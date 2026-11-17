import 'package:barbearia_frontend/features/catalog/data/service_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalogo_screen.dart';
import 'package:barbearia_frontend/features/employees/data/employee_repository.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/features/employees/presentation/employees_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/app/layout/desktop_layout.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agenda_screen.dart';

class ResponsiveAgenda extends AppointmentRepository {
  int calls = 0;
  @override
  Future<List<Appointment>> list({DateTime? date}) async {
    calls++;
    return [
      const Appointment(
          id: 'test',
          clientName: 'Cliente Teste',
          employeeName: 'Barbeiro',
          scheduledAt: '2026-11-17T15:00:00Z',
          status: 'cancelado',
          services: ['Barba', 'Corte de cabelo'],
          total: 85)
    ];
  }
}

class ResponsiveServices extends ServiceRepository {
  @override
  Future<List<Service>> list() async => const [
        Service(
            id: 'hair',
            name: 'Hidratação capilar',
            description: 'Tratamento e cuidado capilar',
            price: 80)
      ];
}

class ResponsiveEmployees extends EmployeeRepository {
  @override
  Future<List<Employee>> list() async => const [
        Employee(
            id: 'employee',
            name: 'Profissional de Teste',
            email: 'profissional@empresa.com')
      ];
}

void main() {
  testWidgets(
      'Painel reserva a largura para a agenda em telas de celular e mantém a data ao redimensionar',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 924);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ResponsiveAgenda();
    await tester.pumpWidget(MaterialApp(
        home: DesktopLayout(
            initialRoute: AppRouter.home,
            initialContent:
                AgendaScreen(embedded: true, repository: repository))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Próximo dia'));
    await tester.pumpAndSettle();
    final today = shopTime(DateTime.now());
    final label =
        shopDateLabel(DateTime(today.year, today.month, today.day + 1));
    expect(repository.calls, 2);
    for (final width in [412.0, 320.0, 600.0, 760.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 924);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      final dateSize = tester.getSize(find.text(label));
      expect(dateSize.height, lessThan(65));
      expect(dateSize.width, greaterThan(140));
      expect(find.text('Cliente Teste'), findsOneWidget);
      expect(repository.calls, 2);
      expect(find.byType(AppBar), width < 760 ? findsOneWidget : findsNothing);
      if (width < 760) {
        expect(find.text('N&E'), findsNothing);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        expect(find.text('Funcionários'), findsOneWidget);
        expect(find.text('Disponibilidade'), findsOneWidget);
        await tester.tap(find.text('Agendamentos').last);
        await tester.pumpAndSettle();
        expect(find.text('N&E'), findsNothing);
      }
      expect(tester.takeException(), isNull, reason: 'Largura: $width');
    }
  });

  testWidgets(
      'Formulário conserva a digitação ao alternar entre menu lateral e compacto',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 924);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        home: DesktopLayout(
            initialRoute: AppRouter.newAppointment,
            initialContent: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: TextField(
                    decoration:
                        InputDecoration(labelText: 'Nome do cliente'))))));
    await tester.enterText(find.byType(TextField), 'Cliente preservado');
    for (final width in [412.0, 320.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 924);
      await tester.pumpAndSettle();
      expect(find.text('Cliente preservado'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Largura: $width');
    }
  });
  testWidgets(
      'Cartões mantêm informações legíveis e ações abaixo em telas estreitas',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 412.0]) {
      tester.view.physicalSize = Size(width, 924);
      for (final page in [
        (
          AppRouter.catalog,
          CatalogoScreen(embedded: true, repository: ResponsiveServices()),
          'Hidratação capilar',
          'Editar Hidratação capilar'
        ),
        (
          AppRouter.employees,
          EmployeesScreen(embedded: true, repository: ResponsiveEmployees()),
          'Profissional de Teste',
          'Editar'
        ),
      ]) {
        await tester.pumpWidget(MaterialApp(
            home: DesktopLayout(
                key: ValueKey((width, page.$1)),
                initialRoute: page.$1,
                initialContent: page.$2)));
        await tester.pumpAndSettle();
        final title = find.text(page.$3);
        final edit = find.byTooltip(page.$4);
        expect(tester.getSize(title).width, greaterThan(180));
        expect(tester.getRect(edit).top,
            greaterThan(tester.getRect(title).bottom));
        expect(tester.takeException(), isNull,
            reason: 'Largura: $width, tela: ${page.$1}');
      }
    }
  });
}
