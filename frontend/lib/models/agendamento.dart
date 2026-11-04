class Agendamento {
  final String id, dataAgendamento, status, nomeCliente, nomeFuncionario;
  final double total;
  final String funcionarioId;
  final List<String> servicos;
  const Agendamento(
      {required this.id,
      required this.dataAgendamento,
      required this.status,
      required this.nomeCliente,
      required this.nomeFuncionario,
      required this.total,
      this.funcionarioId = '',
      this.servicos = const []});
  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
      id: j['id'].toString(),
      dataAgendamento: j['dataAgendamento'].toString(),
      status: j['status'] as String,
      nomeCliente: (j['cliente']?['nome'] ?? j['nomeCliente'] ?? '').toString(),
      nomeFuncionario:
          (j['funcionario']?['nome'] ?? j['nomeFuncionario'] ?? '').toString(),
      total: (j['total'] as num).toDouble(),
      funcionarioId: (j['funcionario']?['id'] ?? j['idFuncionario'] ?? '').toString(),
      servicos: [for (final s in (j['servicos'] as List? ?? []))
        s is Map ? s['nome'].toString() : s.toString()]);
}
