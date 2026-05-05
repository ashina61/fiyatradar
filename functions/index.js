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

  // Find every user that has set an alert on this product. Doc id is the
  // productId so we can use a collection group query and match by id.
  const alertsSnap = await db.collectionGroup('productAlerts').get();
  const interested = alertsSnap.docs.filter((d) => d.id === productId);
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

    // 2) Push token (best-effort).
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const fcmToken = ((userSnap.data() || {}).fcmToken || '').toString().trim();
      if (fcmToken) {
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
