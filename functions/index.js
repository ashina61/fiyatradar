const admin = require('firebase-admin');
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { google } = require('googleapis');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const INVALID_TOKEN_ERROR_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

/**
 * Returns the lowest "valid" price from a product's `priceHistory` array.
 * Entries flagged `rejected` are ignored. Returns null if the product has
 * no usable history.
 */
function lowestValidPrice(historyArray) {
  if (!Array.isArray(historyArray) || historyArray.length === 0) return null;
  let lowest = null;
  for (const raw of historyArray) {
    if (!raw || typeof raw !== 'object') continue;
    if (raw.status === 'rejected') continue;
    const price = Number(raw.price);
    if (!Number.isFinite(price) || price <= 0) continue;
    if (lowest === null || price < lowest) lowest = price;
  }
  return lowest;
}

/**
 * Fires when a product document is updated. If the new lowest valid price is
 * lower than the previous lowest valid price, every user with an active
 * `productAlert` for this product is notified IF their target is met.
 *
 * Schema notes:
 *   - Prices live in `products/{id}.priceHistory[]`, not a top-level field.
 *   - User alerts live in `users/{uid}/productAlerts/{productId}`. The doc
 *     id IS the productId.
 *   - FCM tokens live in `users/{uid}.fcmToken` (single string for now).
 *   - Per-user notification documents land in
 *     `users/{uid}/notifications/{auto}` so the in-app notification center
 *     can surface them.
 */
exports.onProductPriceDrop = onDocumentUpdated('products/{productId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const oldPrice = lowestValidPrice(before.priceHistory);
  const newPrice = lowestValidPrice(after.priceHistory);
  if (newPrice === null) return;
  const hasComparableOld = oldPrice !== null && oldPrice > 0;
  const direction = !hasComparableOld
    ? 'available'
    : (newPrice < oldPrice
      ? 'drop'
      : (newPrice > oldPrice ? 'rise' : 'flat'));

  const productId = event.params.productId;
  const productName = (after.name || 'Ürün').toString();

  logger.info('PRICE_ALERT_NEW_PRICE', {
    productId,
    source: 'products.priceHistory',
    direction,
    newPrice,
    oldPrice: hasComparableOld ? oldPrice : null,
  });

  // ÖNCE: full collectionGroup scan + client-side `d.id === productId`.
  // SONRA: `productId` field'ı üzerinden indexli sorgu.
  logger.info('PRICE_ALERT_QUERY_START', {
    productId,
    source: 'products.priceHistory',
  });
  let interested = [];
  try {
    const alertsSnap = await db
      .collectionGroup('productAlerts')
      .where('productId', '==', productId)
      .get();
    interested = alertsSnap.docs;
  } catch (e) {
    // Full-scan fallback KALDIRILDI (audit Y1): tüm productAlerts
    // koleksiyonunu taramak her fiyat değişiminde okuma maliyetini
    // patlatıyordu. Index eksikse deploy pipeline'ı düzeltilmeli
    // (firestore:indexes artık firebase-deploy.yml'da).
    logger.error('productAlerts indexed query failed — is the '
      + 'COLLECTION_GROUP productId index deployed?', {
      error: e.message,
      productId,
    });
    return;
  }
  logger.info('PRICE_ALERT_QUERY_RESULT_COUNT', {
    productId,
    source: 'products.priceHistory',
    count: interested.length,
  });
  if (interested.length === 0) {
    logger.info('Fiyat değişti ama alarm kuran kullanıcı yok.', {
      productId,
      oldPrice,
      newPrice,
    });
    return;
  }

  logger.info('PRICE_ALERT_TRIGGER_STARTED', {
    productId,
    source: 'products.priceHistory',
    direction,
  });

  const pushQueue = [];
  let inAppSent = 0;

  const writePromises = interested.map(async (doc) => {
    const data = doc.data() || {};
    const userId = doc.ref.parent.parent.id;
    if (data.enabled === false) return;

    const mode = resolveAlertMode(data);
    const targetPrice = Number(data.targetPrice);

    logger.info('PRICE_ALERT_USER_ALERT_FOUND', {
      productId,
      uid: userId,
      mode,
      targetPrice: Number.isFinite(targetPrice) ? targetPrice : null,
      source: 'products.priceHistory',
    });

    if (mode === 'below_target') {
      if (!(Number.isFinite(targetPrice) && targetPrice > 0)) return;
      if (newPrice > targetPrice) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'new_price_above_target',
        });
        return;
      }
      if (hasComparableOld && oldPrice <= targetPrice) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'already_below_target',
        });
        return;
      }
    } else if (mode === 'price_drop') {
      if (direction !== 'drop') {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'not_a_drop',
          direction,
        });
        return;
      }
    } else if (mode === 'any_new_price') {
      // Bu trigger sadece lowestValidPrice değiştiğinde anlamlı sinyal verir;
      // değişmediyse atla (priceGroups trigger zaten any_new_price'i
      // raporCount değişimi üzerinden yakalıyor).
      if (!hasComparableOld) {
        // İlk fiyat oluşumu — herkes için bildirim anlamlı.
      } else if (newPrice === oldPrice) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'no_lowest_price_change',
        });
        return;
      }
    }

    const copy = buildAlertNotificationCopy({
      mode,
      productName,
      chainName: '',
      newPrice,
      oldPrice,
      hasComparableOld,
    });
    const notificationType = mode === 'below_target'
      ? 'price_alert_target'
      : (mode === 'price_drop' ? 'price_drop' : 'price_new');

    logger.info('PRICE_ALERT_CONDITION_MATCHED', {
      productId,
      uid: userId,
      mode,
      newPrice,
    });

    // Çift bildirim önleme: aynı alarm olayı priceGroups tetikleyicisinden de
    // gelebilir. İlk kapan yazar, diğeri atlar.
    const claim = await claimAlertNotification({
      userId,
      notificationType,
      productId,
      price: newPrice,
    });
    if (!claim.claimed) {
      // Push da yazılmaz — sadece ilk bildirim için gönderilir.
      return;
    }

    logger.info('IN_APP_NOTIFICATION_WRITE_START', {
      uid: userId,
      mode,
      type: notificationType,
      source: 'products.priceHistory',
    });
    try {
      await db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          title: copy.title,
          body: copy.body,
          productId,
          productName,
          price: newPrice,
          type: notificationType,
          mode,
          direction,
          oldPrice: hasComparableOld ? oldPrice : null,
          newPrice,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      inAppSent++;
      logger.info('IN_APP_NOTIFICATION_WRITTEN', {
        uid: userId,
        mode,
        source: 'products.priceHistory',
      });
      logger.info('PRICE_ALERT_NOTIFICATION_WRITTEN_ONCE', {
        uid: userId,
        type: notificationType,
        source: 'products.priceHistory',
      });
    } catch (e) {
      logger.error('In-app notification write failed', {
        productId,
        uid: userId,
        error: e.message,
      });
      // Yazım başarısızsa dedupe kilidini geri al ki bir sonraki tetikleyici
      // gerçek bildirimi yazabilsin (in-app yazımı korunmalı).
      if (claim.dedupeRef) {
        try {
          await claim.dedupeRef.delete();
        } catch (_) {
          // best-effort
        }
      }
      return;
    }

    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const u = userSnap.data() || {};
      const fcmToken = (u.fcmToken || '').toString().trim();
      const settings = (u.settings || {}).notifications || {};
      const pushEnabled = settings.pushEnabled !== false;
      const priceAlertsEnabled = settings.priceAlertsEnabled !== false;
      if (fcmToken) {
        logger.info('FCM_TOKEN_FOUND', { uid: userId });
      } else {
        logger.info('FCM_TOKEN_MISSING', { uid: userId });
      }
      if (fcmToken && pushEnabled && priceAlertsEnabled) {
        pushQueue.push({
          token: fcmToken,
          uid: userId,
          title: copy.title,
          body: copy.body,
          notificationType,
          mode,
        });
      } else {
        logger.info('PUSH_SKIPPED', {
          uid: userId,
          reason: !fcmToken
            ? 'no_token'
            : (!pushEnabled ? 'push_disabled' : 'price_alerts_disabled'),
        });
      }
    } catch (e) {
      logger.warn('FCM token okunamadı', { userId, error: e.message });
    }
  });

  await Promise.all(writePromises);

  if (pushQueue.length === 0) {
    logger.info('FCM token bulunan alıcı yok; sadece in-app bildirim atıldı.', {
      productId,
      inAppSent,
    });
    return;
  }

  let pushSent = 0;
  let pushFailed = 0;
  const cleanupPromises = [];
  for (const item of pushQueue) {
    logger.info('PUSH_SEND_ATTEMPT', { uid: item.uid, mode: item.mode });
    try {
      await messaging.send({
        token: item.token,
        notification: { title: item.title, body: item.body },
        data: {
          productId,
          type: item.notificationType,
          mode: item.mode,
          direction,
        },
      });
      pushSent++;
      logger.info('PUSH_SEND_SUCCESS', { uid: item.uid });
    } catch (err) {
      pushFailed++;
      const code = err.code || (err.errorInfo && err.errorInfo.code);
      logger.warn('PUSH_SEND_FAILED', {
        uid: item.uid,
        error: err.message,
        code,
      });
      if (INVALID_TOKEN_ERROR_CODES.has(code)) {
        cleanupPromises.push(
          db.collection('users').doc(item.uid).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          }),
        );
      }
    }
  }
  await Promise.all(cleanupPromises);

  logger.info('Fiyat değişim bildirimleri işlendi', {
    productId,
    oldPrice,
    newPrice,
    direction,
    recipients: interested.length,
    inAppSent,
    pushSent,
    pushFailed,
    cleanedTokens: cleanupPromises.length,
  });
});

