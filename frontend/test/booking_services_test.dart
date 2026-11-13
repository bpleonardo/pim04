import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agendamento_screen.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BookingApi extends BarbershopApi {
  List<String>? submittedServices;

  @override
  Future<List<Service>> services() async => const [
        Service(id: 'hair', name: 'Cabelo', price: 35),
        Service(id: 'hydration', name: 'Hidratação', price: 20),
        Service(id: 'beard', name: 'Barba', price: 25),
      ];

  @override
  Future<List<Employee>> employees() async =>
      const [Employee(id: 'ana', name: 'Ana')];

  @override
  Future<List<Map<String, dynamic>>> timeSlots(DateTime selectedDate) async => [
        {'available': true, 'slot': '10:00'}
      ];

  @override
  Future<void> createAppointment({
    required String name,
    required String phone,
    required String employeeId,
    required DateTime scheduledAt,
    required List<String> services,
    String? nonce,
  }) async {
    submittedServices = services;
  }
}

void main() {
  testWidgets('Envia todos e apenas os serviços selecionados', (tester) async {
    final api = BookingApi();
    await tester.pumpWidget(MaterialApp(home: AgendamentoScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Silva');
    await tester.enterText(find.byType(TextFormField).at(1), '5511999999999');
    await tester.tap(find.text('Barbeiro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10:00').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();
    expect(api.submittedServices, isNull);
    expect(find.text('Selecione pelo menos um serviço, o barbeiro e o horário'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cabelo'));
    await tester.tap(find.text('Hidratação'));
    await tester.tap(find.text('Barba'));
    await tester.pump();
    await tester.tap(find.text('Barba'));
    await tester.pump();
    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();

    expect(api.submittedServices, ['hair', 'hydration']);
  });
}
