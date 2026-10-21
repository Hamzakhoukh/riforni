import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/product_supplier.dart';
import '../models/order.dart';
import '../models/order_item.dart';

/// Seeds realistic test data on first launch (only when DB is empty).
class DbSeeder {
  static Future<void> seedIfEmpty() async {
    if (kIsWeb) return; // No SQLite on web
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );
    if (count != null && count > 0) return; // already seeded

    // ── Fornitori ──────────────────────────────────────────────────
    final carni = await DatabaseHelper.instance.insertSupplier(
      const Supplier(
        name: 'Macelleria Rossi',
        whatsapp: '+393331112233',
        email: 'rossi@macelleria.it',
        notes: 'Consegna ogni lunedì e giovedì mattina',
      ),
    );
    final fresco = await DatabaseHelper.instance.insertSupplier(
      const Supplier(
        name: 'Mercato del Fresco',
        whatsapp: '+393347778899',
        email: 'ordini@mercatofresco.it',
        notes: 'Frutta, verdura e latticini. Ordine entro le 18:00',
      ),
    );
    final bevande = await DatabaseHelper.instance.insertSupplier(
      const Supplier(
        name: 'Distribuzione Bianchi',
        whatsapp: '+393284445566',
        email: 'bianchi@distribuzione.it',
        notes: 'Vini, birre e bibite. Minimo ordine 50€',
      ),
    );

    // ── Prodotti per categoria ─────────────────────────────────────
    // Carne (cat 1)
    final carneProducts = [
      Product(name: 'Filetto di manzo', unit: 'kg', categoriaId: 1, notes: 'Frollato 21 giorni'),
      Product(name: 'Petto di pollo', unit: 'kg', categoriaId: 1),
      Product(name: 'Costine di maiale', unit: 'kg', categoriaId: 1),
      Product(name: 'Agnello a pezzi', unit: 'kg', categoriaId: 1, notes: 'Solo su richiesta'),
      Product(name: 'Salsiccia fresca', unit: 'kg', categoriaId: 1),
    ];

    // Pesce (cat 2)
    final pesceProducts = [
      Product(name: 'Branzino fresco', unit: 'kg', categoriaId: 2),
      Product(name: 'Gamberi rossi', unit: 'kg', categoriaId: 2, notes: 'Sicilia'),
      Product(name: 'Calamari', unit: 'kg', categoriaId: 2),
      Product(name: 'Tonno in scatola', unit: 'latte', categoriaId: 2),
    ];

    // Verdure (cat 3)
    final verdureProducts = [
      Product(name: 'Pomodori datterini', unit: 'kg', categoriaId: 3),
      Product(name: 'Melanzane', unit: 'kg', categoriaId: 3),
      Product(name: 'Zucchine', unit: 'kg', categoriaId: 3),
      Product(name: 'Patate', unit: 'kg', categoriaId: 3),
      Product(name: 'Cipolla bianca', unit: 'kg', categoriaId: 3),
      Product(name: 'Basilico fresco', unit: 'mazzo', categoriaId: 3),
    ];

    // Latticini (cat 4)
    final latticiniProducts = [
      Product(name: 'Mozzarella fior di latte', unit: 'kg', categoriaId: 4),
      Product(name: 'Parmigiano Reggiano 24m', unit: 'kg', categoriaId: 4, notes: 'Grattugiato'),
      Product(name: 'Burro', unit: 'kg', categoriaId: 4),
      Product(name: 'Ricotta fresca', unit: 'kg', categoriaId: 4),
      Product(name: 'Panna fresca 35%', unit: 'L', categoriaId: 4),
    ];

