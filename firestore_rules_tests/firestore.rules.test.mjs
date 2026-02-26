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
