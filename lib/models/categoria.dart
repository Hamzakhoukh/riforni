class Categoria {
  final int? id;
  final String nome;
  final String? emoji;
  final int? ordine;

  Categoria({
    this.id,
    required this.nome,
    this.emoji,
    this.ordine,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'emoji': emoji,
      'ordine': ordine,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      emoji: map['emoji'] as String?,
      ordine: map['ordine'] as int?,
    );
  }

  Categoria copyWith({
    int? id,
    String? nome,
    String? emoji,
    int? ordine,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      emoji: emoji ?? this.emoji,
      ordine: ordine ?? this.ordine,
    );
  }
}
