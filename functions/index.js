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

exports.onProductPriceDrop = onDocumentUpdated('products/{productId}', async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!beforeData || !afterData) return;

  const oldPrice = Number(beforeData.price ?? 0);
  const newPrice = Number(afterData.price ?? 0);

  if (!Number.isFinite(oldPrice) || !Number.isFinite(newPrice)) return;
  if (newPrice >= oldPrice) return;

  const productId = event.params.productId;
  const productName = (afterData.productName || afterData.name || 'Ürün').toString();

  const watchlistSnapshot = await db
    .collectionGroup('watchlist')
    .where('productId', '==', productId)
    .get();

  if (watchlistSnapshot.empty) {
    logger.info('İzleme listesinde eşleşen ürün bulunamadı', { productId });
    return;
  }

  const tokens = [];
  const tokenToRefs = new Map();

  const writePromises = watchlistSnapshot.docs.map(async (doc) => {
    const data = doc.data() || {};
    const userId = doc.ref.parent.parent.id;
    const fcmToken = (data.fcmToken || '').toString().trim();

    if (fcmToken) {
      tokens.push(fcmToken);
      if (!tokenToRefs.has(fcmToken)) tokenToRefs.set(fcmToken, []);
      tokenToRefs.get(fcmToken).push(doc.ref);
    }

    await db.collection('notifications').doc(userId).collection('items').add({
      title: 'Fiyat Düştü! 💰',
      body: `${productName}: ${oldPrice}₺ → ${newPrice}₺`,
      productId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await Promise.all(writePromises);

  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: '💰 Fiyat Düştü!',
      body: `${productName} artık ${newPrice}₺`,
    },
    data: {
      productId,
      type: 'price_drop',
    },
  });

  const cleanupPromises = [];

  response.responses.forEach((result, index) => {
    if (!result.error) return;
    const code = result.error.code;
    if (!INVALID_TOKEN_ERROR_CODES.has(code)) return;

    const token = tokens[index];
    const refs = tokenToRefs.get(token) || [];
    refs.forEach((ref) => cleanupPromises.push(ref.delete()));
  });

  await Promise.all(cleanupPromises);

  logger.info('Fiyat düşüş bildirimleri işlendi', {
    productId,
    recipients: watchlistSnapshot.size,
    pushSent: response.successCount,
    pushFailed: response.failureCount,
    cleanedTokens: cleanupPromises.length,
  });
});
