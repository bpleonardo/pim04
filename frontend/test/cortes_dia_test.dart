import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/core/rotas.dart';
import 'package:barbearia_frontend/data/api/api_client.dart';
import 'package:barbearia_frontend/data/repositories/agendamento_repository.dart';
import 'package:barbearia_frontend/models/agendamento.dart';
import 'package:barbearia_frontend/models/usuario.dart';
import 'package:barbearia_frontend/ui/telas/cortes_dia_screen.dart';
import 'package:barbearia_frontend/ui/telas/home_screen.dart';

Agendamento corte(String id, String status) => Agendamento(
    id: id,
    dataAgendamento: '2026-11-04T13:00:00Z',
    status: status,
    nomeCliente: 'Cliente $id',
    nomeFuncionario: 'Ana',
    total: 35,
    funcionarioId: 'ana',
    servicos: const ['Corte']);

class AgendaTeste extends AgendamentoRepository {
  List<Agendamento> itens = [
    corte('1', 'agendado'),
    corte('2', 'concluido'),
    corte('3', 'cancelado')
  ];
  int conclusoes = 0;
  bool falharCarga = false;
  bool falharConclusao = false;
  @override
  Future<List<Agendamento>> meusCortesHoje() async {
    if (falharCarga) throw Exception('Sem conexão');
    return itens;
  }

  @override
  Future<void> concluirMeuCorte(String id) async {
    conclusoes++;
    if (falharConclusao) throw Exception('Falha na API');
    itens = [for (final a in itens) a.id == id ? corte(id, 'concluido') : a];
  }
}

void main() {
  setUp(() {
    ApiClient.usuario =
        const Usuario(id: 'ana', nome: 'Ana Costa', login: 'ana.costa');
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    ApiClient.sair();
  });

  testWidgets('Android e iOS só oferecem a agenda diária nas rotas internas',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);
    for (final plataforma in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = plataforma;
      for (final rota in [
        Rotas.home,
        Rotas.catalogo,
        Rotas.novo,
        Rotas.agenda,
        Rotas.dashboard
      ]) {
        expect(Rotas.routes[rota]!(context), isA<CortesDiaScreen>());
      }
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(Rotas.routes[Rotas.home]!(context), isA<HomeScreen>());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'Mostra horário de São Paulo, serviço e só permite concluir pendente',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: CortesDiaScreen(repository: AgendaTeste())));
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
    final repo = AgendaTeste();
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(repo.conclusoes, 0);
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar conclusão'));
    await tester.pumpAndSettle();
    expect(repo.conclusoes, 1);
    expect(find.text('Concluir corte'), findsNothing);
    expect(find.text('0 pendentes • 2 concluídos'), findsOneWidget);
    expect(find.text('Corte concluído com sucesso.'), findsOneWidget);
  });

  testWidgets('Falha ao concluir mantém pendente e permite tentar novamente',
      (tester) async {
    final repo = AgendaTeste()..falharConclusao = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir corte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar conclusão'));
    await tester.pumpAndSettle();
    expect(find.text('Concluir corte'), findsOneWidget);
    expect(find.textContaining('Não foi possível concluir'), findsOneWidget);
    expect(repo.itens.first.status, 'agendado');
  });

  testWidgets('Tela vazia e erro de carga com nova tentativa', (tester) async {
    final repo = AgendaTeste()..falharCarga = true;
    await tester
        .pumpWidget(MaterialApp(home: CortesDiaScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    repo.falharCarga = false;
    repo.itens = [];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum corte para você hoje.'), findsOneWidget);
  });

  test('Converte dados da API sem perder barbeiro nem serviços', () {
    final a = Agendamento.fromJson({
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
    expect(a.funcionarioId, 'ana');
    expect(a.servicos, ['Corte', 'Barba']);
    expect(a.total, 35.0);
  });
}
