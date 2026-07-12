import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/core/constants/collection_name_constant.dart';

class CategoryDateSource {
  CategoryDateSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _usersCollection() =>
      _firestore.collection(CollectionName.users);
  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _usersCollection().doc(uid);
  /// Adds a category document.
  Future<void> addCategory({required String uid, required String title}) async {
    await _userRef(uid).collection('categories').add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes every category document matching the given title.
  Future<void> deleteCategory({
    required String uid,
    required String categoryTitle,
  }) async {
    final snapshot = await _userRef(uid)
        .collection('categories')
        .where('title', isEqualTo: categoryTitle)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Returns the distinct, non-empty, trimmed category titles ordered by
  /// createdAt.
  Future<List<String>> getCategories({required String uid}) async {
    final snapshot = await _userRef(uid)
        .collection('categories')
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['title'] as String).trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

}