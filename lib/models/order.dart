import 'order_item.dart';

class AppOrder {
  static const String statusBozza = 'bozza';
  static const String statusInviato = 'inviato';
  static const String statusAnnullato = 'annullato';

  final int? id;
  final DateTime createdAt;
  final int? supplierId;
  final String supplierName;
  final String message;
  final List<OrderItem> items;
  final String status;
  final DateTime? sentAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  AppOrder({
    this.id,
    required this.createdAt,
    this.supplierId,
    required this.supplierName,
    required this.message,
    required this.items,
    this.status = statusBozza,
    this.sentAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  bool get isBozza => status == statusBozza;
  bool get isInviato => status == statusInviato;
  bool get isAnnullato => status == statusAnnullato;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'message': message,
      'status': status,
      'sent_at': sentAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory AppOrder.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    // Legacy support: if status is null or legacy 'sent', normalize to 'inviato'
    final rawStatus = map['status'] as String?;
    final normalizedStatus = (rawStatus == null || rawStatus == 'sent')
        ? statusInviato
        : rawStatus;

    return AppOrder(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String,
      message: map['message'] as String,
      items: items,
      status: normalizedStatus,
      sentAt: map['sent_at'] != null ? DateTime.tryParse(map['sent_at'] as String) : null,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
    );
  }

  AppOrder copyWith({
    int? id,
    DateTime? createdAt,
    int? supplierId,
    String? supplierName,
    String? message,
    List<OrderItem>? items,
    String? status,
    DateTime? sentAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return AppOrder(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      message: message ?? this.message,
      items: items ?? this.items,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

