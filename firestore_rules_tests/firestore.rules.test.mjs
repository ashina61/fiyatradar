import { readFileSync } from 'node:fs';
import { after, before, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const projectId = 'fiyatradar-rules-test';
const rules = readFileSync('./firestore.rules', 'utf8');

let testEnv;


async function withDisabledRules(run) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await run(ctx.firestore());
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const adminDb = ctx.firestore();
    await setDoc(doc(adminDb, 'users/admin1'), { isAdmin: true, role: 'admin' });
    await setDoc(doc(adminDb, 'users/user1'), { isAdmin: false, role: 'user', points: 0 });
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

describe('users rules', () => {
  test('owner can create own user document without uid field', async () => {
    const db = testEnv.authenticatedContext('user2').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users/user2'), {
        email: 'u2@test.com',
        name: 'User 2',
        isAdmin: false,
      }),
    );
  });

  test('owner cannot create own user document with elevated points', async () => {
    const db = testEnv.authenticatedContext('user3').firestore();
    await assertFails(
      setDoc(doc(db, 'users/user3'), {
        name: 'User 3',
        points: 9999,
      }),
    );
  });

  test('owner cannot create own user document with forged trust stats', async () => {
    const db = testEnv.authenticatedContext('user4').firestore();
    await assertFails(
      setDoc(doc(db, 'users/user4'), {
        name: 'User 4',
        trustScorePercent: 100,
        trustTotalVotes: 50,
      }),
    );
  });

  test('owner can create own user document with safe default role', async () => {
    const db = testEnv.authenticatedContext('user5').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users/user5'), {
        name: 'User 5',
        role: 'user',
        points: 0,
      }),
    );
  });

  test('owner cannot create own user document with admin role', async () => {
    const db = testEnv.authenticatedContext('user6').firestore();
    await assertFails(
      setDoc(doc(db, 'users/user6'), {
        name: 'User 6',
        role: 'admin',
      }),
    );
  });

  test('owner cannot create own user document with isAdmin=true', async () => {
    const db = testEnv.authenticatedContext('user7').firestore();
    await assertFails(
      setDoc(doc(db, 'users/user7'), {
        name: 'User 7',
        isAdmin: true,
      }),
    );
  });

  test('owner cannot create own user document with mismatched uid field', async () => {
    const db = testEnv.authenticatedContext('user8').firestore();
    await assertFails(
      setDoc(doc(db, 'users/user8'), {
        uid: 'another-user',
        name: 'User 8',
      }),
    );
  });

  test('owner cannot escalate isAdmin during update', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(updateDoc(doc(db, 'users/user1'), { isAdmin: true }));
  });

  // Premium entitlement alanları yalnız verifyPurchase Cloud Function (Admin
  // SDK) tarafından yazılabilir. İstemci hiçbir şekilde kendi premium'unu
  // açamamalı (production security: ücretsiz Pro sömürüsünü engeller).
  test('owner cannot self-grant isPremium during update', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(updateDoc(doc(db, 'users/user1'), { isPremium: true }));
  });

  test('owner cannot write premium entitlement fields during update', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      updateDoc(doc(db, 'users/user1'), {
        isPremium: true,
        premiumPlan: 'fr_pro_yearly',
        premiumProductId: 'fr_pro_yearly',
        premiumSource: 'google_play',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'users/user1'), { premiumUntil: new Date() }),
    );
  });

  test('owner cannot self-grant isPremium at create time', async () => {
    const db = testEnv.authenticatedContext('userPrem').firestore();
    await assertFails(
      setDoc(doc(db, 'users/userPrem'), {
        name: 'Premium Cheater',
        isPremium: true,
      }),
    );
  });
});

describe('users/{uid}/productAlerts rules', () => {
  test('verified owner can create and update own product alert', async () => {
    const db = testEnv
      .authenticatedContext('user1', { email_verified: true })
      .firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users/user1/productAlerts/p1'), {
        targetPrice: 42.5,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'users/user1/productAlerts/p1'), {
        targetPrice: 39.9,
      }),
    );
  });

  test('another user cannot write someone else product alert doc', async () => {
    const db = testEnv
      .authenticatedContext('user2', { email_verified: true })
      .firestore();
    await assertFails(
      setDoc(doc(db, 'users/user1/productAlerts/p2'), {
        targetPrice: 21.0,
      }),
    );
  });
});

