class Appointment {
  final String id, scheduledAt, status, clientName, employeeName;
  final double total;
  final String employeeId;
  final List<String> services;
  const Appointment(
      {required this.id,
      required this.scheduledAt,
      required this.status,
      required this.clientName,
      required this.employeeName,
      required this.total,
      this.employeeId = '',
      this.services = const []});
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
          id: j['id'].toString(),
          scheduledAt: j['dataAgendamento'].toString(),
          status: j['status'] as String,
          clientName:
              (j['cliente']?['nome'] ?? j['nomeCliente'] ?? '').toString(),
          employeeName:
              (j['funcionario']?['nome'] ?? j['nomeFuncionario'] ?? '')
                  .toString(),
          total: (j['total'] as num).toDouble(),
          employeeId:
              (j['funcionario']?['id'] ?? j['idFuncionario'] ?? '').toString(),
          services: [
            for (final s in (j['servicos'] as List? ?? []))
              s is Map ? s['nome'].toString() : s.toString()
          ]);

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataAgendamento': scheduledAt,
        'status': status,
        'nomeCliente': clientName,
        'nomeFuncionario': employeeName,
        'idFuncionario': employeeId,
        'total': total,
        'servicos': services,
      };
}
