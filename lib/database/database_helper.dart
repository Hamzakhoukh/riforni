import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../models/product_supplier.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/categoria.dart';

/// Singleton SQLite database helper for Riforni.
/// Database version 4 — manages suppliers, products, categories, orders.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('SQLite not supported on web');
    if (_database != null) return _database!;
    _database = await _initDB('riforni.db');
    return _database!;
  }


  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        whatsapp TEXT NOT NULL,
        email TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE categorie (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        emoji TEXT,
        ordine INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        image_path TEXT,
        notes TEXT,
        categoria_id INTEGER REFERENCES categorie(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE product_suppliers (
        product_id INTEGER NOT NULL,
        supplier_id INTEGER NOT NULL,
        is_default INTEGER DEFAULT 1,
        supplier_code TEXT,
        PRIMARY KEY (product_id, supplier_id),
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');
    await _createHistoryTables(db);
    await _seedDefaultCategories(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createHistoryTables(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE product_suppliers ADD COLUMN supplier_code TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorie (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          emoji TEXT,
          ordine INTEGER
        )
      ''');
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN categoria_id INTEGER REFERENCES categorie(id)',
        );
      } catch (_) {
        // column might already exist
      }
      await _seedDefaultCategories(db);
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          "ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'inviato'",
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN sent_at TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE orders ADD COLUMN is_deleted INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN deleted_at TEXT');
      } catch (_) {}
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final List<Map<String, dynamic>> defaultCategories = [
      {'nome': 'Carne', 'emoji': '🥩', 'ordine': 1},
      {'nome': 'Pesce', 'emoji': '🐟', 'ordine': 2},
      {'nome': 'Verdure', 'emoji': '🥦', 'ordine': 3},
      {'nome': 'Latticini', 'emoji': '🧀', 'ordine': 4},
      {'nome': 'Bevande', 'emoji': '🍷', 'ordine': 5},
      {'nome': 'Altro', 'emoji': '📦', 'ordine': 6},
    ];
    for (final cat in defaultCategories) {
      await db.insert('categorie', cat,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _createHistoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        supplier_id INTEGER,
        supplier_name TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT DEFAULT 'inviato',
        sent_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');
  }

  // ─────────────────────────── SUPPLIERS ───────────────────────────

  Future<List<Supplier>> getAllSuppliers() async {
    if (kIsWeb) return _mockSuppliers;
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  // ── Web mock data (shown when SQLite unavailable) ─────────────────
  static final List<Supplier> _mockSuppliers = [
    const Supplier(id: 1, name: 'Macelleria Rossi', whatsapp: '+393331112233',
        email: 'rossi@macelleria.it', notes: 'Consegna lunedì e giovedì mattina'),
    const Supplier(id: 2, name: 'Mercato del Fresco', whatsapp: '+393347778899',
        email: 'ordini@mercatofresco.it', notes: 'Frutta, verdura e latticini. Ordine entro le 18:00'),
    const Supplier(id: 3, name: 'Distribuzione Bianchi', whatsapp: '+393284445566',
        email: 'bianchi@distribuzione.it', notes: 'Vini, birre e bibite. Minimo 50€'),
  ];

  static final List<Product> _mockProducts = [
    Product(id: 1,  name: 'Filetto di manzo',       unit: 'kg',       categoriaId: 1),
    Product(id: 2,  name: 'Petto di pollo',          unit: 'kg',       categoriaId: 1),
    Product(id: 3,  name: 'Salsiccia fresca',        unit: 'kg',       categoriaId: 1),
    Product(id: 4,  name: 'Costine di maiale',       unit: 'kg',       categoriaId: 1),
    Product(id: 5,  name: 'Branzino fresco',         unit: 'kg',       categoriaId: 2),
    Product(id: 6,  name: 'Gamberi rossi',           unit: 'kg',       categoriaId: 2),
    Product(id: 7,  name: 'Calamari',                unit: 'kg',       categoriaId: 2),
    Product(id: 8,  name: 'Pomodori datterini',      unit: 'kg',       categoriaId: 3),
    Product(id: 9,  name: 'Melanzane',               unit: 'kg',       categoriaId: 3),
    Product(id: 10, name: 'Zucchine',                unit: 'kg',       categoriaId: 3),
    Product(id: 11, name: 'Patate',                  unit: 'kg',       categoriaId: 3),
    Product(id: 12, name: 'Cipolla bianca',          unit: 'kg',       categoriaId: 3),
    Product(id: 13, name: 'Basilico fresco',         unit: 'mazzo',    categoriaId: 3),
    Product(id: 14, name: 'Mozzarella fior di latte',unit: 'kg',       categoriaId: 4),
    Product(id: 15, name: 'Parmigiano Reggiano 24m', unit: 'kg',       categoriaId: 4),
    Product(id: 16, name: 'Burro',                   unit: 'kg',       categoriaId: 4),
    Product(id: 17, name: 'Panna fresca 35%',        unit: 'L',        categoriaId: 4),
    Product(id: 18, name: 'Vino Rosso della casa',   unit: 'bottiglie',categoriaId: 5),
    Product(id: 19, name: 'Vino Bianco della casa',  unit: 'bottiglie',categoriaId: 5),
    Product(id: 20, name: 'Acqua naturale 1L',       unit: 'casse',    categoriaId: 5),
    Product(id: 21, name: 'Acqua frizzante 1L',      unit: 'casse',    categoriaId: 5),
    Product(id: 22, name: 'Birra artigianale',       unit: 'casse',    categoriaId: 5),
    Product(id: 23, name: 'Farina 00',               unit: 'kg',       categoriaId: 6),
    Product(id: 24, name: 'Olio EVO',                unit: 'L',        categoriaId: 6),
    Product(id: 25, name: 'Sale grosso',             unit: 'kg',       categoriaId: 6),
  ];

  static final List<Categoria> _mockCategorie = [
    Categoria(id: 1, nome: 'Carne',     emoji: '🥩', ordine: 1),
    Categoria(id: 2, nome: 'Pesce',     emoji: '🐟', ordine: 2),
    Categoria(id: 3, nome: 'Verdure',   emoji: '🥦', ordine: 3),
    Categoria(id: 4, nome: 'Latticini', emoji: '🧀', ordine: 4),
    Categoria(id: 5, nome: 'Bevande',   emoji: '🍷', ordine: 5),
    Categoria(id: 6, nome: 'Altro',     emoji: '📦', ordine: 6),
  ];

  Future<Supplier> insertSupplier(Supplier supplier) async {
    if (kIsWeb) {
      final newId = (_mockSuppliers.map((s) => s.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      final newS = supplier.copyWith(id: newId);
      _mockSuppliers.add(newS);
      return newS;
    }
    final db = await database;
    final id = await db.insert('suppliers', supplier.toMap()..remove('id'));
    return supplier.copyWith(id: id);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    if (kIsWeb) {
      final index = _mockSuppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) _mockSuppliers[index] = supplier;
      return;
    }
    final db = await database;
    await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<void> deleteSupplier(int id) async {
    if (kIsWeb) {
      _mockSuppliers.removeWhere((s) => s.id == id);
      return;
    }
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> supplierHasProducts(int supplierId) async {
    if (kIsWeb) return false;
    final db = await database;
    final result = await db.query(
      'product_suppliers',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ─────────────────────────── PRODUCTS ────────────────────────────

  Future<List<Product>> getAllProducts() async {
    if (kIsWeb) return _mockProducts;
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }


  Future<Product> insertProduct(Product product) async {
    if (kIsWeb) {
      final newId = (_mockProducts.map((p) => p.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      final newP = product.copyWith(id: newId);
      _mockProducts.add(newP);
      return newP;
    }
    final db = await database;
    final map = product.toMap()..remove('id');
    final id = await db.insert('products', map);
    return product.copyWith(id: id);
  }

  Future<void> updateProduct(Product product) async {
    if (kIsWeb) {
      final index = _mockProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) _mockProducts[index] = product;
      return;
    }
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int id) async {
    if (kIsWeb) {
      _mockProducts.removeWhere((p) => p.id == id);
      return;
    }
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────── PRODUCT-SUPPLIERS ───────────────────────

  Future<void> setProductSuppliers(
      int productId, List<ProductSupplier> suppliers) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'product_suppliers',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    for (final ps in suppliers) {
      await db.insert('product_suppliers', ps.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Supplier? _getMockDefaultSupplier(int productId) {
    if (_mockSuppliers.isEmpty) return null;
    if (productId <= 4) return _mockSuppliers[0]; // Macelleria Rossi (Carne)
    if (productId <= 17 && _mockSuppliers.length > 1) return _mockSuppliers[1]; // Mercato del Fresco
    if (productId <= 22 && _mockSuppliers.length > 2) return _mockSuppliers[2]; // Distribuzione Bianchi
    return _mockSuppliers.length > 1 ? _mockSuppliers[1] : _mockSuppliers.first;
  }

  Future<List<ProductSupplier>> getSuppliersForProduct(int productId) async {
    if (kIsWeb) {
      final s = _getMockDefaultSupplier(productId);
      return s != null ? [ProductSupplier(productId: productId, supplierId: s.id!, isDefault: true)] : [];
    }
    final db = await database;
    final maps = await db.query(
      'product_suppliers',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return maps.map((m) => ProductSupplier.fromMap(m)).toList();
  }

  Future<List<Supplier>> getSuppliersForProductAsFull(int productId) async {
    if (kIsWeb) {
      final s = _getMockDefaultSupplier(productId);
      return s != null ? [s] : (_mockSuppliers.isNotEmpty ? [_mockSuppliers.first] : []);
    }
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM suppliers s
      INNER JOIN product_suppliers ps ON s.id = ps.supplier_id
      WHERE ps.product_id = ?
      ORDER BY ps.is_default DESC, s.name ASC
    ''', [productId]);
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<Supplier?> getDefaultSupplierForProduct(int productId) async {
    if (kIsWeb) {
      return _getMockDefaultSupplier(productId);
    }
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM suppliers s
      INNER JOIN product_suppliers ps ON s.id = ps.supplier_id
      WHERE ps.product_id = ? AND ps.is_default = 1
      LIMIT 1
    ''', [productId]);
    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  // ─────────────────────────── CATEGORIE ───────────────────────────

  Future<List<Categoria>> getAllCategorie() async {
    if (kIsWeb) return _mockCategorie;
    final db = await database;
    final maps =
        await db.query('categorie', orderBy: 'ordine ASC, nome ASC');
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<Categoria> insertCategoria(Categoria categoria) async {
    if (kIsWeb) {
      final newId = (_mockCategorie.map((c) => c.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      final newC = categoria.copyWith(id: newId);
      _mockCategorie.add(newC);
      return newC;
    }
    final db = await database;
    final map = categoria.toMap()..remove('id');
    final id = await db.insert('categorie', map);
    return categoria.copyWith(id: id);
  }

  Future<void> updateCategoria(Categoria categoria) async {
    if (kIsWeb) {
      final index = _mockCategorie.indexWhere((c) => c.id == categoria.id);
      if (index != -1) _mockCategorie[index] = categoria;
      return;
    }
    final db = await database;
    await db.update(
      'categorie',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<void> deleteCategoria(int id) async {
    if (kIsWeb) {
      _mockCategorie.removeWhere((c) => c.id == id);
      return;
    }
    final db = await database;
    await db.update(
      'products',
      {'categoria_id': null},
      where: 'categoria_id = ?',
      whereArgs: [id],
    );
    await db.delete('categorie', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCategoriaProductsCount(int categoriaId) async {
    if (kIsWeb) return 0;
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM products WHERE categoria_id = ?',
      [categoriaId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─────────────────────────── ORDERS ──────────────────────────────

  static final List<AppOrder> _webOrders = _mockOrders();

  Future<List<AppOrder>> getAllOrders({bool includeDeleted = false}) async {
    if (kIsWeb) {
      if (includeDeleted) return List.from(_webOrders);
      return _webOrders.where((o) => !o.isDeleted).toList();
    }
    final db = await database;
    final orderMaps = await db.query(
      'orders',
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );
    final List<AppOrder> orders = [];
    for (final orderMap in orderMaps) {
      final id = orderMap['id'] as int;
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [id],
      );
      final items = itemMaps.map((m) => OrderItem.fromMap(m)).toList();
      orders.add(AppOrder.fromMap(orderMap, items));
    }
    return orders;
  }

  Future<int> insertOrder(AppOrder order) async {
    if (kIsWeb) {
      final newId = (_webOrders.map((o) => o.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _webOrders.insert(0, order.copyWith(id: newId));
      return newId;
    }
    final db = await database;
    final orderId = await db.insert('orders', order.toMap()..remove('id'));
    for (final item in order.items) {
      final itemMap = item.toMap()
        ..remove('id')
        ..['order_id'] = orderId;
      await db.insert('order_items', itemMap);
    }
    return orderId;
  }

  Future<void> updateOrderStatus(int orderId, String status, {DateTime? sentAt}) async {
    final now = sentAt ?? (status == AppOrder.statusInviato ? DateTime.now() : null);
    if (kIsWeb) {
      final index = _webOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _webOrders[index] = _webOrders[index].copyWith(
          status: status,
          sentAt: now ?? _webOrders[index].sentAt,
        );
      }
      return;
    }
    final db = await database;
    final Map<String, dynamic> values = {
      'status': status,
    };
    if (now != null) {
      values['sent_at'] = now.toIso8601String();
    }
    await db.update('orders', values, where: 'id = ?', whereArgs: [orderId]);
  }

  Future<void> deleteOrder(int id) async {
    if (kIsWeb) {
      final index = _webOrders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _webOrders[index] = _webOrders[index].copyWith(
          isDeleted: true,
          deletedAt: DateTime.now(),
        );
      }
      return;
    }
    final db = await database;
    await db.update(
      'orders',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all data and restores from a JSON backup map (created by BackupHelper).
  Future<void> importBackup(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data (order matters for FK constraints)
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('product_suppliers');
      await txn.delete('products');
      await txn.delete('categorie');
      await txn.delete('suppliers');

      // Re-insert suppliers
      for (final s in (data['suppliers'] as List? ?? [])) {
        await txn.insert('suppliers', Map<String, dynamic>.from(s as Map));
      }
      // Re-insert categories
      for (final c in (data['categories'] as List? ?? [])) {
        await txn.insert('categorie', Map<String, dynamic>.from(c as Map));
      }
      // Re-insert products
      for (final p in (data['products'] as List? ?? [])) {
        await txn.insert('products', Map<String, dynamic>.from(p as Map));
      }
      // Re-insert orders + items
      for (final o in (data['orders'] as List? ?? [])) {
        final orderMap = Map<String, dynamic>.from(o as Map);
        final items = orderMap.remove('items') as List? ?? [];
        final newOrderId = await txn.insert('orders', orderMap);
        for (final item in items) {
          final itemMap = Map<String, dynamic>.from(item as Map)
            ..remove('id')
            ..['order_id'] = newOrderId;
          await txn.insert('order_items', itemMap);
        }
      }
    });
  }

  static List<AppOrder> _mockOrders() {
    final now = DateTime.now();
    return [
      AppOrder(
        id: 1,
        createdAt: now.subtract(const Duration(hours: 2)),
        supplierId: 2,
        supplierName: 'Mercato del Fresco',
        message: 'Ordine di esempio',
        status: AppOrder.statusInviato,
        sentAt: now.subtract(const Duration(hours: 2)),
        items: [
          OrderItem(id: 1, orderId: 1, productName: 'Pomodori datterini', quantity: 5, unit: 'kg'),
          OrderItem(id: 2, orderId: 1, productName: 'Melanzane', quantity: 3, unit: 'kg'),
          OrderItem(id: 3, orderId: 1, productName: 'Mozzarella fior di latte', quantity: 2, unit: 'kg'),
        ],
      ),
      AppOrder(
        id: 2,
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
        supplierId: 1,
        supplierName: 'Macelleria Rossi',
        message: 'Ordine di esempio',
        status: AppOrder.statusInviato,
        sentAt: now.subtract(const Duration(days: 1, hours: 8)),
        items: [
          OrderItem(id: 4, orderId: 2, productName: 'Filetto di manzo', quantity: 3, unit: 'kg'),
          OrderItem(id: 5, orderId: 2, productName: 'Petto di pollo', quantity: 5, unit: 'kg'),
          OrderItem(id: 6, orderId: 2, productName: 'Salsiccia fresca', quantity: 2, unit: 'kg'),
        ],
      ),
      AppOrder(
        id: 3,
        createdAt: now.subtract(const Duration(days: 2, hours: 15)),
        supplierId: 3,
        supplierName: 'Distribuzione Bianchi',
        message: 'Ordine di esempio',
        status: AppOrder.statusInviato,
        sentAt: now.subtract(const Duration(days: 2, hours: 15)),
        items: [
          OrderItem(id: 7, orderId: 3, productName: 'Vino Rosso della casa', quantity: 6, unit: 'bottiglie'),
          OrderItem(id: 8, orderId: 3, productName: 'Acqua naturale 1L', quantity: 2, unit: 'casse'),
          OrderItem(id: 9, orderId: 3, productName: 'Birra artigianale', quantity: 1, unit: 'casse'),
        ],
      ),
    ];
  }
}