describe('products rules', () => {
  test('non-admin cannot create product', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(setDoc(doc(db, 'products/p1'), { name: 'Süt' }));
  });

  test('admin can create product', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(setDoc(doc(db, 'products/p2'), { name: 'Yoğurt' }));
    const snap = await getDoc(doc(db, 'products/p2'));
    assert.equal(snap.exists(), true);
  });

  // Regression: seed products are imported WITHOUT a `priceHistory` field, so
  // the very first community price appends to a non-existent array. This must
  // be allowed — otherwise every product's first price fails permission-denied.
  test('verified user can append first priceHistory entry on a seed product (no priceHistory field)', async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'products/pSeed'), { name: 'Çay' });
    });
    const db = testEnv
      .authenticatedContext('userSeed', { email_verified: true })
      .firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'products/pSeed'), {
        priceHistory: [{ price: 45, reportedByUid: 'userSeed' }],
      }),
    );
  });

  test('verified user cannot append a priceHistory entry impersonating another user', async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'products/pSeed2'), { name: 'Kahve' });
    });
    const db = testEnv
      .authenticatedContext('userSeed2', { email_verified: true })
      .firestore();
    await assertFails(
      updateDoc(doc(db, 'products/pSeed2'), {
        priceHistory: [{ price: 45, reportedByUid: 'someoneElse' }],
      }),
    );
  });
});

describe('priceReports rules', () => {
  // Bölgesel katkı sıralaması bir bölgedeki tüm kullanıcıların raporlarını
  // (userId filtresi olmadan) sorgular. Giriş yapan herkes listeleyebilmeli.
  test('signed-in user can list priceReports by region (leaderboard query)', async () => {
    const db = testEnv.authenticatedContext('userBoard').firestore();
    await assertSucceeds(
      getDocs(
        query(collection(db, 'priceReports'), where('cityId', '==', 'istanbul')),
      ),
    );
  });

  test('anonymous (signed-out) user cannot list priceReports', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDocs(collection(db, 'priceReports')));
  });

  test('authenticated user can create own price report', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'priceReports/user1_e1'), {
        productId: 'p1',
        entryId: 'e1',
        createdByUid: 'user1',
        price: 39.9,
      }),
    );
  });

  test('authenticated user can create own price report with string reason', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'priceReports/user1_e1b'), {
        productId: 'p1',
        entryId: 'e1b',
        createdByUid: 'user1',
        price: 38.5,
        reason: 'Fiyat etiketi kasada farklıydı',
      }),
    );
  });

  test('authenticated user cannot create report for another user uid', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/user1_e2'), {
        productId: 'p1',
        entryId: 'e2',
        createdByUid: 'user2',
        price: 49.9,
      }),
    );
  });

  test('authenticated user cannot create report as pre-verified', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/user1_e5'), {
        productId: 'p1',
        entryId: 'e5',
        createdByUid: 'user1',
        price: 29.9,
        verificationStatus: 'verified',
      }),
    );
  });

  test('authenticated user cannot create report with unexpected field', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/user1_e9'), {
        productId: 'p1',
        entryId: 'e9',
        createdByUid: 'user1',
        price: 19.9,
        injected: true,
      }),
    );
  });

  test('authenticated user cannot create report with invalid price type', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/user1_e10'), {
        productId: 'p1',
        entryId: 'e10',
        createdByUid: 'user1',
        price: '19.9',
      }),
    );
  });

  test('authenticated user cannot create report with removed status', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/user1_e6'), {
        productId: 'p1',
        entryId: 'e6',
        createdByUid: 'user1',
        price: 19.9,
        status: 'removed',
      }),
    );
  });

  test('owner cannot update moderation fields (status / verificationStatus)', async () => {
    const ownerDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'priceReports/user1_e3'), {
        productId: 'p1',
        entryId: 'e3',
        createdByUid: 'user1',
        price: 59.9,
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const userDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      updateDoc(doc(userDb, 'priceReports/user1_e3'), {
        status: 'removed',
      }),
    );
    await assertFails(
      updateDoc(doc(userDb, 'priceReports/user1_e3'), {
        verificationStatus: 'verified',
      }),
    );
  });

  test('owner can update allowed mutable fields (price/storeName)', async () => {
    const ownerDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'priceReports/user1_e4'), {
        productId: 'p1',
        entryId: 'e4',
        createdByUid: 'user1',
        price: 31.5,
        storeName: 'A',
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const userDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      updateDoc(doc(userDb, 'priceReports/user1_e4'), {
        price: 30.9,
        storeName: 'B',
      }),
    );
  });

  test('owner cannot update disallowed immutable domain fields (productId)', async () => {
    const ownerDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'priceReports/user1_e7'), {
        productId: 'p1',
        entryId: 'e7',
        createdByUid: 'user1',
        price: 12.5,
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const userDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      updateDoc(doc(userDb, 'priceReports/user1_e7'), {
        productId: 'p2',
      }),
    );
  });

  test('admin can update moderation fields on priceReports', async () => {
    const ownerDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'priceReports/user1_e8'), {
        productId: 'p1',
        entryId: 'e8',
        createdByUid: 'user1',
        price: 44.0,
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      updateDoc(doc(adminDb, 'priceReports/user1_e8'), {
        status: 'removed',
        verificationStatus: 'verified',
      }),
    );
  });

});