/**
 * Yeni bölgesel omurga için fiyat değişim tetikleyicisi.
 *
 * `priceGroups/{groupId}` create/update aldığında aynı ürünü alarmla takip
 * eden kullanıcılara in-app notification doc + FCM push gönderiyoruz. Eski
 * sürüm sadece update + düşüş dinliyordu; ilk grup yaratıldığında ya da fiyat
 * yükseldiğinde bildirim merkezi sessiz kalıyordu.
 */
/**
 * Alert dokümanının yeni / eski şemasından mod çıkarır. Eski kayıtlarda
 * yalnız `targetPrice` vardı; o dokümanlar `below_target` olarak değerlendi-
 * rilir. Yeni şema `mode` alanı taşır:
 *   - "below_target"   → hedef fiyatın altına düşünce
 *   - "price_drop"     → yeni fiyat öncekinden düşükse
 *   - "any_new_price"  → her yeni fiyat geldiğinde
 *
 * Geri uyum için `notifyOnAnyNewPrice` / `notifyOnPriceDrop` boolean
 * ayna alanları da okunur.
 */
function resolveAlertMode(alertData) {
  const raw = (alertData.mode || '').toString();
  if (raw === 'below_target') return 'below_target';
  if (raw === 'price_drop') return 'price_drop';
  if (raw === 'any_new_price') return 'any_new_price';
  if (alertData.notifyOnAnyNewPrice === true) return 'any_new_price';
  if (alertData.notifyOnPriceDrop === true) return 'price_drop';
  const target = Number(alertData.targetPrice);
  if (Number.isFinite(target) && target > 0) return 'below_target';
  return 'any_new_price';
}

function buildAlertNotificationCopy({
  mode,
  productName,
  chainName,
  newPrice,
  oldPrice,
  hasComparableOld,
}) {
  const formattedPrice = newPrice.toFixed(2);
  const venue = chainName ? ' · ' + chainName : '';
  if (mode === 'below_target') {
    return {
      title: 'Fiyat alarmı',
      body: `${productName}${venue} hedeflediğin fiyatın altına düştü: ₺${formattedPrice}`,
    };
  }
  if (mode === 'price_drop') {
    const transition = hasComparableOld
      ? ` (₺${Number(oldPrice).toFixed(2)} → ₺${formattedPrice})`
      : `: ₺${formattedPrice}`;
    return {
      title: 'Fiyat düştü',
      body: `${productName}${venue} için yeni daha düşük fiyat bulundu${transition}`,
    };
  }
  return {
    title: 'Yeni fiyat bildirimi',
    body: `${productName}${venue} için yeni fiyat eklendi: ₺${formattedPrice}`,
  };
}

/**
 * Fiyat alarmı bildirim dedupe'i.
 *
 * Aynı fiyat alarm olayı hem `onProductPriceDrop` (products.priceHistory) hem
 * `onPriceGroupUpdate` (priceGroups) tarafından tetikleniyor; ikisi de aynı
 * kullanıcıya bildirim yazınca Bildirim Merkezi'nde çift kayıt oluşuyordu.
 *
 * Çözüm: bildirim yazmadan ÖNCE `users/{uid}/notificationDedupes/{key}`
 * dokümanını `create()` ile atomik olarak "kapatıyoruz". `create()` doküman
 * zaten varsa ALREADY_EXISTS fırlatır → ikinci tetikleyici bunu görüp atlar.
 * Böylece yarış (race) durumunda bile yalnızca ilk tetikleyici yazar.
 *
 * Anahtar: notificationType + productId + fiyat(kuruş) + gün (uid path'te).
 * Fiyat ve gün anahtarda olduğu için gerçekten FARKLI bildirimler (farklı
 * fiyat, farklı tip, başka gün) engellenmez.
 *
 * Dönüş: { claimed, dedupeRef }. `claimed === false` → atla (HIT_SKIP).
 * Dedupe altyapısı beklenmedik hata verirse bildirimi KAYBETMEMEK için
 * yazmaya izin veririz (claimed=true, dedupeRef=null).
 */
