class Service {
  final String id, name;
  final String? description;
  final double price;
  final bool enabled, linked;
  const Service(
      {required this.id,
      required this.name,
      this.description,
      this.enabled = true,
      this.linked = false,
      required this.price});
  factory Service.fromJson(Map<String, dynamic> j) => Service(
      id: j['id'].toString(),
      name: j['nome'] as String,
      description: j['descricao'] as String?,
      enabled: j['ativo'] != false,
      linked: j['vinculado'] == true,
      price: (j['preco'] as num).toDouble());
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': name,
        'descricao': description,
        'preco': price,
        'ativo': enabled,
        'vinculado': linked
      };
}
