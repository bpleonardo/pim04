class Employee {
  final String id, name;
  final String? phone, cpf, email, address;
  final bool isDeleted;
  const Employee({
    required this.id,
    required this.name,
    this.phone,
    this.cpf,
    this.email,
    this.address,
    this.isDeleted = false,
  });
  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'].toString(),
        name: j['nome'] as String,
        phone: j['telefone'] as String?,
        cpf: j['cpf'] as String?,
        email: j['email'] as String?,
        address: j['endereco'] as String?,
        isDeleted: j['isDeleted'] == true,
      );
}
