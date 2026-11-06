class Service {
  final String id, name;
  final String? description;
  final double price;
  const Service(
      {required this.id,
      required this.name,
      this.description,
      required this.price});
  factory Service.fromJson(Map<String, dynamic> j) => Service(
      id: j['id'].toString(),
      name: j['nome'] as String,
      description: j['descricao'] as String?,
      price: (j['preco'] as num).toDouble());
  Map<String, dynamic> toJson() =>
      {'id': id, 'nome': name, 'descricao': description, 'preco': price};
}
