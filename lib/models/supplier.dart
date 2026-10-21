class Supplier {
  final int? id;
  final String name;
  final String whatsapp;
  final String? email;
  final String? notes;

  const Supplier({
    this.id,
    required this.name,
    required this.whatsapp,
    this.email,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'whatsapp': whatsapp,
      'email': email,
      'notes': notes,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      whatsapp: map['whatsapp'] as String,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? whatsapp,
    String? email,
    String? notes,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
