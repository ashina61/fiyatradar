import { readFileSync } from 'node:fs';
import { after, before, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const projectId = 'fiyatradar-rules-test';
const rules = readFileSync('../firestore.rules', 'utf8');

let testEnv;

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
  await testEnv.cleanup();
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
});

describe('priceReports rules', () => {
  test('authenticated user can create own price report', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'priceReports/r1'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 39.9,
      }),
    );
  });

  test('authenticated user cannot create report for another user uid', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/r2'), {
        productId: 'p1',
        createdByUid: 'user2',
        price: 49.9,
      }),
    );
  });

  test('authenticated user cannot create report as pre-verified', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/r5'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 29.9,
        verificationStatus: 'verified',
      }),
    );
  });

  test('authenticated user cannot create report with unexpected field', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/r9'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 19.9,
        injected: true,
      }),
    );
  });

  test('authenticated user cannot create report with invalid price type', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/r10'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: '19.9',
      }),
    );
  });

  test('authenticated user cannot create report with removed status', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'priceReports/r6'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 19.9,
        status: 'removed',
      }),
    );
  });

  test('owner cannot update moderation fields (status / verificationStatus)', async () => {
    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(adminDb, 'priceReports/r3'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 59.9,
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const userDb = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      updateDoc(doc(userDb, 'priceReports/r3'), {
        status: 'removed',
      }),
    );
    await assertFails(
      updateDoc(doc(userDb, 'priceReports/r3'), {
        verificationStatus: 'verified',
      }),
    );
  });

  test('owner can update allowed mutable fields (price/storeName)', async () => {
    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(adminDb, 'priceReports/r4'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 31.5,
        storeName: 'A',
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const userDb = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(
      updateDoc(doc(userDb, 'priceReports/r4'), {
        price: 30.9,
        storeName: 'B',
      }),
    );
  });

  test('owner cannot update disallowed immutable domain fields (productId)', async () => {
    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(adminDb, 'priceReports/r7'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 12.5,
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    const userDb = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      updateDoc(doc(userDb, 'priceReports/r7'), {
        productId: 'p2',
      }),
    );
  });

  test('admin can update moderation fields on priceReports', async () => {
    const adminDb = testEnv.authenticatedContext('admin1').firestore();
    await assertSucceeds(
      setDoc(doc(adminDb, 'priceReports/r8'), {
        productId: 'p1',
        createdByUid: 'user1',
        price: 44.0,
        status: 'active',
        verificationStatus: 'unverified',
      }),
    );

    await assertSucceeds(
      updateDoc(doc(adminDb, 'priceReports/r8'), {
        status: 'removed',
        verificationStatus: 'verified',
      }),
    );
  });

});

describe('comments rules', () => {
  test('authenticated user can create own comment with default likes state', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
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
    const db = testEnv.authenticatedContext('user1').firestore();
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
    const db = testEnv.authenticatedContext('user1').firestore();
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
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      setDoc(doc(db, 'comments/c9'), {
        productId: 'p1',
        userId: 'user1',
        text: 123,
      }),
    );
  });

  test('authenticated user cannot create comment with pre-populated likedBy list', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
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
    const db = testEnv.authenticatedContext('user1').firestore();
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
    const db = testEnv.authenticatedContext('user1').firestore();
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
    const ownerDb = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'comments/c6'), {
        productId: 'p1',
        userId: 'user1',
        text: 'Yorum',
        likes: 0,
        likedBy: [],
      }),
    );

    const otherUserDb = testEnv.authenticatedContext('user2').firestore();
    await assertFails(
      updateDoc(doc(otherUserDb, 'comments/c6'), {
        text: 'Kotu niyetli guncelleme',
      }),
    );
  });

  test('admin can update comment moderation-related fields when needed', async () => {
    const ownerDb = testEnv.authenticatedContext('user1').firestore();
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
