
abstract class CategoryRepo {
  Future<void> addCategory({required String uid, required String title});

  Future<void> deleteCategory({
    required String uid,
    required String categoryTitle,
  });

  Future<List<String>> getCategories({required String uid});
}
