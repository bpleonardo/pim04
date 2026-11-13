import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';

class BarbershopApi {
  final ApiClient _client = ApiClient();
  Future<Map<String, dynamic>> login(String login, String password) async =>
      Map<String, dynamic>.from(await _client.request('POST', '/api/Login',
          body: {'login': login, 'senha': password}));
  Future<List<Service>> services() async =>
      (await _client.request('GET', '/api/Servicos') as List)
          .map((x) => Service.fromJson(Map<String, dynamic>.from(x)))
          .toList();
  Future<void> saveService(Service service, {required bool creating}) async {
    await _client.request(
      creating ? 'POST' : 'PUT',
      creating ? '/api/servicos' : '/api/servicos/${service.id}',
      body: {
        'nome': service.name,
        'descricao': service.description,
        'preco': service.price
      },
    );
  }

  Future<void> deleteService(String id) async {
    await _client.request('DELETE', '/api/servicos/$id');
  }

  Future<List<Employee>> employees() async =>
      (await _client.request('GET', '/api/Funcionarios') as List)
          .map((x) => Employee.fromJson(Map<String, dynamic>.from(x)))
          .toList();
  Future<List<Map<String, dynamic>>> timeSlots(DateTime selectedDate) async {
    final date =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    return (await _client.request('GET', '/api/Horarios?date=$date') as List)
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
  }

  Future<List<Appointment>> appointments({
    String? date,
    bool mine = false,
    String? bearerToken,
  }) async {
    final query = Uri(queryParameters: {
      if (date != null) 'date': date,
      if (mine) 'mine': 'true',
    }).query;
    final path =
        query.isEmpty ? '/api/agendamentos' : '/api/agendamentos?$query';
    final response =
        await _client.request('GET', path, bearerToken: bearerToken) as List;
    return response
        .map((item) => Appointment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createAppointment(
      {required String name,
      required String phone,
      required String employeeId,
      required DateTime scheduledAt,
      required List<String> services}) async {
    await _client.request('POST', '/api/agendamentos', body: {
      'nomeCliente': name,
      'telefoneCliente': phone,
      'idFuncionario': employeeId,
      'dataAgendamento': scheduledAt.toIso8601String(),
      'idServicos': services,
    });
  }

  Future<void> updateStatus(String id, String status,
      {String? bearerToken}) async {
    await _client.request('PATCH', '/api/agendamentos/$id',
        body: {'status': status}, bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> dashboard() async =>
      Map<String, dynamic>.from(await _client.request('GET', '/api/Dashboard'));
}
