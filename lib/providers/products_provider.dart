import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/product_supplier.dart';
import '../models/supplier.dart';

class ProductsProvider extends ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    _products = await DatabaseHelper.instance.getAllProducts();
    notifyListeners();
  }

  Future<void> addProduct(
    Product product,
    List<ProductSupplier> suppliers,
  ) async {
    final inserted = await DatabaseHelper.instance.insertProduct(product);
    if (inserted.id != null) {
      final links = suppliers
          .map((ps) => ProductSupplier(
                productId: inserted.id!,
                supplierId: ps.supplierId,
                isDefault: ps.isDefault,
              ))
          .toList();
      await DatabaseHelper.instance.setProductSuppliers(inserted.id!, links);
    }
    await loadProducts();
  }

  Future<void> updateProduct(
    Product product,
    List<ProductSupplier> suppliers,
  ) async {
    await DatabaseHelper.instance.updateProduct(product);
    if (product.id != null) {
      await DatabaseHelper.instance.setProductSuppliers(product.id!, suppliers);
    }
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await loadProducts();
  }

  Future<List<ProductSupplier>> getSuppliersForProduct(int productId) async {
    return DatabaseHelper.instance.getSuppliersForProduct(productId);
  }

  Future<List<Supplier>> getFullSuppliersForProduct(int productId) async {
    return DatabaseHelper.instance.getSuppliersForProductAsFull(productId);
  }

  Future<Supplier?> getDefaultSupplier(int productId) async {
    return DatabaseHelper.instance.getDefaultSupplierForProduct(productId);
  }
}
