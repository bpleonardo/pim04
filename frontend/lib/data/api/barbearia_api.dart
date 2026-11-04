import '../../models/servico.dart';
import '../../models/funcionario.dart';
import '../../models/agendamento.dart';
import 'api_client.dart';

class BarbeariaApi {
  final ApiClient _client = ApiClient();
  Future<Map<String, dynamic>> login(String login, String senha) async =>
      Map<String, dynamic>.from(await _client.request('POST', '/api/Login',
          body: {'login': login, 'senha': senha}));
  Future<List<Servico>> servicos() async =>
      (await _client.request('GET', '/api/Servicos') as List)
          .map((x) => Servico.fromJson(Map<String, dynamic>.from(x)))
          .toList();
  Future<List<Funcionario>> funcionarios() async =>
      (await _client.request('GET', '/api/Funcionarios') as List)
          .map((x) => Funcionario.fromJson(Map<String, dynamic>.from(x)))
          .toList();
  Future<List<Map<String, dynamic>>> horarios(DateTime dia) async {
    final date =
        '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
    return (await _client.request('GET', '/api/Horarios?date=$date') as List)
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
  }

  Future<List<Agendamento>> agendamentos() async =>
      (await _client.request('GET', '/api/Agendamentos') as List)
          .map((x) => Agendamento.fromJson(Map<String, dynamic>.from(x)))
          .toList();
  Future<void> criar(
      {required String nome,
      required String telefone,
      required String funcionarioId,
      required DateTime data,
      required List<String> servicos}) async {
    await _client.request('POST', '/api/Agendamentos', body: {
      'nomeCliente': nome,
      'telefoneCliente': telefone,
      'idFuncionario': funcionarioId,
      'dataAgendamento': data.toIso8601String(),
      'idServicos': servicos,
    });
  }

  Future<void> status(String id, String status) async => _client
      .request('PATCH', '/api/Agendamentos/$id', body: {'status': status});
  Future<Map<String, dynamic>> dashboard() async =>
      Map<String, dynamic>.from(await _client.request('GET', '/api/Dashboard'));
}
