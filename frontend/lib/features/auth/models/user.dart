class User {
  final String id, name, login;
  const User({required this.id, required this.name, required this.login});
  factory User.fromJson(Map<String, dynamic> j) => User(
      id: j['id'].toString(),
      name: j['nome'] as String,
      login: j['login'] as String);
}
