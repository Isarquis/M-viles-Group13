import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final _searchTermsRef = FirebaseFirestore.instance.collection('search_terms');

  Future<void> incrementSearchTerm(String term) async {
    final docRef = _searchTermsRef.doc(term.toLowerCase());
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      if (doc.exists) {
        final current = doc.data()?['count'] ?? 0;
        tx.update(docRef, {'count': current + 1});
      } else {
        tx.set(docRef, {'count': 1});
      }
    });
  }

  Future<List<String>> getTopSearchTerms({int limit = 5}) async {
    final query = await _searchTermsRef.orderBy('count', descending: true).limit(limit).get();
    return query.docs.map((doc) => doc.id).toList();
  }
}
