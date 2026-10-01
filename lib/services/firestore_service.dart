import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/constants.dart';

class FirestoreService extends GetxService {
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get _firestore {
    try {
      _firestoreInstance ??= FirebaseFirestore.instance;
      return _firestoreInstance;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveImageRecord({
    required String collection,
    required String docId,
    required String imageUrl,
    required String imageType,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final data = {
        'docId': docId,
        'imageUrl': imageUrl,
        'imageType': imageType,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?extraData,
      };

      await _firestore?.collection(collection).doc(docId).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<String?> getImageUrl({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore?.collection(collection).doc(docId).get();
      if (doc != null && doc.exists && doc.data() != null) {
        return doc.data()?['imageUrl'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Deletes every image document in [collection] owned by [userId].
  Future<void> deleteImageRecords({
    required String collection,
    required String userId,
  }) async {
    try {
      final db = _firestore;
      if (db == null) return;
      final snapshot = await db
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamGalleryImages(String userId) {
    try {
      if (_firestore == null) return Stream.value([]);
      return _firestore!
          .collection(DatabaseKeys.portfolioImages)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }
}
