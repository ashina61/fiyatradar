const admin = require('firebase-admin');
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');

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
  if (oldPrice === null || newPrice === null) return;
  if (newPrice >= oldPrice) return;

  const productId = event.params.productId;
  const productName = (after.name || 'Ürün').toString();

  // ÖNCE: full collectionGroup scan + client-side `d.id === productId`.
  // Bu her ürün update'inde TÜM kullanıcıların TÜM alarmlarını okuyordu →
  // 100 alarm = 100 read × her drop. Dakikada 10 drop olsa bile maliyet
  // patlıyor.
  // SONRA: `productId` field'ı üzerinden indexli sorgu. Client tarafı
  // `setProductAlert` artık bu field'ı da yazıyor; eski dokümanlarda
  // alan yoksa fallback olarak doc id'ye düşüyoruz (geri uyumluluk).
  let interested = [];
  try {
    const alertsSnap = await db
      .collectionGroup('productAlerts')
      .where('productId', '==', productId)
      .get();
    interested = alertsSnap.docs;
  } catch (e) {
    logger.warn('productAlerts indexed query failed, falling back to scan', {
      error: e.message,
      productId,
    });
    const scan = await db.collectionGroup('productAlerts').get();
    interested = scan.docs.filter((d) => d.id === productId);
  }
  if (interested.length === 0) {
    logger.info('Fiyat düştü ama alarm kuran kullanıcı yok.', {
      productId,
      oldPrice,
      newPrice,
    });
    return;
  }

  const tokens = [];
  const tokenToRefs = new Map();

  const writePromises = interested.map(async (doc) => {
    const data = doc.data() || {};
    const userId = doc.ref.parent.parent.id;
    const targetPrice = Number(data.targetPrice);

    // Skip alerts whose target hasn't been crossed yet.
    if (Number.isFinite(targetPrice) && targetPrice > 0 && newPrice > targetPrice) {
      return;
    }

    // 1) In-app notification doc.
    await db
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        title: 'Fiyat düştü',
        body: `${productName}: ${oldPrice.toFixed(2)}₺ → ${newPrice.toFixed(2)}₺`,
        productId,
        type: 'price_drop',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // 2) Push token (best-effort) + opt-in kontrolleri.
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const u = userSnap.data() || {};
      const fcmToken = (u.fcmToken || '').toString().trim();
      const settings = (u.settings || {}).notifications || {};
      const pushEnabled = settings.pushEnabled !== false;
      const priceAlertsEnabled = settings.priceAlertsEnabled !== false;
      if (fcmToken && pushEnabled && priceAlertsEnabled) {
        tokens.push(fcmToken);
        if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
        tokenToRefs.get(fcmToken).push(userSnap.ref);
      }
    } catch (e) {
      logger.warn('FCM token okunamadı', { userId, error: e.message });
    }
  });

  await Promise.all(writePromises);

  if (tokens.length === 0) {
    logger.info('FCM token bulunan alıcı yok; sadece in-app bildirim atıldı.', {
      productId,
    });
    return;
  }

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: 'Fiyat düştü',
      body: `${productName} ${newPrice.toFixed(2)}₺`,
    },
    data: {
      productId,
      type: 'price_drop',
    },
  });

  // Cleanup unregistered tokens so we don't keep retrying them.
  const cleanupPromises = [];
  response.responses.forEach((result, index) => {
    if (!result.error) return;
    const code = result.error.code;
    if (!INVALID_TOKEN_ERROR_CODES.has(code)) return;
    const token = tokens[index];
    const refs = tokenToRefs.get(token) || [];
    refs.forEach((ref) =>
      cleanupPromises.push(ref.update({ fcmToken: admin.firestore.FieldValue.delete() }))
    );
  });
  await Promise.all(cleanupPromises);

  logger.info('Fiyat düşüş bildirimleri işlendi', {
    productId,
    oldPrice,
    newPrice,
    recipients: interested.length,
    pushSent: response.successCount,
    pushFailed: response.failureCount,
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
exports.onPriceGroupUpdate = onDocumentWritten('priceGroups/{groupId}', async (event) => {
  const before = event.data.before.exists ? event.data.before.data() || {} : null;
  const after = event.data.after.exists ? event.data.after.data() || {} : null;
  if (!after) return;

  const oldPrice = before ? Number(before.trustedPrice ?? before.latestPrice) : null;
  const newPrice = Number(after.trustedPrice ?? after.latestPrice);
  if (!Number.isFinite(newPrice) || newPrice <= 0) return;
  const hasComparableOld = Number.isFinite(oldPrice) && oldPrice > 0;
  if (hasComparableOld && Number(oldPrice) === newPrice) return;

  const productId = (after.productId || '').toString();
  if (!productId) return;
  const productName = (after.productName || 'Ürün').toString();
  const cityName = (after.cityName || '').toString();
  const districtName = (after.districtName || '').toString();
  const chainName = (after.chainName || '').toString();
  const direction = !hasComparableOld
    ? 'available'
    : newPrice < Number(oldPrice)
      ? 'drop'
      : 'rise';
  const title = direction === 'drop'
    ? 'Fiyat düştü'
    : direction === 'rise'
      ? 'Fiyat yükseldi'
      : 'Alarmındaki ürün fiyatlandı';
  const priceText = hasComparableOld
    ? `${Number(oldPrice).toFixed(2)}₺ → ${newPrice.toFixed(2)}₺`
    : `${newPrice.toFixed(2)}₺`;
  const body = `${productName}${chainName ? ' · ' + chainName : ''}: ${priceText}`;
  const type = direction === 'rise' ? 'price_rise' : 'price_drop';

  // Sadece bu ürünü takip eden kullanıcıları çek (indexed).
  let alerts;
  try {
    const snap = await db
      .collectionGroup('productAlerts')
      .where('productId', '==', productId)
      .get();
    alerts = snap.docs;
  } catch (e) {
    logger.warn('priceGroup alerts query failed', {
      groupId: event.params.groupId,
      error: e.message,
    });
    return;
  }
  if (alerts.length === 0) {
    try {
      const scan = await db.collectionGroup('productAlerts').get();
      alerts = scan.docs.filter((d) => d.id === productId);
    } catch (e) {
      logger.warn('priceGroup legacy alerts scan failed', {
        groupId: event.params.groupId,
        error: e.message,
      });
    }
  }
  if (alerts.length === 0) return;

  const tokens = [];
  const tokenToRefs = new Map();
  let inAppSent = 0;
  const writes = alerts.map(async (doc) => {
    const userId = doc.ref.parent.parent?.id;
    if (!userId) return;

    // Bölge filtresi: alarm sahibinin profil bölgesi grubun bölgesiyle
    // eşleşmiyorsa bildirme. Online gruplar Türkiye / Online olarak geçtiği
    // için bölge bilgisi olmayan kullanıcılara da ulaşabilir.
    let userCity = '';
    let userDistrict = '';
    let fcmToken = '';
    let pushEnabled = true;
    let priceAlertsEnabled = true;
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const u = userSnap.data() || {};
      userCity = (u.cityName || u.city || '').toString();
      userDistrict = (u.districtName || u.district || u.neighborhood || '').toString();
      fcmToken = (u.fcmToken || '').toString().trim();
      const settings = (u.settings || {}).notifications || {};
      pushEnabled = settings.pushEnabled !== false;
      priceAlertsEnabled = settings.priceAlertsEnabled !== false;
    } catch (e) {
      logger.warn('priceGroup: user fetch failed', { userId, error: e.message });
      return;
    }
    const isOnlineGroup = cityName.toLowerCase() === 'türkiye' &&
      districtName.toLowerCase() === 'online';
    if (
      !isOnlineGroup &&
      userCity &&
      userDistrict &&
      cityName &&
      districtName &&
      (userCity.toLowerCase() !== cityName.toLowerCase() ||
        userDistrict.toLowerCase() !== districtName.toLowerCase())
    ) {
      return;
    }

    await db
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        title,
        body,
        productId,
        groupId: event.params.groupId,
        type,
        direction,
        oldPrice: hasComparableOld ? Number(oldPrice) : null,
        newPrice,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    inAppSent++;

    // Push'u sadece opt-in kullanıcılara gönder; in-app doc yine yazıldı.
    if (fcmToken && pushEnabled && priceAlertsEnabled) {
      tokens.push(fcmToken);
      if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
      tokenToRefs.get(fcmToken).push(db.collection('users').doc(userId));
    }
  });
  await Promise.all(writes);

  if (tokens.length === 0) {
    logger.info('priceGroup change: push yok, in-app yazıldı', {
      groupId: event.params.groupId,
      productId,
      direction,
      inAppSent,
    });
    return;
  }

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title,
      body,
    },
    data: {
      productId,
      groupId: event.params.groupId,
      type,
      direction,
    },
  });

  const cleanupPromises = [];
  response.responses.forEach((result, index) => {
    if (!result.error) return;
    const code = result.error.code;
    if (!INVALID_TOKEN_ERROR_CODES.has(code)) return;
    const token = tokens[index];
    const refs = tokenToRefs.get(token) || [];
    refs.forEach((ref) =>
      cleanupPromises.push(ref.update({ fcmToken: admin.firestore.FieldValue.delete() }))
    );
  });
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
    pushSent: response.successCount,
    pushFailed: response.failureCount,
  });
});

