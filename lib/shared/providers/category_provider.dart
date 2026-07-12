import 'package:expence_app/core/services/session_maganger.dart';
import 'package:expence_app/shared/backend_parts/repo/category_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dialogs/category_dialog.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepo _repository;
  final String uid;

  final List<String> _cachedCategories = [];
  List<String> get categories => List.unmodifiable(_cachedCategories);


  CategoryProvider({
    required CategoryRepo repository,
  })  : _repository = repository,
        uid = SessionManager.instance.requireUid {
    fetchCategories();
  }

  Future<void> showAddCategoryDialog(BuildContext context) async {
    await CategoryDialog.show(
      context: context,
      categories: _cachedCategories,
      onAdd: (title) async {
        await _repository.addCategory(
          uid: uid,
          title: title,
        );

        await fetchCategories();
      },
      onDelete: (title) async {
        await deleteCategory(title);
      },
    );
  }

  Future<void> deleteCategory(String categoryTitle) async {
    try {
      await _repository.deleteCategory(
        uid: uid,
        categoryTitle: categoryTitle,
      );

      await fetchCategories();

      if (kDebugMode) {
        print('🗑️ Category deleted: $categoryTitle');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete category: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final categories = await _repository.getCategories(uid: uid);

      _cachedCategories
        ..clear()
        ..addAll(categories);

      if (kDebugMode) {
        print("📂 Categories loaded: $_cachedCategories");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to fetch categories: $e");
    }
  }
}