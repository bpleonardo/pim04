import 'dart:async';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/auth/models/user.dart';
import 'package:barbearia_frontend/features/appointments/presentation/cortes_dia_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agenda_screen.dart';

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
  final requestedDates = <DateTime>[];

  @override
  Future<List<Appointment>> list({DateTime? date}) async {
    if (date != null) requestedDates.add(date);
    return items;
  }

  List<Appointment> items = [
    appointment('1', 'agendado'),
    appointment('2', 'concluido'),
    appointment('3', 'cancelado')
  ];
  int completionCalls = 0;
  Completer<DailyAgenda>? delayedLoad;
  bool failLoad = false;
  bool failCompletion = false;
  bool offline = false;
  bool rejectQueuedCompletion = false;
  String? rejectedId;
  String? queuedId;
  @override
  Future<DailyAgenda> loadDay(DateTime date) async {
    if (delayedLoad != null) return delayedLoad!.future;
    if (failLoad) throw Exception('Sem conexão');
    final id = queuedId;
    if (id != null && !offline) {
      items = [
        for (final item in items)
          item.id == id
              ? appointment(
                  id, rejectQueuedCompletion ? 'cancelado' : 'concluido')
              : item
      ];
      if (rejectQueuedCompletion) rejectedId = id;
      queuedId = null;
    }
    return DailyAgenda(items, offline: offline, completions: {
      if (queuedId case final String pendingId)
        pendingId: CompletionState.pending,
      if (rejectedId case final String id) id: CompletionState.rejected,
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

  testWidgets('Controles mobile reativam após carregamento assíncrono',
      (tester) async {
    final pending = Completer<DailyAgenda>();
    final repo = FakeAgendaRepository()..delayedLoad = pending;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Selecionar data'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<FloatingActionButton>(find.byWidgetPredicate((widget) =>
                widget is FloatingActionButton &&
                widget.tooltip == 'Novo agendamento'))
            .onPressed,
        isNull);
    pending.complete(const DailyAgenda([]));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Selecionar data'))
            .onPressed,
        isNotNull);
    expect(
        tester
            .widget<FloatingActionButton>(find.byWidgetPredicate((widget) =>
                widget is FloatingActionButton &&
                widget.tooltip == 'Novo agendamento'))
            .onPressed,
        isNotNull);
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is IconButton && widget.tooltip == 'Selecionar data'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('Android e iOS usam a agenda do barbeiro nas rotas de consulta',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      for (final route in [
        AppRouter.home,
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
        isA<AgendaScreen>());
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
    expect(
        find.byWidgetPredicate((widget) =>
            widget is FloatingActionButton &&
            widget.tooltip == 'Novo agendamento'),
        findsOneWidget);
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
    expect(find.text('Nenhum agendamento para esta data.'), findsOneWidget);
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

  testWidgets('Reconecta sem fila e atualiza a agenda salva', (tester) async {
    final repo = FakeAgendaRepository()..offline = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Sem conexão. Mostrando a agenda salva.'), findsOneWidget);

    repo.offline = false;
    repo.items = [appointment('1', 'concluido')];
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Sem conexão. Mostrando a agenda salva.'), findsNothing);
    expect(find.text('Concluído'), findsOneWidget);
  });

  testWidgets('Cancelamento no servidor prevalece sobre conclusão offline',
      (tester) async {
    final repo = FakeAgendaRepository()
      ..offline = true
      ..queuedId = '1'
      ..rejectQueuedCompletion = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();

    repo.offline = false;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Cancelado · Conclusão não sincronizada'), findsOneWidget);
    expect(find.text('Aguardando sincronização'), findsNothing);
    expect(find.text('Concluir corte'), findsNothing);
  });

  testWidgets('Agenda larga mostra menu lateral e consulta a data escolhida',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeAgendaRepository();
    await tester.pumpWidget(MaterialApp(home: AgendaScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('N&E'), findsOneWidget);
    expect(find.text('Agendamentos'), findsOneWidget);
    expect(find.text('Selecionar'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is FloatingActionButton &&
            widget.tooltip == 'Novo agendamento'),
        findsOneWidget);
    expect(find.text('10:00'), findsNWidgets(3));
    final day = repo.requestedDates.single;
    await tester.tap(find.byTooltip('Próximo dia'));
    await tester.pumpAndSettle();
    expect(
        repo.requestedDates.last, DateTime(day.year, day.month, day.day + 1));
    expect(find.text(shopDateLabel(repo.requestedDates.last)), findsOneWidget);
    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(find.text(shopDateLabel(day)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Agenda estreita oferece menu compacto e botão de cadastro',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: AgendaScreen(repository: FakeAgendaRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agendamentos'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is FloatingActionButton &&
            widget.tooltip == 'Novo agendamento'),
        findsOneWidget);
    expect(find.text('N&E'), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('N&E'), findsOneWidget);
    expect(find.text('Serviços'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
