class Funcionario {
  final String id, nome;
  const Funcionario({required this.id, required this.nome});
  factory Funcionario.fromJson(Map<String, dynamic> j) =>
      Funcionario(id: j['id'].toString(), nome: j['nome'] as String);
}