describe('comments rules', () => {
  test('authenticated user can create own comment with default likes state', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'comments/c1'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Harika urun',
        likes: 0,
        likedBy: [],
      }),
    );
  });

  test('authenticated user cannot create comment with pre-populated likes', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'comments/c2'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Manipulatif yorum',
        likes: 999,
      }),
    );
  });

  test('authenticated user cannot create comment with unexpected field', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'comments/c8'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Yorum',
        injected: true,
      }),
    );
  });

  test('authenticated user cannot create comment with invalid text type', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'comments/c9'), {
        productId: 'p1',
        userId: 'user1',
        text: 123,
      }),
    );
  });

  test('authenticated user cannot create comment with pre-populated likedBy list', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'comments/c3'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Manipulatif yorum',
        likedBy: ['user2'],
      }),
    );
  });

  test('comment owner can update own text', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'comments/c4'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Ilk yorum',
        likes: 0,
        likedBy: [],
      }),
    );

    await assertSucceeds(
      updateDoc(doc(db, 'comments/c4'), {
        text: 'Duzenlenmis yorum',
      }),
    );
  });

  test('comment owner cannot update likes counters directly', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'comments/c5'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Yorum',
        likes: 0,
        likedBy: [],
      }),
    );

    await assertFails(
      updateDoc(doc(db, 'comments/c5'), {
        likes: 42,
      }),
    );
  });

  test('non-owner cannot update another user comment text', async () => {
    const ownerDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'comments/c6'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Yorum',
        likes: 0,
        likedBy: [],
      }),
    );

    const otherUserDb = testEnv.authenticatedContext('user2', { email_verified: true }).firestore();
    await assertFails(
      updateDoc(doc(otherUserDb, 'comments/c6'), {
        text: 'Kotu niyetli guncelleme',
      }),
    );
  });

  test('admin can update comment moderation-related fields when needed', async () => {
    const ownerDb = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'comments/c7'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Yorum',
        likes: 0,
        likedBy: [],
      }),
    );

    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      updateDoc(doc(adminDb, 'comments/c7'), {
        likes: 1,
        likedBy: ['admin1'],
      }),
    );
  });

});

