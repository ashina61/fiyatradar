const admin = require('firebase-admin');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
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
 * Yeni bölgesel omurga için fiyat düşüş tetikleyicisi.
 *
 * `priceGroups/{groupId}` bir update aldığında, eğer `trustedPrice` (yoksa
 * `latestPrice`) düştüyse aynı bölgedeki ürünü takip eden kullanıcılara
 * notification doc + FCM push gönderiyoruz. Eski `onProductPriceDrop`
 * legacy `priceHistory` array'ine bağlıydı; mirror kaldırıldığında bu
 * fonksiyon devreye girip sessizce ölmesini engeller.
 *
 * Şema notu: priceGroups doc'unun `productId`, `cityId`, `districtId`,
 * `trustedPrice`, `latestPrice`, `chainName` alanları olmak zorunda.
 * Kullanıcı alarmları `users/{uid}/productAlerts/{productId}` altında ve
 * `productId` field'ı doc'ta indexli olarak yazılı (bkz: setProductAlert).
 */
exports.onPriceGroupUpdate = onDocumentUpdated('priceGroups/{groupId}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};

  const oldPrice = Number(before.trustedPrice ?? before.latestPrice);
  const newPrice = Number(after.trustedPrice ?? after.latestPrice);
  if (!Number.isFinite(oldPrice) || !Number.isFinite(newPrice)) return;
  if (newPrice >= oldPrice) return;

  const productId = (after.productId || '').toString();
  if (!productId) return;
  const cityName = (after.cityName || '').toString();
  const districtName = (after.districtName || '').toString();
  const chainName = (after.chainName || '').toString();

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
  if (alerts.length === 0) return;

  const tokens = [];
  const tokenToRefs = new Map();
  const writes = alerts.map(async (doc) => {
    const data = doc.data() || {};
    const target = Number(data.targetPrice);
    if (Number.isFinite(target) && target > 0 && newPrice > target) return;
    const userId = doc.ref.parent.parent.id;

    // Bölge filtresi: alarm sahibinin profil bölgesi grubun bölgesiyle
    // eşleşmiyorsa bildirme. Aksi halde Adana'da yaşayan kullanıcı
    // Ankara'daki bir grupta düşüş için push alıyor — gürültü olur.
    let userCity = '';
    let userDistrict = '';
    let fcmToken = '';
    let regionalDropPushEnabled = true;
    let pushEnabled = true;
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const u = userSnap.data() || {};
      userCity = (u.cityName || u.city || '').toString();
      userDistrict = (u.district || u.neighborhood || '').toString();
      fcmToken = (u.fcmToken || '').toString().trim();
      const settings = (u.settings || {}).notifications || {};
      // Opt-in flag'leri default true (kullanıcı hiç dokunmadıysa açık);
      // explicit false ise push'u atlıyoruz ama in-app notification doc'u
      // yine yazıyoruz — bildirim merkezi sinyali kaybolmasın.
      pushEnabled = settings.pushEnabled !== false;
      regionalDropPushEnabled =
        settings.regionalDropPushEnabled !== false;
    } catch (e) {
      logger.warn('priceGroup: user fetch failed', { userId, error: e.message });
      return;
    }
    if (
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
        title: 'Bölgende fiyat düştü',
        body: `${chainName ? chainName + ' · ' : ''}${oldPrice.toFixed(2)}₺ → ${newPrice.toFixed(2)}₺`,
        productId,
        groupId: event.params.groupId,
        type: 'regional_price_drop',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Push'u sadece opt-in kullanıcılara gönder; in-app doc yine yazıldı.
    if (fcmToken && pushEnabled && regionalDropPushEnabled) {
      tokens.push(fcmToken);
      if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
      tokenToRefs.get(fcmToken).push(db.collection('users').doc(userId));
    }
  });
  await Promise.all(writes);

  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: 'Bölgende fiyat düştü',
      body: `${chainName ? chainName + ' · ' : ''}${newPrice.toFixed(2)}₺`,
    },
    data: {
      productId,
      groupId: event.params.groupId,
      type: 'regional_price_drop',
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

  logger.info('Bölgesel fiyat düşüş bildirimleri işlendi', {
    groupId: event.params.groupId,
    productId,
    cityName,
    districtName,
    oldPrice,
    newPrice,
    recipients: alerts.length,
    pushSent: response.successCount,
    pushFailed: response.failureCount,
  });
});
