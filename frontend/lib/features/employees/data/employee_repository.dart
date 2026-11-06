import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';

class EmployeeRepository {
  final BarbershopApi api = BarbershopApi();
  Future<List<Employee>> list() => api.employees();
}
