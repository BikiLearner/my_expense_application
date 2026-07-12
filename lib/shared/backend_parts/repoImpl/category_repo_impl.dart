
import 'package:expence_app/shared/backend_parts/datasources/category_datesource.dart';

import '../repo/category_repo.dart';

class CategoryRepoImpl implements CategoryRepo {
  CategoryRepoImpl({CategoryDateSource? datasource})
      : _datasource = datasource ?? CategoryDateSource();

  final CategoryDateSource _datasource;
  @override
  Future<void> addCategory({required String uid, required String title}) {
    return _datasource.addCategory(uid: uid, title: title);
  }

  @override
  Future<void> deleteCategory({
    required String uid,
    required String categoryTitle,
  }) {
    return _datasource.deleteCategory(uid: uid, categoryTitle: categoryTitle);
  }

  @override
  Future<List<String>> getCategories({required String uid}) {
    return _datasource.getCategories(uid: uid);
  }
}