    // Bevande (cat 5)
    final bevandeProducts = [
      Product(name: 'Vino Rosso della casa', unit: 'bottiglie', categoriaId: 5, notes: 'Primitivo IGT'),
      Product(name: 'Vino Bianco della casa', unit: 'bottiglie', categoriaId: 5, notes: 'Vermentino'),
      Product(name: 'Acqua naturale 1L', unit: 'casse', categoriaId: 5),
      Product(name: 'Acqua frizzante 1L', unit: 'casse', categoriaId: 5),
      Product(name: 'Birra artigianale', unit: 'casse', categoriaId: 5),
    ];

    // Altro (cat 6)
    final altroProducts = [
      Product(name: 'Farina 00', unit: 'kg', categoriaId: 6),
      Product(name: 'Olio EVO', unit: 'L', categoriaId: 6, notes: 'DOP Sicilia'),
      Product(name: 'Sale grosso', unit: 'kg', categoriaId: 6),
      Product(name: 'Zucchero semolato', unit: 'kg', categoriaId: 6),
    ];

    Future<void> insertWithSupplier(
        List<Product> prods, Supplier defaultSupplier) async {
      for (final p in prods) {
        final inserted = await DatabaseHelper.instance.insertProduct(p);
        if (inserted.id != null && defaultSupplier.id != null) {
          await DatabaseHelper.instance.setProductSuppliers(inserted.id!, [
            ProductSupplier(
              productId: inserted.id!,
              supplierId: defaultSupplier.id!,
              isDefault: true,
            ),
          ]);
        }
      }
    }

    await insertWithSupplier(carneProducts, carni);
    await insertWithSupplier(pesceProducts, fresco);
    await insertWithSupplier(verdureProducts, fresco);
    await insertWithSupplier(latticiniProducts, fresco);
    await insertWithSupplier(bevandeProducts, bevande);
    await insertWithSupplier(altroProducts, fresco);

    // ── Cronologia ordini di esempio ───────────────────────────────
    final now = DateTime.now();

    await DatabaseHelper.instance.insertOrder(AppOrder(
      createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      supplierId: fresco.id,
      supplierName: 'Mercato del Fresco',
      message: 'Buongiorno, si prega di preparare il seguente ordine:\n\nPomodori datterini: 5 kg\nMelanzane: 3 kg\nMozzarella fior di latte: 2 kg\n\nGrazie,\nRistorante Test',
      items: [
        OrderItem(productName: 'Pomodori datterini', quantity: 5, unit: 'kg'),
        OrderItem(productName: 'Melanzane', quantity: 3, unit: 'kg'),
        OrderItem(productName: 'Mozzarella fior di latte', quantity: 2, unit: 'kg'),
      ],
    ));

    await DatabaseHelper.instance.insertOrder(AppOrder(
      createdAt: now.subtract(const Duration(days: 1, hours: 10)),
      supplierId: carni.id,
      supplierName: 'Macelleria Rossi',
      message: 'Buongiorno, si prega di preparare il seguente ordine:\n\nFiletto di manzo: 3 kg\nPetto di pollo: 5 kg\nSalsiccia fresca: 2 kg\n\nGrazie,\nRistorante Test',
      items: [
        OrderItem(productName: 'Filetto di manzo', quantity: 3, unit: 'kg'),
        OrderItem(productName: 'Petto di pollo', quantity: 5, unit: 'kg'),
        OrderItem(productName: 'Salsiccia fresca', quantity: 2, unit: 'kg'),
      ],
    ));

    await DatabaseHelper.instance.insertOrder(AppOrder(
      createdAt: now.subtract(const Duration(hours: 4)),
      supplierId: bevande.id,
      supplierName: 'Distribuzione Bianchi',
      message: 'Buongiorno, si prega di preparare il seguente ordine:\n\nVino Rosso della casa: 6 bottiglie\nAcqua naturale 1L: 2 casse\n\nGrazie,\nRistorante Test',
      items: [
        OrderItem(productName: 'Vino Rosso della casa', quantity: 6, unit: 'bottiglie'),
        OrderItem(productName: 'Acqua naturale 1L', quantity: 2, unit: 'casse'),
      ],
    ));
  }
}
