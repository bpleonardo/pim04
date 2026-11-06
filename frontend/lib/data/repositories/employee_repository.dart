import 'package:barbearia_frontend/models/employee.dart';
import 'package:barbearia_frontend/data/api/barbershop_api.dart';

class EmployeeRepository {
  final BarbershopApi api = BarbershopApi();
  Future<List<Employee>> list() => api.employees();
}
