class Usuario {
  final String id, nome, login;
  const Usuario({required this.id, required this.nome, required this.login});
  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
      id: j['id'].toString(),
      nome: j['nome'] as String,
      login: j['login'] as String);
}