describe('points_events rules', () => {
  test('unauthenticated user cannot read points_events document', async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'points_events/e_read_0'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
      });
    });

    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'points_events/e_read_0')));
  });

  test('owner can read own points_events document', async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'points_events/e_read_1'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
      });
    });

    const ownerDb = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(getDoc(doc(ownerDb, 'points_events/e_read_1')));
  });

  test('non-owner cannot read another user points_events document', async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'points_events/e_read_2'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
      });
    });

    const otherUserDb = testEnv.authenticatedContext('user2').firestore();
    await assertFails(getDoc(doc(otherUserDb, 'points_events/e_read_2')));
  });

  test('admin can read any points_events document', async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'points_events/e_read_3'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
      });
    });

    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(getDoc(doc(adminDb, 'points_events/e_read_3')));
  });

  test('non-admin cannot create points_events document', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e1'), {
        userId: 'user1',
        eventType: 'manual_bonus',
        pointsDelta: 999,
        createdAt: new Date(),
      }),
    );
  });

  test('admin can create points_events document', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'points_events/e2'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
        createdAt: new Date(),
      }),
    );
  });

  test('admin cannot create points_events document with unexpected field', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e3'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
        backdoor: true,
        createdAt: new Date(),
      }),
    );
  });



  test('admin cannot create points_events document with non-integer pointsDelta', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e5'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 1.5,
        createdAt: new Date(),
      }),
    );
  });

  test('admin cannot create points_events document with invalid createdAt type', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e7'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
        createdAt: 'not-a-timestamp',
      }),
    );
  });

  test('admin cannot create points_events document with invalid meta type', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e8'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
        createdAt: new Date(),
        meta: 'string-meta',
      }),
    );
  });

  test('admin cannot create points_events document when points != pointsDelta', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e6'), {
        userId: 'user1',
        eventType: 'admin_bonus',
        pointsDelta: 5,
        points: 7,
        createdAt: new Date(),
      }),
    );
  });

  test('admin cannot create points_events document without required fields', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'points_events/e4'), {
        userId: 'user1',
        pointsDelta: 5,
      }),
    );
  });
});

describe('adminActions rules', () => {
  test('non-admin cannot read adminActions', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(getDoc(doc(db, 'adminActions/a1')));
  });

  test('admin can create action only for own actorUid', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'adminActions/a2'), {
        actorUid: 'admin1',
        action: 'banUser',
        createdAt: new Date(),
      }),
    );
    await assertFails(
      setDoc(doc(db, 'adminActions/a3'), {
        actorUid: 'other-admin',
        action: 'banUser',
        createdAt: new Date(),
      }),
    );
  });

  test('admin cannot create action with empty action string', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'adminActions/a4'), {
        actorUid: 'admin1',
        action: '',
        createdAt: new Date(),
      }),
    );
  });

  test('admin cannot create action with invalid targetUid type', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'adminActions/a8'), {
        actorUid: 'admin1',
        action: 'banUser',
        createdAt: new Date(),
        targetUid: 123,
      }),
    );
  });

  test('admin cannot create action with invalid reason type', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'adminActions/a9'), {
        actorUid: 'admin1',
        action: 'banUser',
        createdAt: new Date(),
        reason: true,
      }),
    );
  });

  test('admin cannot create action with invalid meta type', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'adminActions/a7'), {
        actorUid: 'admin1',
        action: 'banUser',
        createdAt: new Date(),
        meta: 'string-meta',
      }),
    );
  });

  test('admin cannot create action without createdAt', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'adminActions/a6'), {
        actorUid: 'admin1',
        action: 'banUser',
      }),
    );
  });

  test('admin cannot create action with unexpected fields', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertFails(
      setDoc(doc(db, 'adminActions/a5'), {
        actorUid: 'admin1',
        action: 'banUser',
        isSuperAdmin: true,
        createdAt: new Date(),
      }),
    );
  });
});

