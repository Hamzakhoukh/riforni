import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/categoria.dart';

class CategorieProvider extends ChangeNotifier {
  List<Categoria> _categories = [];

  List<Categoria> get categories => _categories;

  Future<void> loadCategories() async {
    _categories = await DatabaseHelper.instance.getAllCategorie();
    notifyListeners();
  }

  Future<void> addCategory(Categoria category) async {
    final orderValue = category.ordine ?? (_categories.length + 1);
    final toSave = category.copyWith(ordine: orderValue);
    await DatabaseHelper.instance.insertCategoria(toSave);
    await loadCategories();
  }

  Future<void> updateCategory(Categoria category) async {
    await DatabaseHelper.instance.updateCategoria(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id, {VoidCallback? onProductsChanged}) async {
    await DatabaseHelper.instance.deleteCategoria(id);
    await loadCategories();
    onProductsChanged?.call();
  }

  Future<int> getProductsCount(int id) async {
    return DatabaseHelper.instance.getCategoriaProductsCount(id);
  }
}
