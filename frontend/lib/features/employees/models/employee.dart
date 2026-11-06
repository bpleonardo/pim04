class Employee {
  final String id, name;
  const Employee({required this.id, required this.name});
  factory Employee.fromJson(Map<String, dynamic> j) =>
      Employee(id: j['id'].toString(), name: j['nome'] as String);
}