describe('priceGroups rules', () => {
  test('signed-in user can create with own uid as lastReporterId', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'priceGroups/g_a'), {
        productId: 'p1',
        productName: 'Süt 1L',
        chainId: 'a101',
        chainName: 'A101',
        cityId: 'adana',
        cityName: 'Adana',
        districtId: 'seyhan',
        districtName: 'Seyhan',
        latestPrice: 14.99,
        avgPrice: 14.99,
        reportCount: 1,
        verifiedCount: 0,
        photoReportCount: 0,
        confidence: 'low',
        lastReporterId: 'user1',
      }),
    );
  });

  test('cannot impersonate another user as lastReporterId', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceGroups/g_b'), {
        productId: 'p1',
        chainId: 'a101',
        cityId: 'adana',
        districtId: 'seyhan',
        reportCount: 1,
        verifiedCount: 0,
        confidence: 'low',
        lastReporterId: 'someoneElse',
      }),
    );
  });

  test('cannot inflate verifiedCount by more than +1', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'priceGroups/g_inflate'), {
        productId: 'p1',
        chainId: 'a101',
        cityId: 'adana',
        districtId: 'seyhan',
        reportCount: 1,
        verifiedCount: 0,
        confidence: 'low',
        lastReporterId: 'user1',
      });
    });
    await assertFails(
      updateDoc(doc(db, 'priceGroups/g_inflate'), {
        verifiedCount: 99999,
        lastReporterId: 'user1',
      }),
    );
  });

  test('another verified user can bump verifiedCount by +1 (ben de gördüm)', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'priceGroups/g_verify'), {
        productId: 'p1',
        chainId: 'a101',
        cityId: 'adana',
        districtId: 'seyhan',
        reportCount: 3,
        verifiedCount: 0,
        confidence: 'low',
        lastReporterId: 'user1',
      });
    });
    // user2 son raporlayan DEĞİL — verify-only bump yine de geçmeli.
    const db = testEnv.authenticatedContext('user2', { email_verified: true }).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'priceGroups/g_verify'), { verifiedCount: 1 }),
    );
  });

  test('verify-only path cannot jump verifiedCount by more than +1', async () => {
    const db = testEnv.authenticatedContext('user2', { email_verified: true }).firestore();
    await assertFails(
      updateDoc(doc(db, 'priceGroups/g_verify'), { verifiedCount: 50 }),
    );
  });

  test('verify-only path cannot smuggle other fields (price tamper)', async () => {
    const db = testEnv.authenticatedContext('user2', { email_verified: true }).firestore();
    await assertFails(
      updateDoc(doc(db, 'priceGroups/g_verify'), {
        verifiedCount: 2,
        trustedPrice: 0.01,
      }),
    );
  });

  test('cannot rewrite chain identity after creation', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'priceGroups/g_immut'), {
        productId: 'p1',
        chainId: 'a101',
        cityId: 'adana',
        districtId: 'seyhan',
        reportCount: 1,
        verifiedCount: 0,
        confidence: 'low',
        lastReporterId: 'user1',
      });
    });
    await assertFails(
      updateDoc(doc(db, 'priceGroups/g_immut'), {
        chainId: 'a101_evil',
        lastReporterId: 'user1',
      }),
    );
  });
});

describe('priceReportDedupes rules', () => {
  test('first verifier may create with self-only verifierUserIds map', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'priceReportDedupes/dk1'), {
        groupId: 'g1',
        reportId: 'r1',
        dedupeKey: 'dk1',
        verifiedCount: 1,
        verifierUserIds: { user1: true },
      }),
    );
  });

  test('cannot impersonate other user in verifierUserIds', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      setDoc(doc(db, 'priceReportDedupes/dk2'), {
        groupId: 'g1',
        reportId: 'r1',
        dedupeKey: 'dk2',
        verifiedCount: 1,
        verifierUserIds: { user2: true },
      }),
    );
  });

  test('cannot double-credit yourself on update', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'priceReportDedupes/dk3'), {
        groupId: 'g1',
        reportId: 'r1',
        dedupeKey: 'dk3',
        verifiedCount: 1,
        verifierUserIds: { user1: true },
      });
    });
    await assertFails(
      updateDoc(doc(db, 'priceReportDedupes/dk3'), {
        dedupeKey: 'dk3',
        groupId: 'g1',
        verifiedCount: 2,
        verifierUserIds: { user1: true },
      }),
    );
  });
});

