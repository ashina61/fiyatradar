import 'package:cloud_firestore/cloud_firestore.dart';

class SearchHistoryService {
  SearchHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _searchHistoryRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('searchHistory');
  }

  Future<void> saveSearchHistory(String userId, String query) async {
    final doc = _searchHistoryRef(userId).doc();
    await doc.set({
      'query': query,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getSearchHistory(String userId, {int limit = 10}) {
    return _searchHistoryRef(userId).snapshots().map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return docs.take(limit).map((doc) => doc.data()['query'] as String).toList();
    });
  }

  Future<void> clearSearchHistory(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _searchHistoryRef(userId).get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