const DEDUPE_RETENTION_DAYS = 3;
async function claimAlertNotification({ userId, notificationType, productId, price }) {
  const priceKey = Number.isFinite(price) ? Math.round(price * 100) : 'na';
  const dayKey = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
  const dedupeKey = `${notificationType}_${productId}_${priceKey}_${dayKey}`;
  const dedupeRef = db
    .collection('users')
    .doc(userId)
    .collection('notificationDedupes')
    .doc(dedupeKey);

  logger.info('PRICE_ALERT_DEDUPE_CHECK', { uid: userId, dedupeKey });
  try {
    await dedupeRef.create({
      type: notificationType,
      productId,
      price: Number.isFinite(price) ? price : null,
      day: dayKey,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      // Eski dedupe doc'ları temizlemek isteyen bir TTL/cron için ipucu;
      // bugün için işlevi yok, ileride güvenle silinebilir olsun diye yazılır.
      expiresAfterDays: DEDUPE_RETENTION_DAYS,
    });
    logger.info('PRICE_ALERT_DEDUPE_CREATED', { uid: userId, dedupeKey });
    return { claimed: true, dedupeRef };
  } catch (e) {
    const code = e.code || (e.errorInfo && e.errorInfo.code);
    const alreadyExists =
      code === 6 ||
      code === 'already-exists' ||
      (typeof e.message === 'string' &&
        e.message.toLowerCase().includes('already exists'));
    if (alreadyExists) {
      logger.info('PRICE_ALERT_DEDUPE_HIT_SKIP', { uid: userId, dedupeKey });
      return { claimed: false, dedupeRef };
    }
    logger.warn('PRICE_ALERT_DEDUPE_ERROR_ALLOW', {
      uid: userId,
      dedupeKey,
      error: e.message,
    });
    // Dedupe altyapısı hatasında bildirimi engellemektense yazmayı seç.
    return { claimed: true, dedupeRef: null };
  }
}

