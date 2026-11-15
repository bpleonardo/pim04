import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/features/employees/data/employee_repository.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/features/employees/presentation/employees_screen.dart';

class EmployeesRepository extends EmployeeRepository {
  List<Employee> employees = [];
  int listCalls = 0;
  final creations = <bool>[];
  final deleted = <String>[];
  @override
  Future<List<Employee>> list() async {
    listCalls++;
    return List.of(employees);
  }

  @override
  Future<void> save(Employee employee, {required bool creating}) async {
    creations.add(creating);
    employees = [
      Employee(
          id: creating ? 'employee-1' : employee.id,
          name: employee.name,
          phone: employee.phone,
          cpf: employee.cpf,
          email: employee.email,
          address: employee.address)
    ];
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    employees = employees.where((employee) => employee.id != id).toList();
  }
}

void main() {
  testWidgets(
      'Cadastro, edição e exclusão recarregam funcionários sem retornar Future no setState',
      (tester) async {
    final repository = EmployeesRepository();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EmployeesScreen(repository: repository))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo funcionário'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Profissional de Teste');
    await tester.enterText(find.byType(TextFormField).at(1), '5511000000000');
    await tester.enterText(
        find.byType(TextFormField).at(4), 'Endereço de teste');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Profissional de Teste'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Profissional Editado');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Profissional Editado'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum funcionário cadastrado'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
    expect(repository.creations, [true, false]);
    expect(repository.deleted, ['employee-1']);
    expect(repository.listCalls, 4);
  });
}
