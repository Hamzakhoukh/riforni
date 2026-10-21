import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/supplier.dart';

class SuppliersProvider extends ChangeNotifier {
  List<Supplier> _suppliers = [];

  List<Supplier> get suppliers => _suppliers;

  Future<void> loadSuppliers() async {
    _suppliers = await DatabaseHelper.instance.getAllSuppliers();
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.insertSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.updateSupplier(supplier);
    await loadSuppliers();
  }

  Future<bool> deleteSupplier(int id) async {
    final hasProducts = await DatabaseHelper.instance.supplierHasProducts(id);
    if (hasProducts) return false;
    await DatabaseHelper.instance.deleteSupplier(id);
    await loadSuppliers();
    return true;
  }

  Future<bool> supplierHasProducts(int id) async {
    return DatabaseHelper.instance.supplierHasProducts(id);
  }

  Supplier? getById(int id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