exports.onPriceGroupUpdate = onDocumentWritten('priceGroups/{groupId}', async (event) => {
  const before = event.data.before.exists ? event.data.before.data() || {} : null;
  const after = event.data.after.exists ? event.data.after.data() || {} : null;
  if (!after) return;

  logger.info('PRICE_ALERT_TRIGGER_STARTED', {
    groupId: event.params.groupId,
    source: 'priceGroups',
  });

  const oldPrice = before ? Number(before.trustedPrice ?? before.latestPrice) : null;
  const newPrice = Number(after.trustedPrice ?? after.latestPrice);
  if (!Number.isFinite(newPrice) || newPrice <= 0) return;
  const hasComparableOld = Number.isFinite(oldPrice) && oldPrice > 0;
  const priceChanged = !hasComparableOld || Number(oldPrice) !== newPrice;

  // priceGroups'un her güncellemesi fiyat değişimi anlamına gelmez (yalnız
  // verifiedCount artışı olabilir). `any_new_price` modunda yine de
  // bildirmek için reportCount artışını işaretliyoruz; aksi halde sadece
  // fiyat değişti ise devam ediyoruz.
  const beforeReportCount = before ? Number(before.reportCount ?? 0) : 0;
  const afterReportCount = Number(after.reportCount ?? 0);
  const newReportObserved = afterReportCount > beforeReportCount;
  if (!priceChanged && !newReportObserved) {
    logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
      groupId: event.params.groupId,
      reason: 'no_price_change_and_no_new_report',
    });
    return;
  }

  const productId = (after.productId || '').toString();
  if (!productId) return;
  const productName = (after.productName || 'Ürün').toString();
  const cityName = (after.cityName || '').toString();
  const districtName = (after.districtName || '').toString();
  const chainName = (after.chainName || '').toString();
  const lastReporterId = (after.lastReporterId || '').toString();
  const direction = !hasComparableOld
    ? 'available'
    : newPrice < Number(oldPrice)
      ? 'drop'
      : (newPrice > Number(oldPrice) ? 'rise' : 'flat');

  logger.info('PRICE_ALERT_NEW_PRICE', {
    productId,
    groupId: event.params.groupId,
    direction,
    newPrice,
    oldPrice: hasComparableOld ? Number(oldPrice) : null,
  });

  logger.info('PRICE_ALERT_PRODUCT_MATCH', {
    productId,
    groupId: event.params.groupId,
    direction,
    newPrice,
    oldPrice: hasComparableOld ? Number(oldPrice) : null,
  });

  // Sadece bu ürünü takip eden kullanıcıları çek (indexed). Tek-alan
  // collection-group index'i (productId) firestore.indexes.json'da tanımlı;
  // index yoksa aşağıda full-scan fallback'ine düşüyoruz.
  logger.info('PRICE_ALERT_QUERY_START', {
    productId,
    groupId: event.params.groupId,
  });
  let alerts = [];
  try {
    const snap = await db
      .collectionGroup('productAlerts')
      .where('productId', '==', productId)
      .get();
    alerts = snap.docs;
  } catch (e) {
    // Full-scan fallback'leri KALDIRILDI (audit Y1): 0 sonuçta bile tüm
    // productAlerts koleksiyonu taranıyordu — alarm kurulmamış ürünler en
    // yaygın durum olduğu için HER fiyat raporu tam tarama tetikliyordu.
    // Index eksikse sorun deploy'da: firestore:indexes artık
    // firebase-deploy.yml'da deploy ediliyor.
    logger.error('priceGroup alerts indexed query failed — is the '
      + 'COLLECTION_GROUP productId index deployed?', {
      groupId: event.params.groupId,
      error: e.message,
    });
    return;
  }
  logger.info('PRICE_ALERT_QUERY_RESULT_COUNT', {
    productId,
    groupId: event.params.groupId,
    count: alerts.length,
  });
  if (alerts.length === 0) {
    logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
      productId,
      reason: 'no_alerts_for_product',
    });
    return;
  }

  const isOnlineGroup = cityName.toLowerCase() === 'türkiye' &&
    districtName.toLowerCase() === 'online';

  const pushQueue = [];
  let inAppSent = 0;
  const writes = alerts.map(async (doc) => {
    const userId = doc.ref.parent.parent?.id;
    if (!userId) return;

    const alertData = doc.data() || {};
    if (alertData.enabled === false) {
      logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
        productId,
        uid: userId,
        reason: 'alert_disabled',
      });
      return;
    }

    const mode = resolveAlertMode(alertData);
    const targetPrice = Number(alertData.targetPrice);

    logger.info('PRICE_ALERT_USER_ALERT_FOUND', {
      productId,
      uid: userId,
      mode,
      targetPrice: Number.isFinite(targetPrice) ? targetPrice : null,
    });

    // Self-notification politikası: kullanıcı kendi raporladığı fiyat için
    // bildirim almamalı (zaten ekledikleri anda biliyorlar).
    if (lastReporterId && lastReporterId === userId) {
      logger.info('SELF_NOTIFICATION_SKIPPED', {
        productId,
        uid: userId,
        reason: 'self_reporter',
      });
      return;
    }

    if (mode === 'below_target') {
      if (!(Number.isFinite(targetPrice) && targetPrice > 0)) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'missing_target_price',
        });
        return;
      }
      if (newPrice > targetPrice) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'new_price_above_target',
          newPrice,
          targetPrice,
        });
        return;
      }
      // below_target: önceki fiyat zaten target altındaysa tekrar bildirme
      // (kullanıcıyı aynı eşik için sürekli rahatsız etmeyelim).
      if (hasComparableOld && Number(oldPrice) <= targetPrice) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'already_below_target',
          oldPrice: Number(oldPrice),
          targetPrice,
        });
        return;
      }
    } else if (mode === 'price_drop') {
      if (direction !== 'drop') {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'not_a_drop',
          direction,
        });
        return;
      }
    } else if (mode === 'any_new_price') {
      // Yeni rapor yok ve fiyat aynı kaldıysa skip et — gerçek bir yeni
      // fiyat sinyali olduğunda bildiriyoruz.
      if (!newReportObserved && !priceChanged) {
        logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
          productId,
          uid: userId,
          mode,
          reason: 'no_signal',
        });
        return;
      }
    }

    // Bölge filtresi: below_target ve any_new_price modlarında kullanıcı
    // ülke çapında bildirim istemiş kabul edilir (hedef fiyat her yerde
    // geçerli). price_drop modunda kullanıcının bölgesi grubun bölgesiyle
    // eşleşmiyorsa atla — kendi bölgesi dışındaki kısa süreli düşüşlerle
    // boğmayalım.
    let userCity = '';
    let userDistrict = '';
    let fcmToken = '';
    let pushEnabled = true;
    let priceAlertsEnabled = true;
    let regionalDropPushEnabled = true;
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const u = userSnap.data() || {};
      userCity = (u.cityName || u.city || '').toString();
      userDistrict = (u.districtName || u.district || u.neighborhood || '').toString();
      fcmToken = (u.fcmToken || '').toString().trim();
      const settings = (u.settings || {}).notifications || {};
      pushEnabled = settings.pushEnabled !== false;
      priceAlertsEnabled = settings.priceAlertsEnabled !== false;
      regionalDropPushEnabled = settings.regionalDropPushEnabled !== false;
    } catch (e) {
      logger.warn('priceGroup: user fetch failed', { userId, error: e.message });
      return;
    }
    if (
      mode === 'price_drop' &&
      !isOnlineGroup &&
      userCity &&
      userDistrict &&
      cityName &&
      districtName &&
      (userCity.toLowerCase() !== cityName.toLowerCase() ||
        userDistrict.toLowerCase() !== districtName.toLowerCase())
    ) {
      logger.info('PRICE_ALERT_CONDITION_NOT_MATCHED', {
        productId,
        uid: userId,
        mode,
        reason: 'region_mismatch',
        userRegion: `${userCity}/${userDistrict}`,
        groupRegion: `${cityName}/${districtName}`,
      });
      return;
    }

    const copy = buildAlertNotificationCopy({
      mode,
      productName,
      chainName,
      newPrice,
      oldPrice,
      hasComparableOld,
    });
    const notificationType = mode === 'below_target'
      ? 'price_alert_target'
      : (mode === 'price_drop' ? 'price_drop' : 'price_new');

    logger.info('PRICE_ALERT_CONDITION_MATCHED', {
      productId,
      uid: userId,
      mode,
      newPrice,
    });

    // Çift bildirim önleme: aynı alarm olayı products.priceHistory
    // tetikleyicisinden de gelebilir. İlk kapan yazar, diğeri atlar.
    const claim = await claimAlertNotification({
      userId,
      notificationType,
      productId,
      price: newPrice,
    });
    if (!claim.claimed) {
      // Push da yazılmaz — sadece ilk bildirim için gönderilir.
      return;
    }

    logger.info('IN_APP_NOTIFICATION_WRITE_START', {
      uid: userId,
      mode,
      type: notificationType,
    });
    try {
      await db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          title: copy.title,
          body: copy.body,
          productId,
          productName,
          price: newPrice,
          groupId: event.params.groupId,
          type: notificationType,
          mode,
          direction,
          oldPrice: hasComparableOld ? Number(oldPrice) : null,
          newPrice,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      inAppSent++;
      logger.info('IN_APP_NOTIFICATION_WRITTEN', { uid: userId, mode });
      logger.info('PRICE_ALERT_NOTIFICATION_WRITTEN_ONCE', {
        uid: userId,
        type: notificationType,
        source: 'priceGroups',
      });
    } catch (e) {
      logger.error('In-app notification write failed', {
        productId,
        uid: userId,
        error: e.message,
      });
      // In-app yazılamadıysa dedupe kilidini geri al ki bir sonraki
      // tetikleyici gerçek bildirimi yazabilsin; push da denenmez.
      if (claim.dedupeRef) {
        try {
          await claim.dedupeRef.delete();
        } catch (_) {
          // best-effort
        }
      }
      return;
    }

    // Push'u sadece opt-in kullanıcılara gönder; in-app doc yine yazıldı.
    // regionalDropPushEnabled: kullanıcı bölgesel hareket bildirimlerini
    // kapatmışsa price_drop push'u skip et (in-app doc yazılmaya devam
    // eder). below_target ve any_new_price modlarında bu toggle göz
    // ardı edilir; çünkü kullanıcı bilinçli olarak bu modu seçmiş.
    const respectRegionalToggle = mode === 'price_drop';
    if (fcmToken) {
      logger.info('FCM_TOKEN_FOUND', { uid: userId });
    } else {
      logger.info('FCM_TOKEN_MISSING', { uid: userId });
    }
    if (
      fcmToken &&
      pushEnabled &&
      priceAlertsEnabled &&
      (!respectRegionalToggle || regionalDropPushEnabled)
    ) {
      pushQueue.push({
        token: fcmToken,
        uid: userId,
        title: copy.title,
        body: copy.body,
        notificationType,
        mode,
      });
    } else {
      logger.info('PUSH_SKIPPED', {
        uid: userId,
        reason: !fcmToken
          ? 'no_token'
          : (!pushEnabled
            ? 'push_disabled'
            : (!priceAlertsEnabled
              ? 'price_alerts_disabled'
              : 'regional_drop_disabled')),
      });
    }
  });
  await Promise.all(writes);

  if (pushQueue.length === 0) {
    logger.info('priceGroup change: push yok, in-app yazıldı', {
      groupId: event.params.groupId,
      productId,
      direction,
      inAppSent,
    });
    return;
  }

  let pushSent = 0;
  let pushFailed = 0;
  const cleanupPromises = [];
  // Her kullanıcı için ayrı title/body olabildiği için tek tek gönderiyoruz.
  for (const item of pushQueue) {
    logger.info('PUSH_SEND_ATTEMPT', { uid: item.uid, mode: item.mode });
    try {
      await messaging.send({
        token: item.token,
        notification: { title: item.title, body: item.body },
        data: {
          productId,
          groupId: event.params.groupId,
          type: item.notificationType,
          mode: item.mode,
          direction,
        },
      });
      pushSent++;
      logger.info('PUSH_SEND_SUCCESS', { uid: item.uid });
    } catch (err) {
      pushFailed++;
      const code = err.code || (err.errorInfo && err.errorInfo.code);
      logger.warn('PUSH_SEND_FAILED', {
        uid: item.uid,
        error: err.message,
        code,
      });
      if (INVALID_TOKEN_ERROR_CODES.has(code)) {
        cleanupPromises.push(
          db.collection('users').doc(item.uid).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          }),
        );
      }
    }
  }
  await Promise.all(cleanupPromises);

  logger.info('Fiyat değişim bildirimleri işlendi', {
    groupId: event.params.groupId,
    productId,
    cityName,
    districtName,
    oldPrice: hasComparableOld ? Number(oldPrice) : null,
    newPrice,
    direction,
    recipients: alerts.length,
    inAppSent,
    pushSent,
    pushFailed,
  });
});

