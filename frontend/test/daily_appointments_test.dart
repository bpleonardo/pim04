import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/auth/models/user.dart';
import 'package:barbearia_frontend/features/appointments/presentation/cortes_dia_screen.dart';
import 'package:barbearia_frontend/features/home/presentation/home_screen.dart';

Appointment appointment(String id, String status) => Appointment(
    id: id,
    scheduledAt: '2026-11-04T13:00:00Z',
    status: status,
    clientName: 'Cliente $id',
    employeeName: 'Ana',
    total: 35,
    employeeId: 'ana',
    services: const ['Corte']);

class FakeAgendaRepository extends AppointmentRepository {
  List<Appointment> items = [
    appointment('1', 'agendado'),
    appointment('2', 'concluido'),
    appointment('3', 'cancelado')
  ];
  int completionCalls = 0;
  bool failLoad = false;
  bool failCompletion = false;
  bool offline = false;
  String? queuedId;
  @override
  Future<DailyAgenda> loadToday() async {
    if (failLoad) throw Exception('Sem conexão');
    final id = queuedId;
    if (id != null && !offline) {
      items = [
        for (final item in items)
          item.id == id ? appointment(id, 'concluido') : item
      ];
      queuedId = null;
    }
    return DailyAgenda(items, offline: offline, completions: {
      if (queuedId case final String pendingId)
        pendingId: CompletionState.pending,
    });
  }

  @override
  Future<CompletionState> complete(String id) async {
    completionCalls++;
    if (failCompletion) throw Exception('Falha na API');
    if (offline) {
      queuedId = id;
      return CompletionState.pending;
    }
    items = [
      for (final a in items) a.id == id ? appointment(id, 'concluido') : a
    ];
    return CompletionState.sent;
  }
}

void main() {
  setUp(() {
    ApiClient.user =
        const User(id: 'ana', name: 'Ana Costa', login: 'ana.costa');
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    ApiClient.signOut();
  });

  testWidgets('Android e iOS só oferecem a agenda diária nas rotas internas',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      for (final route in [
        AppRouter.home,
        AppRouter.catalog,
        AppRouter.newAppointment,
        AppRouter.agenda,
        AppRouter.dashboard
      ]) {
        expect(
            (AppRouter.onGenerateRoute(RouteSettings(name: route))
                    as MaterialPageRoute<void>)
                .builder(context),
            isA<CortesDiaScreen>());
      }
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(
        (AppRouter.onGenerateRoute(const RouteSettings(name: AppRouter.home))
                as MaterialPageRoute<void>)
            .builder(context),
        isA<HomeScreen>());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'Mostra horário de São Paulo, serviço e só permite concluir pendente',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: CortesDiaScreen(repository: FakeAgendaRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(find.text('10:00'), findsNWidgets(3));
    expect(find.text('Concluir corte'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Novo agendamento'), findsNothing);
    expect(find.text('1 pendente • 1 concluído'), findsOneWidget);
  });

  testWidgets(
      'Cancelar confirmação não altera dados; confirmar recarrega e desabilita conclusão',
      (tester) async {
    final repo = FakeAgendaRepository();
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(repo.completionCalls, 0);
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar conclusão'));
    await tester.pumpAndSettle();
    expect(repo.completionCalls, 1);
    expect(find.text('Concluir corte'), findsNothing);
    expect(find.text('0 pendentes • 2 concluídos'), findsOneWidget);
    expect(find.text('Corte concluído com sucesso.'), findsOneWidget);
  });

  testWidgets('Falha ao concluir mantém pendente e permite tentar novamente',
      (tester) async {
    final repo = FakeAgendaRepository()..failCompletion = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar conclusão'));
    await tester.pumpAndSettle();
    expect(find.text('Concluir corte'), findsOneWidget);
    expect(find.textContaining('Não foi possível concluir'), findsOneWidget);
    expect(repo.items.first.status, 'agendado');
  });

  testWidgets('Tela vazia e erro de carga com nova tentativa', (tester) async {
    final repo = FakeAgendaRepository()..failLoad = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    repo.failLoad = false;
    repo.items = [];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum corte para você hoje.'), findsOneWidget);
  });

  testWidgets('Conclusão offline fica pendente até a sincronização',
      (tester) async {
    final repo = FakeAgendaRepository()..offline = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar conclusão'));
    await tester.pumpAndSettle();
    expect(find.text('Aguardando sincronização'), findsOneWidget);
    expect(find.text('Corte concluído com sucesso.'), findsNothing);
    expect(repo.queuedId, '1');
    expect(repo.items.first.status, 'agendado');

    repo.offline = false;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Aguardando sincronização'), findsNothing);
    expect(repo.queuedId, isNull);
    expect(repo.items.first.status, 'concluido');
  });

  test('Converte dados da API sem perder barbeiro nem serviços', () {
    final a = Appointment.fromJson({
      'id': '1',
      'dataAgendamento': '2026-11-04T13:00:00Z',
      'status': 'agendado',
      'total': 35,
      'cliente': {'nome': 'Cliente'},
      'funcionario': {'id': 'ana', 'nome': 'Ana'},
      'servicos': [
        {'nome': 'Corte'},
        {'nome': 'Barba'}
      ],
    });
    expect(a.employeeId, 'ana');
    expect(a.services, ['Corte', 'Barba']);
    expect(a.total, 35.0);
  });
}
