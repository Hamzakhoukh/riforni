class ProductSupplier {
  final int productId;
  final int supplierId;
  final bool isDefault;
  final String? supplierCode;

  ProductSupplier({
    required this.productId,
    required this.supplierId,
    this.isDefault = true,
    this.supplierCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'supplier_id': supplierId,
      'is_default': isDefault ? 1 : 0,
      'supplier_code': supplierCode,
    };
  }

  factory ProductSupplier.fromMap(Map<String, dynamic> map) {
    return ProductSupplier(
      productId: map['product_id'] as int,
      supplierId: map['supplier_id'] as int,
      isDefault: (map['is_default'] as int? ?? 1) == 1,
      supplierCode: map['supplier_code'] as String?,
    );
  }
}