/**
 * FiyatRadar Pro satın alma doğrulayıcı.
 *
 * `purchaseQueue/{uid_productId_purchaseId}` doc create edildiğinde devreye
 * girer. Google Play Developer API
 * (`androidpublisher.purchases.subscriptionsv2.get`) ile purchase token
 * doğrulanır ve subscription metadata'sı (lineItems[0].expiryTime,
 * subscriptionState) okunur. Doğrulama başarısızsa `users/{uid}.isPremium`
 * KESİNLİKLE true'ya çekilmez — purchaseQueue dokümanına verifyFailed
 * işaretlenir ki UI tarafı durumu görsün.
 *
 * Auth: Firebase Functions default service account
 * (`...@appspot.gserviceaccount.com`) bu projeyle birlikte hazır gelir;
 * `androidpublisher` scope'unu kapsaması için Google Play Console →
 * API Access → Service accounts tarafında bu hesaba "Finance" rolü
 * verilmesi yeterli (release manager düzeyinde değil, sadece read).
 *
 * Test/staging: ortamda `FR_PLAY_PACKAGE_NAME` env override edilebilir.
 * Default `com.fiyatradar` (android/app/build.gradle.kts applicationId).
 *
 * `users/{uid}` rules `immutable('isPremium')` koyduğu için bu function
 * admin SDK kullanmak zorunda — istemci aynı write'ı yapamaz.
 */
const FR_PLAY_PACKAGE_NAME =
  process.env.FR_PLAY_PACKAGE_NAME || 'com.fiyatradar';
const FR_KNOWN_SUB_PRODUCT_IDS = new Set([
  'fr_pro_monthly',
  'fr_pro_yearly',
]);

let _androidpublisherClient = null;
async function getAndroidPublisherClient() {
  if (_androidpublisherClient) return _androidpublisherClient;
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  _androidpublisherClient = google.androidpublisher({
    version: 'v3',
    auth,
  });
  return _androidpublisherClient;
}

function parsePlayExpiryTime(rawIso) {
  if (!rawIso) return null;
  const ms = Date.parse(rawIso);
  if (!Number.isFinite(ms)) return null;
  return new Date(ms);
}

// Play subscriptionsv2 SubscriptionState'leri: ACTIVE & IN_GRACE_PERIOD
// erişimi açık tutar. CANCELED henüz bitmediği için de pratikte expiry
// kontrolü yapacağız — kullanıcı süresini doldurana kadar premium kalır.
// ON_HOLD, PAUSED, EXPIRED → premium kapalı.
const PLAY_ACTIVE_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
]);
const PLAY_GRACEFUL_END_STATES = new Set([
  'SUBSCRIPTION_STATE_CANCELED',
]);

