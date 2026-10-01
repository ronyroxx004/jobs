const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const ADMIN_EMAIL = 'admin@gmail.com';

/** Caller must be signed in with the admin account. */
function assertAdmin(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  const email = (request.auth.token.email || '').toLowerCase();
  const role = request.auth.token.admin === true;
  if (email !== ADMIN_EMAIL && !role) {
    throw new HttpsError('permission-denied', 'Admin access required.');
  }
}

/** Recursively drop every record in `node` that belongs to `userId`. */
async function purgeCollection(db, path, ownerFields) {
  const snapshot = await db.ref(path).get();
  const value = snapshot.val();
  if (!value || typeof value !== 'object') return 0;

  const batch = {};
  let count = 0;
  for (const [key, record] of Object.entries(value)) {
    if (!record || typeof record !== 'object') continue;
    const owned = ownerFields.some(
      (field) => record[field] === userId,
    ) || (Array.isArray(record.participantIds) && record.participantIds.includes(userId));

    if (owned) {
      batch[key] = null;
      count += 1;
    }
  }
  if (count > 0) await db.ref(path).update(batch);
  return count;
}

/**
 * Deletes a user completely: Firebase Auth account, Realtime Database records
 * and Firestore media. Callable, so only the Admin SDK can remove the Auth
 * account (a client SDK cannot delete another user).
 */
exports.deleteUserAccount = onCall(async (request) => {
  assertAdmin(request);

  const uid = request.data && request.data.uid;
  if (!uid || typeof uid !== 'string') {
    throw new HttpsError('invalid-argument', 'A user id is required.');
  }
  if (uid === request.auth.uid) {
    throw new HttpsError('failed-precondition', 'You cannot delete your own account.');
  }

  const db = getDatabase();
  const auth = getAuth();

  let profile = {};
  try {
    const record = await db.ref(`users/${uid}`).once('value');
    profile = record.val() || {};
  } catch (e) {
    profile = {};
  }

  // 1. Tombstone first so the account cannot be recreated if this fails midway.
  await db.ref(`deleted_users/${uid}`).set({
    uid,
    email: profile.email || '',
    name: profile.name || '',
    role: profile.role || '',
    deletedAt: new Date().toISOString(),
    deletedBy: request.auth.uid,
  });

  // 2. Realtime Database records owned by this user.
  const removed = {};
  removed.resumes = await purgeCollection(db, 'resumes', ['userId']);
  removed.applications = await purgeCollection(db, 'applications', ['candidateId']);
  removed.jobs = await purgeCollection(db, 'jobs', ['recruiterId']);
  removed.mentorshipServices = await purgeCollection(db, 'mentorship_services', ['mentorId']);
  removed.bookings = await purgeCollection(db, 'bookings', ['candidateId', 'mentorId']);

  const chatsSnapshot = await db.ref('chats').once('value');
  const chats = chatsSnapshot.val() || {};
  const chatBatches = { chats: {}, messages: {} };
  let chatCount = 0;
  for (const [roomId, room] of Object.entries(chats)) {
    if (room && Array.isArray(room.participantIds) && room.participantIds.includes(uid)) {
      chatBatches.chats[roomId] = null;
      chatBatches.messages[roomId] = null;
      chatCount += 1;
    }
  }
  if (chatCount > 0) {
    await db.ref('chats').update(chatBatches.chats);
    await db.ref('messages').update(chatBatches.messages);
  }
  removed.chats = chatCount;

  await db.ref(`users/${uid}`).remove();

  // 3. Firestore media owned by this user.
  const firestore = getFirestore();
  const removedImages = [];
  for (const collection of ['user_images', 'portfolio_images']) {
    const snapshot = await firestore.collection(collection).where('userId', '==', uid).get();
    if (!snapshot.empty) {
      const batch = firestore.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      removedImages.push(collection);
    }
  }

  // 4. Firebase Auth account - only possible with the Admin SDK.
  let authDeleted = true;
  let authError = null;
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    authDeleted = false;
    authError = e && e.message ? e.message : 'unknown error';
  }

  return {
    ok: true,
    uid,
    email: profile.email || '',
    authDeleted,
    authError,
    realtimeRemoved: removed,
    firestoreRemoved: removedImages,
  };
});