/**
 * FiyatRadar Pro satın alma doğrulayıcı.
 *
 * `purchaseQueue/{uid_productId_purchaseId}` doc create edildiğinde devreye
 * girer. Üretimde Google Play Developer API
 * (`androidpublisher.purchases.subscriptionsv2.get`) ile token doğrulanır
 * ve subscription metadata (`expiryTimeMillis`, `autoRenewing`) okunur.
 * Bu iskelet **stub** — gerçek Play Developer client setup'ı için service
 * account key Cloud Functions config'ine eklenmesi gerek
 * (`firebase functions:config:set play.serviceaccount=...`).
 *
 * Stub davranışı: gelen verificationData boş değilse purchase'ı
 * "geçerli" kabul eder ve subscription productId'ye göre 30 / 365 gün
 * eklenir; üretimde Play API döndüğü gerçek expiry kullanılır.
 *
 * `users/{uid}` rules `immutable('isPremium')` koyduğu için bu function
 * admin SDK kullanmak zorunda — istemci aynı write'ı yapamaz.
 */
exports.verifyPurchase = onDocumentCreated(
  'purchaseQueue/{purchaseDoc}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.consumed === true) return;
    const userId = (data.userId || '').toString();
    if (!userId) return;
    const productId = (data.productId || '').toString();
    const verificationData = (data.verificationData || '').toString();
    if (!verificationData) {
      logger.warn('verifyPurchase: empty verificationData', {
        purchaseDoc: event.params.purchaseDoc,
      });
      return;
    }

    // TODO(prod): Play Developer API çağrısı — şu an stub.
    // const auth = new google.auth.GoogleAuth({
    //   scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    // });
    // const sub = await androidpublisher.purchases.subscriptionsv2.get({
    //   packageName: 'com.fiyatradar', token: verificationData,
    // });
    // const expiryMs = Number(sub.data.lineItems[0].expiryTime);
    // const autoRenew = sub.data.lineItems[0].autoRenewingPlan != null;

    // Stub: productId'ye göre süre.
    const now = Date.now();
    const days = productId === 'fr_pro_yearly'
      ? 365
      : productId === 'fr_pro_monthly'
      ? 30
      : 0;
    if (days <= 0) {
      logger.warn('verifyPurchase: unknown productId', { productId });
      return;
    }
    const expiry = new Date(now + days * 24 * 60 * 60 * 1000);

    try {
      await db.collection('users').doc(userId).set(
        {
          isPremium: true,
          premiumUntil: admin.firestore.Timestamp.fromDate(expiry),
          premiumPlan: productId,
          premiumProductId: productId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      await event.data.ref.set(
        {
          consumed: true,
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          stub: true,
        },
        { merge: true },
      );
      logger.info('Premium aktivasyon (stub)', {
        userId,
        productId,
        expiresAt: expiry.toISOString(),
      });
    } catch (e) {
      logger.error('verifyPurchase write failed', { error: e.message });
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

      // 1) In-app doc.
      try {
        await db
          .collection('users')
          .doc(u.id)
          .collection('notifications')
          .add({
            title: 'Haftalık özet',
            body:
              `${districtName} bölgesinde 7 günde ${count} yeni fiyat bildirildi.`,
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

      // 2) Push token (opt-in).
      const fcmToken = (m.fcmToken || '').toString().trim();
      if (fcmToken && pushEnabled) {
        tokens.push(fcmToken);
        if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
        tokenToRefs.get(fcmToken).push(u.ref);
      }
    }

    if (tokens.length > 0) {
      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: 'Haftalık özet',
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