exports.verifyPurchase = onDocumentCreated(
  'purchaseQueue/{purchaseDoc}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.consumed === true) return;
    const userId = (data.userId || '').toString();
    if (!userId) {
      throw new HttpsError(
        'invalid-argument',
        'purchaseQueue doc missing userId',
      );
    }
    const productId = (data.productId || '').toString();
    const purchaseToken = (data.verificationData || '').toString();
    if (!purchaseToken) {
      logger.warn('verifyPurchase: empty verificationData', {
        purchaseDoc: event.params.purchaseDoc,
        userId,
      });
      await event.data.ref.set(
        {
          verifyFailed: true,
          verifyFailedReason: 'missing_verification_data',
          verifyFailedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }
    if (!FR_KNOWN_SUB_PRODUCT_IDS.has(productId)) {
      logger.warn('verifyPurchase: unknown productId', {
        productId,
        userId,
      });
      await event.data.ref.set(
        {
          verifyFailed: true,
          verifyFailedReason: 'unknown_product_id',
          verifyFailedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    let subscription;
    try {
      const androidpublisher = await getAndroidPublisherClient();
      const res = await androidpublisher.purchases.subscriptionsv2.get({
        packageName: FR_PLAY_PACKAGE_NAME,
        token: purchaseToken,
      });
      subscription = res.data;
    } catch (e) {
      logger.error('verifyPurchase: subscriptionsv2.get failed', {
        userId,
        productId,
        purchaseDoc: event.params.purchaseDoc,
        error: e.message,
        code: e.code,
      });
      await event.data.ref.set(
        {
          verifyFailed: true,
          verifyFailedReason: 'play_api_error',
          verifyFailedDetail: (e.message || '').slice(0, 500),
          verifyFailedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    const state = subscription?.subscriptionState || '';
    const lineItem =
      Array.isArray(subscription?.lineItems) && subscription.lineItems.length > 0
        ? subscription.lineItems[0]
        : null;
    const expiry = parsePlayExpiryTime(lineItem?.expiryTime);

    if (!expiry) {
      logger.warn('verifyPurchase: missing expiryTime', {
        userId,
        productId,
        subscriptionState: state,
      });
      await event.data.ref.set(
        {
          verifyFailed: true,
          verifyFailedReason: 'missing_expiry',
          verifyFailedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    const now = new Date();
    const isActive =
      PLAY_ACTIVE_STATES.has(state) ||
      (PLAY_GRACEFUL_END_STATES.has(state) && expiry > now);

    if (!isActive) {
      logger.info('verifyPurchase: subscription inactive', {
        userId,
        productId,
        subscriptionState: state,
        expiry: expiry.toISOString(),
      });
      // Kullanıcının daha önce premium olduğu durum (yenileme reddi vs.)
      // weeklyPremiumExpiryCheck zaten süreyi kullanarak hesap düşürür;
      // burada zorla `isPremium=false` yazmıyoruz, sadece queue'yu kapat.
      await event.data.ref.set(
        {
          consumed: true,
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          verifyFailed: true,
          verifyFailedReason: 'inactive_state',
          subscriptionState: state,
        },
        { merge: true },
      );
      return;
    }

    try {
      await db.collection('users').doc(userId).set(
        {
          isPremium: true,
          premiumUntil: admin.firestore.Timestamp.fromDate(expiry),
          premiumPlan: productId,
          premiumProductId: productId,
          premiumSource: 'google_play',
          premiumSubscriptionState: state,
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      await event.data.ref.set(
        {
          consumed: true,
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          subscriptionState: state,
          expiryTime: lineItem?.expiryTime || null,
        },
        { merge: true },
      );
      logger.info('Premium aktivasyon doğrulandı', {
        userId,
        productId,
        subscriptionState: state,
        expiresAt: expiry.toISOString(),
      });
    } catch (e) {
      logger.error('verifyPurchase write failed', {
        userId,
        productId,
        error: e.message,
      });
    }
  },
);

/**
 * Free hesabın aktif alarm limiti (Pro launch product split).
 *
 * Client `AppState.setProductAlert` zaten istemci tarafında bu cap'i
 * uygular ama firestore rules `productAlerts` koleksiyonu için sayım
 * tabanlı bir kısıt yazmıyor (her doc bağımsız değerlendiriliyor).
 * Bu trigger backstop: yeni bir alarm dokümanı yaratıldığında kullanıcının
 * `users/{uid}.isPremium` flag'ine bakar, Pro değilse ve aktif alarm
 * sayısı sınırı aşıyorsa yeni eklenen doc'u siler. UI tarafı eklemeyi
 * onaylamış görünebilir; bu yüzden ek olarak per-user notification
 * koleksiyonuna kısa bir uyarı bırakıyoruz.
 */
const kFreeProductAlertLimit = 3;

exports.enforceFreeAlertLimit = onDocumentCreated(
  'users/{uid}/productAlerts/{productId}',
  async (event) => {
    const uid = event.params.uid;
    const productId = event.params.productId;
    if (!uid) return;
    let isPremium = false;
    try {
      const snap = await db.collection('users').doc(uid).get();
      const m = snap.data() || {};
      const premiumUntilRaw = m.premiumUntil;
      const premiumUntil = premiumUntilRaw && premiumUntilRaw.toDate
        ? premiumUntilRaw.toDate()
        : (premiumUntilRaw ? new Date(premiumUntilRaw) : null);
      isPremium = m.isPremium === true &&
        (!premiumUntil || premiumUntil > new Date());
    } catch (e) {
      logger.warn('enforceFreeAlertLimit user lookup failed', {
        uid,
        error: e.message,
      });
      return;
    }
    if (isPremium) return;

    let activeCount = 0;
    try {
      const alertsSnap = await db
        .collection('users')
        .doc(uid)
        .collection('productAlerts')
        .get();
      activeCount = alertsSnap.size;
    } catch (e) {
      logger.warn('enforceFreeAlertLimit count failed', {
        uid,
        error: e.message,
      });
      return;
    }

    if (activeCount <= kFreeProductAlertLimit) return;

    try {
      await event.data.ref.delete();
      logger.info('Free alert limit enforced, deleted newest alert', {
        uid,
        productId,
        activeCount,
      });
      await db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
          type: 'alert_limit_reached',
          title: 'Alarm limiti aşıldı',
          body: `Free hesabınla en fazla ${kFreeProductAlertLimit} alarm kurabilirsin. Sınırsız alarm için Pro'ya geç.`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (e) {
      logger.error('enforceFreeAlertLimit delete failed', {
        uid,
        productId,
        error: e.message,
      });
    }
  },
);

/**
 * Haftalık özet bildirimi.
 *
 * Her Pazartesi 09:00 Europe/Istanbul'da çalışır. Aktif kullanıcılara
 * (settings.weeklySummaryEnabled !== false) son 7 günde bölgelerinde
 * bildirilen yeni fiyat sayısını + Cloud Function tetikçisinin tamamladığı
 * push'u gönderir.
 *
 * Üretimde maliyet kontrolü için kullanıcı segment'leme önerilir
 * (örn. son 30 gün giriş yapmış kullanıcılar). Şu an basit: tüm
 * kullanıcı doc'larını tarar.
 */
exports.weeklySummary = onSchedule(
  {
    schedule: '0 9 * * 1', // Pazartesi 09:00
    timeZone: 'Europe/Istanbul',
  },
  async () => {
    // Admin panelden yönetilebilir içerik konfigürasyonu. Doküman yoksa ya da
    // okunamazsa güvenli varsayılanlar kullanılır (mevcut davranış korunur).
    // NOT: schedule (gün/saat) cron olarak deploy anında sabitlenir; config'in
    // dayOfWeek/hour alanları yalnız bilgilendirme amaçlıdır ve değişiklik
    // ancak yeniden deploy ile cron'a yansır.
    let cfg = {};
    try {
      const cfgSnap = await db.collection('appConfig').doc('weeklySummary').get();
      if (cfgSnap.exists) cfg = cfgSnap.data() || {};
    } catch (e) {
      logger.warn('weeklySummary config okunamadı, varsayılanlar kullanılıyor', {
        error: e.message,
      });
    }
    const cfgEnabled = cfg.enabled !== false; // varsayılan: açık
    if (!cfgEnabled) {
      logger.info('weeklySummary: config ile devre dışı, atlandı.');
      return;
    }
    const cfgTitle = (cfg.title || 'Haftalık özet').toString();
    const cfgBodyTemplate = (
      cfg.bodyTemplate ||
      '{district} bölgesinde 7 günde {count} yeni fiyat bildirildi.'
    ).toString();
    const cfgOnlyPremium = cfg.onlyPremium !== false; // varsayılan: yalnız Pro
    const cfgSendPush = cfg.sendPush !== false; // varsayılan: push açık
    const cfgWriteInApp = cfg.writeInApp !== false; // varsayılan: in-app açık

    const renderBody = (district, count) =>
      cfgBodyTemplate
        .replace(/\{district\}/g, district)
        .replace(/\{count\}/g, String(count));

    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    );
    const usersSnap = await db.collection('users').get();
    const tokens = [];
    const tokenToRefs = new Map();
    let inAppSent = 0;

    for (const u of usersSnap.docs) {
      const m = u.data() || {};
      const settings = (m.settings || {}).notifications || {};
      const weeklyEnabled = settings.weeklySummaryEnabled !== false;
      const pushEnabled = settings.pushEnabled !== false;
      // Haftalık özet varsayılan olarak bir Pro özelliği. Admin config
      // `onlyPremium: false` derse tüm kullanıcılara açılır.
      const isPremium = m.isPremium === true;
      const premiumUntilRaw = m.premiumUntil;
      const premiumUntil = premiumUntilRaw && premiumUntilRaw.toDate
        ? premiumUntilRaw.toDate()
        : (premiumUntilRaw ? new Date(premiumUntilRaw) : null);
      const premiumActive =
        isPremium && (!premiumUntil || premiumUntil > new Date());
      if (cfgOnlyPremium && !premiumActive) continue;
      const cityName = (m.cityName || m.city || '').toString();
      const districtName = (m.district || m.neighborhood || '').toString();
      if (!cityName || !districtName) continue;
      if (!weeklyEnabled) continue;

      const cityId = cityName.trim().toLowerCase().replace(/\s+/g, '_');
      const districtId = districtName.trim().toLowerCase().replace(/\s+/g, '_');
      let count = 0;
      try {
        const reportsSnap = await db
          .collection('priceReports')
          .where('cityId', '==', cityId)
          .where('districtId', '==', districtId)
          .where('createdAt', '>=', cutoff)
          .limit(100)
          .get();
        count = reportsSnap.size;
      } catch (e) {
        logger.warn('weeklySummary count failed', {
          userId: u.id,
          error: e.message,
        });
        continue;
      }
      if (count <= 0) continue;

      // 1) In-app doc (config ile kapatılabilir).
      if (cfgWriteInApp) {
        try {
          await db
            .collection('users')
            .doc(u.id)
            .collection('notifications')
            .add({
              title: cfgTitle,
              body: renderBody(districtName, count),
              type: 'weekly_summary',
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          inAppSent++;
        } catch (e) {
          logger.warn('weeklySummary in-app write failed', {
            userId: u.id,
            error: e.message,
          });
        }
      }

      // 2) Push token (opt-in + config ile kapatılabilir).
      const fcmToken = (m.fcmToken || '').toString().trim();
      if (cfgSendPush && fcmToken && pushEnabled) {
        tokens.push(fcmToken);
        if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
        tokenToRefs.get(fcmToken).push(u.ref);
      }
    }

    if (tokens.length > 0) {
      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: cfgTitle,
          body: 'Bölgendeki son 7 günün fiyat raporu hazır.',
        },
        data: { type: 'weekly_summary' },
      });
      const cleanupPromises = [];
      response.responses.forEach((result, index) => {
        if (!result.error) return;
        const code = result.error.code;
        if (!INVALID_TOKEN_ERROR_CODES.has(code)) return;
        const token = tokens[index];
        const refs = tokenToRefs.get(token) || [];
        refs.forEach((ref) =>
          cleanupPromises.push(
            ref.update({ fcmToken: admin.firestore.FieldValue.delete() }),
          ),
        );
      });
      await Promise.all(cleanupPromises);
      logger.info('weeklySummary gönderildi', {
        inAppSent,
        pushSent: response.successCount,
      });
    } else {
      logger.info('weeklySummary: push yok, in-app yazıldı', { inAppSent });
    }
  },
);

/**
 * Topluluk doğrulama / red bildirimi.
 *
 * `products/{productId}` doc update'inde priceHistory dizisindeki entry
 * status değişimlerini izler. Bir kullanıcının eklediği fiyat
 * `community_verified` ya da `rejected` terminal durumuna geçtiğinde
 * fiyatın orijinal sahibine (entry.reportedByUid) hem in-app notification
 * doc'u yazar hem de varsa FCM push gönderir. Tek bir ürün update'inde
 * birden fazla entry'nin terminal'e gitmesi mümkün, hepsi tek tek
 * işlenir.
 */
exports.onPriceVerificationChange = onDocumentUpdated(
  'products/{productId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    const productId = event.params.productId;
    const productName = (after.name || 'Ürün').toString();

    const beforeMap = new Map();
    if (Array.isArray(before.priceHistory)) {
      for (const e of before.priceHistory) {
        if (e && typeof e === 'object' && typeof e.id === 'string') {
          beforeMap.set(e.id, e);
        }
      }
    }

    const afterEntries = Array.isArray(after.priceHistory)
      ? after.priceHistory
      : [];

    // (uid, type, body, entry) tuple'larını topla — aynı kullanıcıya birden
    // fazla terminal aynı update'te gelirse hepsini tek tek yazıyoruz.
    const transitions = [];
    for (const entry of afterEntries) {
      if (!entry || typeof entry !== 'object') continue;
      const id = (entry.id || '').toString();
      if (!id) continue;
      const reporterUid = (entry.reportedByUid || '').toString();
      if (!reporterUid) continue;
      const prev = beforeMap.get(id);
      const prevStatus = prev ? (prev.status || 'pending').toString() : null;
      const nextStatus = (entry.status || 'pending').toString();
      if (prevStatus === nextStatus) continue;
      if (
        nextStatus !== 'community_verified' &&
        nextStatus !== 'rejected'
      ) {
        continue;
      }
      const verified = nextStatus === 'community_verified';
      const priceText = Number(entry.price).toFixed(2);
      const storeText = (entry.store || '').toString();
      const title = verified
        ? 'Fiyatın doğrulandı'
        : 'Fiyatın reddedildi';
      const body = verified
        ? `${productName}${storeText ? ' · ' + storeText : ''}: ${priceText}₺ topluluk tarafından doğrulandı.`
        : `${productName}${storeText ? ' · ' + storeText : ''}: ${priceText}₺ topluluk tarafından reddedildi.`;
      transitions.push({
        reporterUid,
        type: verified ? 'price_verified' : 'price_rejected',
        title,
        body,
        entryId: id,
      });
    }

    if (transitions.length === 0) return;

    const tokens = [];
    const tokenToRefs = new Map();
    let inAppSent = 0;

    const writes = transitions.map(async (t) => {
      try {
        await db
          .collection('users')
          .doc(t.reporterUid)
          .collection('notifications')
          .add({
            title: t.title,
            body: t.body,
            productId,
            entryId: t.entryId,
            type: t.type,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        inAppSent++;
      } catch (e) {
        logger.warn('verification notification write failed', {
          productId,
          reporterUid: t.reporterUid,
          error: e.message,
        });
        return;
      }
      try {
        const userSnap = await db
          .collection('users')
          .doc(t.reporterUid)
          .get();
        const u = userSnap.data() || {};
        const fcmToken = (u.fcmToken || '').toString().trim();
        const settings = (u.settings || {}).notifications || {};
        const pushEnabled = settings.pushEnabled !== false;
        const verificationsEnabled =
          settings.verificationsEnabled !== false;
        if (fcmToken && pushEnabled && verificationsEnabled) {
          tokens.push(fcmToken);
          if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
          tokenToRefs.get(fcmToken).push({
            ref: userSnap.ref,
            title: t.title,
            body: t.body,
            type: t.type,
          });
        }
      } catch (e) {
        logger.warn('verification: user fetch failed', {
          reporterUid: t.reporterUid,
          error: e.message,
        });
      }
    });
    await Promise.all(writes);

    if (tokens.length === 0) {
      logger.info('Doğrulama bildirimi yazıldı (push yok)', {
        productId,
        inAppSent,
      });
      return;
    }

    // Her tokene farklı body olabileceği için tek tek push gönderiyoruz.
    let pushSent = 0;
    let pushFailed = 0;
    const cleanupPromises = [];
    for (const token of tokens) {
      const entries = tokenToRefs.get(token) || [];
      for (const meta of entries) {
        try {
          await messaging.send({
            token,
            notification: { title: meta.title, body: meta.body },
            data: { productId, type: meta.type },
          });
          pushSent++;
        } catch (err) {
          pushFailed++;
          const code = err.code || (err.errorInfo && err.errorInfo.code);
          if (INVALID_TOKEN_ERROR_CODES.has(code)) {
            cleanupPromises.push(
              meta.ref.update({
                fcmToken: admin.firestore.FieldValue.delete(),
              }),
            );
          }
        }
      }
    }
    await Promise.all(cleanupPromises);

    logger.info('Doğrulama bildirimleri işlendi', {
      productId,
      inAppSent,
      pushSent,
      pushFailed,
      cleanedTokens: cleanupPromises.length,
    });
  },
);

/**
 * Hesap silme işleyicisi (audit K1).
 *
 * Client, `deletionRequests/{uid}` dokümanını yaratır (rules: yalnız kendi
 * uid'i). Bu trigger Admin SDK ile kullanıcının TÜM verisini siler:
 *   1. users/{uid} dokümanı + alt koleksiyonları (notifications,
 *      productAlerts, notificationDedupes, ...) — recursiveDelete.
 *   2. usernames rezervasyonu (uid eşleşen doc'lar).
 *   3. Storage klasörleri: user_profiles/{uid}, price_proofs/{uid},
 *      product_image_submissions/{uid} — best-effort.
 *   4. Firebase Auth hesabı (client recent-login gerektirmeden).
 *
 * Topluluğa katkı olarak girilen fiyat raporları/yorumlar bilinçli olarak
 * KORUNUR (kullanıcı sözleşmesindeki anonimleştirilmiş katkı istisnası);
 * kişisel profil verisi tamamen gider.
 */
exports.processAccountDeletion = onDocumentCreated(
  'deletionRequests/{uid}',
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data() || {};
    if (!uid || (data.uid && data.uid !== uid)) {
      logger.warn('processAccountDeletion: uid mismatch, skipping', { uid });
      return;
    }
    logger.info('ACCOUNT_DELETION_START', { uid });

    // 1) Kullanıcı dokümanı + tüm alt koleksiyonlar.
    try {
      await db.recursiveDelete(db.collection('users').doc(uid));
      logger.info('ACCOUNT_DELETION_USER_DOC_DELETED', { uid });
    } catch (e) {
      logger.error('ACCOUNT_DELETION_USER_DOC_FAILED', {
        uid,
        error: e.message,
      });
    }

    // 2) Username rezervasyonları.
    try {
      const reservations = await db
        .collection('usernames')
        .where('uid', '==', uid)
        .get();
      await Promise.all(reservations.docs.map((d) => d.ref.delete()));
    } catch (e) {
      logger.warn('ACCOUNT_DELETION_USERNAME_FAILED', {
        uid,
        error: e.message,
      });
    }

    // 3) Storage klasörleri (best-effort).
    const prefixes = [
      `user_profiles/${uid}/`,
      `price_proofs/${uid}/`,
      `product_image_submissions/${uid}/`,
    ];
    for (const prefix of prefixes) {
      try {
        await admin.storage().bucket().deleteFiles({ prefix });
      } catch (e) {
        logger.warn('ACCOUNT_DELETION_STORAGE_FAILED', {
          uid,
          prefix,
          error: e.message,
        });
      }
    }

    // 4) Auth hesabı. Client zaten kendi tarafında silmeyi denemiş olabilir
    // (recent login varsa) — user-not-found hatası normaldir.
    try {
      await admin.auth().deleteUser(uid);
      logger.info('ACCOUNT_DELETION_AUTH_DELETED', { uid });
    } catch (e) {
      const code = e.code || '';
      if (code === 'auth/user-not-found') {
        logger.info('ACCOUNT_DELETION_AUTH_ALREADY_GONE', { uid });
      } else {
        logger.error('ACCOUNT_DELETION_AUTH_FAILED', {
          uid,
          error: e.message,
        });
      }
    }

    // 5) Talep dokümanını işlenmiş olarak işaretle (audit izi).
    try {
      await event.data.ref.set(
        {
          status: 'processed',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } catch (e) {
      logger.warn('ACCOUNT_DELETION_MARK_FAILED', { uid, error: e.message });
    }
    logger.info('ACCOUNT_DELETION_DONE', { uid });
  },
);

/**
 * Süresi dolan Pro aboneliklerini düşüren günlük süpürücü (audit Y4).
 *
 * `verifyPurchase` yalnız aktivasyon yazar; Play yenileme başarısız
 * olduğunda `users/{uid}.isPremium` doc'ta true kalıyordu. Client'taki
 * `premium.isActive` getter'ı `premiumUntil`'e baktığı için UI çoğunlukla
 * doğruydu ama doc-bazlı okuma yapan her tüketici (weeklySummary, ileride
 * yazılacak sorgular) yanılabilirdi. Bu job her gün 06:00'da
 * isPremium=true && premiumUntil < now olanları kapatır.
 *
 * Index gereksinimi: (isPremium ASC, premiumUntil ASC) —
 * firestore.indexes.json'a eklendi.
 */
exports.premiumExpirySweep = onSchedule(
  {
    schedule: '0 6 * * *',
    timeZone: 'Europe/Istanbul',
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    let expired;
    try {
      expired = await db
        .collection('users')
        .where('isPremium', '==', true)
        .where('premiumUntil', '<', now)
        .limit(400)
        .get();
    } catch (e) {
      logger.error('premiumExpirySweep query failed — is the '
        + '(isPremium, premiumUntil) index deployed?', { error: e.message });
      return;
    }
    if (expired.empty) {
      logger.info('premiumExpirySweep: süresi dolan abonelik yok.');
      return;
    }
    const batch = db.batch();
    for (const doc of expired.docs) {
      batch.set(
        doc.ref,
        {
          isPremium: false,
          premiumSubscriptionState: 'SUBSCRIPTION_STATE_EXPIRED',
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    await batch.commit();
    logger.info('premiumExpirySweep tamamlandı', { downgraded: expired.size });
  },
);
