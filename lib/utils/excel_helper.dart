import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/product_supplier.dart';
import '../providers/products_provider.dart';

/// Excel import/export for Riforni products.
///
/// Column layout (1-indexed):
///   A: Codice (supplier code)
///   B: Nome   (product name)
///   C: Unità  (unit of measure)
///   D: Fornitore (supplier name)
///   E: Categoria (category name)
///   F: Note   (notes)
class ExcelHelper {
  static const _headers = [
    'Codice',
    'Nome',
    'Unità',
    'Fornitore',
    'Categoria',
    'Note',
  ];

  // ─── EXPORT ────────────────────────────────────────────────────────────────

  /// Exports all products to an Excel file and lets the user save it.
  static Future<void> exportToExcel(BuildContext context) async {
    try {
      final db = DatabaseHelper.instance;
      final products = await db.getAllProducts();
      final suppliers = await db.getAllSuppliers();
      final categories = await db.getAllCategorie();

      // Build lookup maps
      final supplierById = {for (final s in suppliers) s.id: s};
      final categoryById = {for (final c in categories) c.id: c};

      final excel = Excel.createExcel();
      final sheet = excel['Prodotti'];

      // Header row — bold
      for (int i = 0; i < _headers.length; i++) {
        final cell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(_headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Data rows
      for (int ri = 0; ri < products.length; ri++) {
        final p = products[ri];
        final ps = await db.getSuppliersForProduct(p.id!);
        final defaultPs = ps.isNotEmpty ? ps.first : null;
        final supplier = defaultPs != null
            ? supplierById[defaultPs.supplierId]
            : null;
        final category =
            p.categoriaId != null ? categoryById[p.categoriaId] : null;

        final row = [
          defaultPs?.supplierCode ?? '',
          p.name,
          p.unit,
          supplier?.name ?? '',
          category?.nome ?? '',
          p.notes ?? '',
        ];

        for (int ci = 0; ci < row.length; ci++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: ci, rowIndex: ri + 1))
              .value = TextCellValue(row[ci]);
        }
      }

      // Remove default empty sheet if present
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      final bytes = excel.save();
      if (bytes == null) throw Exception('Impossibile generare il file Excel');

      final dir = await getTemporaryDirectory();
      final fileName =
          'riforni_prodotti_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await FilePicker.platform.saveFile(
        dialogTitle: 'Salva Excel',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: file.readAsBytesSync(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel esportato con successo')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore esportazione: $e')),
      );
    }
  }

  // ─── IMPORT ────────────────────────────────────────────────────────────────

  /// Imports products from an Excel file (columns A–F, first row = header).
  static Future<void> importFromExcel(BuildContext context) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.sheets.keys.first;
      final sheet = excel.sheets[sheetName]!;

      final db = DatabaseHelper.instance;
      final suppliers = await db.getAllSuppliers();
      final categories = await db.getAllCategorie();

      final supplierByName = {
        for (final s in suppliers) s.name.toLowerCase(): s
      };
      final categoryByName = {
        for (final c in categories) c.nome.toLowerCase(): c
      };

      int imported = 0;

      for (int ri = 1; ri < sheet.maxRows; ri++) {
        final row = sheet.row(ri);
        if (row.isEmpty) continue;

        String _cell(int ci) {
          if (ci >= row.length) return '';
          final v = row[ci]?.value;
          if (v == null) return '';
          return v.toString().trim();
        }

        final supplierCode = _cell(0);
        final name = _cell(1);
        final unit = _cell(2);
        final supplierName = _cell(3);
        final categoryName = _cell(4);
        final notes = _cell(5);

        if (name.isEmpty) continue;

        // Resolve category id
        int? categoriaId;
        if (categoryName.isNotEmpty) {
          categoriaId = categoryByName[categoryName.toLowerCase()]?.id;
        }

        final product = Product(
          name: name,
          unit: unit.isEmpty ? 'pz' : unit,
          notes: notes.isEmpty ? null : notes,
          categoriaId: categoriaId,
        );

        final inserted = await db.insertProduct(product);

        // Link supplier if found
        if (supplierName.isNotEmpty && inserted.id != null) {
          final supplier = supplierByName[supplierName.toLowerCase()];
          if (supplier != null) {
            await db.setProductSuppliers(
              inserted.id!,
              [
                ProductSupplier(
                  productId: inserted.id!,
                  supplierId: supplier.id!,
                  isDefault: true,
                  supplierCode:
                      supplierCode.isEmpty ? null : supplierCode,
                ),
              ],
            );
          }
        }

        imported++;
      }

      if (!context.mounted) return;

      // Refresh products list
      await context.read<ProductsProvider>().loadProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported prodotti importati')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore importazione: $e')),
      );
    }
  }
}
