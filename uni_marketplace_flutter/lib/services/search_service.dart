import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_file_service.dart';

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SearchFileService _searchFileService = SearchFileService();

  Future<void> incrementSearchTerm(String term) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = _db.collection('search_terms').doc(userId).collection('terms').doc(term.toLowerCase());
    await _db.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      if (doc.exists) {
        final current = doc.data()?['count'] ?? 0;
        tx.update(docRef, {'count': current + 1});
      } else {
        tx.set(docRef, {'count': 1});
      }
    });
  }

  Future<List<String>> getTopUserSearchTerms(String userId, {int limit = 5}) async {
    final query = await _db.collection('search_terms').doc(userId).collection('terms')
      .orderBy('count', descending: true)
      .limit(limit)
      .get();

    return query.docs.map((doc) => doc.id).toList();
  }
}
