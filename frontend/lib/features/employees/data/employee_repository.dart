import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';

class EmployeeRepository {
  final BarbershopApi api = BarbershopApi();
  Future<List<Employee>> list() => api.employees();
  Future<void> save(Employee employee, {required bool creating}) =>
      api.saveEmployee(employee, creating: creating);
  Future<void> delete(String id) => api.deleteEmployee(id);
}
