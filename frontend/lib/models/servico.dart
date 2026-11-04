class Servico {
  final String id, nome;
  final String? descricao;
  final double preco;
  const Servico(
      {required this.id,
      required this.nome,
      this.descricao,
      required this.preco});
  factory Servico.fromJson(Map<String, dynamic> j) => Servico(
      id: j['id'].toString(),
      nome: j['nome'] as String,
      descricao: j['descricao'] as String?,
      preco: (j['preco'] as num).toDouble());
  Map<String, dynamic> toJson() =>
      {'id': id, 'nome': nome, 'descricao': descricao, 'preco': preco};
}
