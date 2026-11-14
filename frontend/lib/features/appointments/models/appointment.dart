class Appointment {
  final String id, scheduledAt, status, clientName, employeeName;
  final String phone;
  final int revision;
  final List<String> serviceIds;
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
      this.phone = '',
      this.revision = 0,
      this.serviceIds = const [],
      this.employeeId = '',
      this.services = const []});
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
          id: j['id'].toString(),
          phone: (j['cliente']?['telefone'] ?? j['telefoneCliente'] ?? '')
              .toString(),
          revision: (j['revision'] as num?)?.toInt() ?? 0,
          serviceIds: (j['serviceIds'] as List?)?.cast<String>() ??
              [
                for (final s in (j['servicos'] as List? ?? []))
                  if (s is Map) s['id'].toString()
              ],
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
              if (s is Map)
                s['ativo'] == false
                    ? "${s['nome']} (desabilitado)"
                    : s['nome'].toString()
              else
                s.toString()
          ]);

  Map<String, dynamic> toJson() => {
        'id': id,
        'telefoneCliente': phone,
        'revision': revision,
        'serviceIds': serviceIds,
        'dataAgendamento': scheduledAt,
        'status': status,
        'nomeCliente': clientName,
        'nomeFuncionario': employeeName,
        'idFuncionario': employeeId,
        'total': total,
        'servicos': services,
      };
}