describe('email verification gating', () => {
  // Token claim email_verified=true → user can perform contribution writes.
  // email_verified=false (varsayılan) → tüm katkı yazımları reddedilmeli.
  const verifiedCtx = (uid) =>
    testEnv.authenticatedContext(uid, { email_verified: true }).firestore();
  const unverifiedCtx = (uid) =>
    testEnv.authenticatedContext(uid, { email_verified: false }).firestore();

  test('unverified user cannot create priceReports doc', async () => {
    const db = unverifiedCtx('uvuser1');
    await assertFails(
      setDoc(doc(db, 'priceReports/uvuser1_e1'), {
        productId: 'p1',
        entryId: 'e1',
        createdByUid: 'uvuser1',
        price: 19.9,
      }),
    );
  });

  test('verified user can create priceReports doc', async () => {
    const db = verifiedCtx('vuser1');
    await assertSucceeds(
      setDoc(doc(db, 'priceReports/vuser1_e1'), {
        productId: 'p1',
        entryId: 'e1',
        createdByUid: 'vuser1',
        price: 19.9,
      }),
    );
  });

  test('unverified user cannot create comment', async () => {
    const db = unverifiedCtx('uvuser2');
    await assertFails(
      setDoc(doc(db, 'comments/uv_c1'), {
        productId: 'p1',
        userId: 'uvuser2',
        text: 'Doğrulanmamış yorum',
        likes: 0,
        likedBy: [],
      }),
    );
  });

  test('verified user can create comment', async () => {
    const db = verifiedCtx('vuser2');
    await assertSucceeds(
      setDoc(doc(db, 'comments/v_c1'), {
        productId: 'p1',
        userId: 'vuser2',
        text: 'Doğrulanmış yorum',
        likes: 0,
        likedBy: [],
      }),
    );
  });

  test('unverified user cannot create productAlert', async () => {
    // user doc seed (rules için).
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/uvuser3'), { isAdmin: false, role: 'user', points: 0 });
    });
    const db = unverifiedCtx('uvuser3');
    await assertFails(
      setDoc(doc(db, 'users/uvuser3/productAlerts/p1'), {
        targetPrice: 21.0,
      }),
    );
  });

  test('verified user can create productAlert', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/vuser3'), { isAdmin: false, role: 'user', points: 0 });
    });
    const db = verifiedCtx('vuser3');
    await assertSucceeds(
      setDoc(doc(db, 'users/vuser3/productAlerts/p1'), {
        targetPrice: 21.0,
      }),
    );
  });

  test('unverified user cannot change profileImageUrl', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/uvuser4'), {
        isAdmin: false,
        role: 'user',
        points: 0,
        profileImageUrl: 'https://example.com/old.jpg',
      });
    });
    const db = unverifiedCtx('uvuser4');
    await assertFails(
      updateDoc(doc(db, 'users/uvuser4'), {
        profileImageUrl: 'https://example.com/new.jpg',
      }),
    );
  });

  test('verified user can change profileImageUrl', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/vuser4'), {
        isAdmin: false,
        role: 'user',
        points: 0,
        profileImageUrl: 'https://example.com/old.jpg',
      });
    });
    const db = verifiedCtx('vuser4');
    await assertSucceeds(
      updateDoc(doc(db, 'users/vuser4'), {
        profileImageUrl: 'https://example.com/new.jpg',
      }),
    );
  });

  test('unverified user can still update safe profile fields (city/displayName)', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/uvuser5'), {
        isAdmin: false,
        role: 'user',
        points: 0,
        displayName: 'Eski Ad',
      });
    });
    const db = unverifiedCtx('uvuser5');
    await assertSucceeds(
      updateDoc(doc(db, 'users/uvuser5'), {
        displayName: 'Yeni Ad',
        city: 'İstanbul',
      }),
    );
  });

  test('unverified user cannot bump points / gamification fields', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/uvuser6'), {
        isAdmin: false,
        role: 'user',
        points: 0,
      });
    });
    const db = unverifiedCtx('uvuser6');
    await assertFails(
      updateDoc(doc(db, 'users/uvuser6'), {
        points: 10,
      }),
    );
  });

  test('unverified user cannot set emailVerified=true on user doc', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/uvuser7'), {
        isAdmin: false,
        role: 'user',
        points: 0,
        emailVerified: false,
      });
    });
    const db = unverifiedCtx('uvuser7');
    await assertFails(
      updateDoc(doc(db, 'users/uvuser7'), {
        emailVerified: true,
      }),
    );
  });

  test('verified user can set emailVerified=true on own user doc', async () => {
    await withDisabledRules(async (admin) => {
      await setDoc(doc(admin, 'users/vuser7'), {
        isAdmin: false,
        role: 'user',
        points: 0,
        emailVerified: false,
      });
    });
    const db = verifiedCtx('vuser7');
    await assertSucceeds(
      updateDoc(doc(db, 'users/vuser7'), {
        emailVerified: true,
      }),
    );
  });

  test('unverified user cannot create priceGroup', async () => {
    const db = unverifiedCtx('uvuser8');
    await assertFails(
      setDoc(doc(db, 'priceGroups/uv_g1'), {
        productId: 'p1',
        chainId: 'a101',
        cityId: 'adana',
        districtId: 'seyhan',
        reportCount: 1,
        verifiedCount: 0,
        confidence: 'low',
        lastReporterId: 'uvuser8',
      }),
    );
  });
});

