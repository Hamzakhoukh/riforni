class Product {
  final int? id;
  final String name;
  final String unit;
  final String? imagePath;
  final String? notes;
  final int? categoriaId;

  Product({
    this.id,
    required this.name,
    required this.unit,
    this.imagePath,
    this.notes,
    this.categoriaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'image_path': imagePath,
      'notes': notes,
      'categoria_id': categoriaId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String,
      imagePath: map['image_path'] as String?,
      notes: map['notes'] as String?,
      categoriaId: map['categoria_id'] as int?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? unit,
    String? imagePath,
    String? notes,
    int? categoriaId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      categoriaId: categoriaId ?? this.categoriaId,
    );
  }
}
