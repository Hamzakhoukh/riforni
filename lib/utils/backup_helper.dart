import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/products_provider.dart';
import '../providers/suppliers_provider.dart';
import '../providers/categorie_provider.dart';
import '../providers/history_provider.dart';

/// Handles JSON backup export and import for the entire Riforni database.
class BackupHelper {
  /// Exports the current database to a JSON file and lets the user choose
  /// where to save it.
  static Future<void> exportBackup(BuildContext context) async {
    try {
      final db = DatabaseHelper.instance;

      // Collect all data as serialisable maps
      final suppliers = await db.getAllSuppliers();
      final categories = await db.getAllCategorie();
      final products = await db.getAllProducts();
      final orders = await db.getAllOrders();

      final backup = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'suppliers': suppliers.map((s) => s.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'products': products.map((p) => p.toMap()).toList(),
        'orders': orders
            .map((o) => {
                  ...o.toMap(),
                  'items': o.items.map((i) => i.toMap()).toList(),
                })
            .toList(),
      };

      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(backup);

      // Write to temp file first
      final dir = await getTemporaryDirectory();
      final fileName =
          'riforni_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      // Let user pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Salva backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: file.readAsBytesSync(),
      );

      if (!context.mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup esportato con successo')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'esportazione: $e')),
      );
    }
  }

  /// Imports a previously exported JSON backup, replacing all current data.
  /// Shows a warning dialog before overwriting.
  static Future<void> importBackup(BuildContext context) async {
    // Request storage permission on older Android versions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) return;
    }

    // Show warning dialog
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attenzione'),
        content: const Text(
          'Attenzione: l\'importazione sovrascriverà tutti i dati attuali. Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continua'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Pick JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      final path = result.files.first.path;
      String jsonStr;
      if (bytes != null) {
        jsonStr = utf8.decode(bytes);
      } else if (path != null) {
        jsonStr = await File(path).readAsString();
      } else {
        return;
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      await DatabaseHelper.instance.importBackup(data);

      if (!context.mounted) return;

      // Refresh all providers
      await Future.wait([
        context.read<SuppliersProvider>().loadSuppliers(),
        context.read<CategorieProvider>().loadCategories(),
        context.read<ProductsProvider>().loadProducts(),
        context.read<HistoryProvider>().loadOrders(),
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup importato con successo')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e')),
      );
    }
  }
}