describe('users.points delta cap', () => {
  test('cannot self-bump points beyond +50 in one update', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(
      updateDoc(doc(db, 'users/user1'), {
        points: 9999,
      }),
    );
  });

  test('can bump points by +10 (one report worth)', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'users/user1'), {
        points: 10,
      }),
    );
  });

  test('streak/badge fields are writable by owner', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'users/user1'), {
        currentStreak: 1,
        longestStreak: 1,
        badges: ['first_report'],
      }),
    );
  });
});

describe('users streak/badge caps (hasSafeStreakBadgeMutation)', () => {
  before(async () => {
    await withDisabledRules(async (adminDb) => {
      await setDoc(doc(adminDb, 'users/streaker'), {
        isAdmin: false,
        role: 'user',
        points: 0,
        currentStreak: 12,
        longestStreak: 12,
        verifyContributions: 3,
        photoContributions: 2,
        badges: ['first_report', 'streak_3', 'streak_7'],
      });
    });
  });

  const streakerDb = () =>
    testEnv.authenticatedContext('streaker', { email_verified: true }).firestore();

  test('cannot jump currentStreak by more than +1', async () => {
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), { currentStreak: 999 }),
    );
  });

  test('day-over-day +1 streak advance succeeds', async () => {
    await assertSucceeds(
      updateDoc(doc(streakerDb(), 'users/streaker'), {
        currentStreak: 13,
        longestStreak: 13,
      }),
    );
  });

  test('streak reset to 1 (missed days) succeeds', async () => {
    await assertSucceeds(
      updateDoc(doc(streakerDb(), 'users/streaker'), { currentStreak: 1 }),
    );
  });

  test('longestStreak cannot shrink', async () => {
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), { longestStreak: 1 }),
    );
  });

  test('verify/photo contribution counters capped at +1', async () => {
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), { verifyContributions: 50 }),
    );
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), { photoContributions: 50 }),
    );
    await assertSucceeds(
      updateDoc(doc(streakerDb(), 'users/streaker'), { verifyContributions: 4 }),
    );
  });

  test('cannot self-award unknown badge id', async () => {
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), {
        badges: ['first_report', 'streak_3', 'streak_7', 'legend_of_fiyat'],
      }),
    );
  });

  test('cannot bulk-award more than 4 new badges in one update', async () => {
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), {
        badges: [
          'first_report', 'ten_reports', 'fifty_reports',
          'first_verify', 'ten_verifies', 'first_photo',
          'streak_3', 'streak_7', 'streak_30',
        ],
      }),
    );
  });

  test('cannot remove already-earned badges', async () => {
    await assertFails(
      updateDoc(doc(streakerDb(), 'users/streaker'), { badges: [] }),
    );
  });

  test('legit single badge unlock succeeds', async () => {
    await assertSucceeds(
      updateDoc(doc(streakerDb(), 'users/streaker'), {
        badges: ['first_report', 'streak_3', 'streak_7', 'ten_reports'],
      }),
    );
  });
});

describe('appConfig rules', () => {
  test('admin can write weeklySummary config', async () => {
    const db = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'appConfig/weeklySummary'), {
        enabled: true,
        title: 'Haftalık özet',
      }),
    );
  });

  test('non-admin cannot read or write appConfig', async () => {
    const db = testEnv.authenticatedContext('user1', { email_verified: true }).firestore();
    await assertFails(getDoc(doc(db, 'appConfig/weeklySummary')));
    await assertFails(
      setDoc(doc(db, 'appConfig/weeklySummary'), { enabled: false }),
    );
  });
});
