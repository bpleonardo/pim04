import 'package:flutter/material.dart';
import '../../core/rotas.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../models/agendamento.dart';

class CortesDiaScreen extends StatefulWidget {
  const CortesDiaScreen({super.key, this.repository});
  final AgendamentoRepository? repository;

  @override
  State<CortesDiaScreen> createState() => _CortesDiaScreenState();
}

class _CortesDiaScreenState extends State<CortesDiaScreen>
    with WidgetsBindingObserver {
  late final AgendamentoRepository repo;
  late Future<List<Agendamento>> future;
  String? concluindo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    repo = widget.repository ?? AgendamentoRepository();
    future = repo.meusCortesHoje();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) atualizar();
  }

  Future<void> atualizar() async {
    setState(() => future = repo.meusCortesHoje());
    try {
      await future;
    } catch (_) {
      // O FutureBuilder apresenta a falha e oferece nova tentativa.
    }
  }

  Future<void> concluir(Agendamento corte) async {
    if (concluindo != null) return;
    setState(() => concluindo = corte.id);
    try {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Concluir corte?'),
          content: Text('Confirmar que o atendimento de ${corte.nomeCliente} foi concluído?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Voltar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar conclusão')),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
      await repo.concluirMeuCorte(corte.id);
      if (!mounted) return;
      setState(() => future = repo.meusCortesHoje());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corte concluído com sucesso.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível concluir o corte. Atualize a lista e tente novamente.'),
        ));
      }
    } finally {
      if (mounted) setState(() => concluindo = null);
    }
  }

  // A agenda da API usa America/Sao_Paulo (UTC-3 nas datas atuais).
  DateTime horarioBarbearia(DateTime data) =>
      data.toUtc().subtract(const Duration(hours: 3));

  String hora(Agendamento corte) {
    final data = DateTime.tryParse(corte.dataAgendamento);
    if (data == null) return 'Horário não informado';
    final local = horarioBarbearia(data);
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String get dataHoje {
    final hoje = horarioBarbearia(DateTime.now());
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return '${dias[hoje.weekday - 1]}, ${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
  }

  Widget cartao(Agendamento corte) {
    final pendente = corte.status == 'agendado';
    final status = switch (corte.status) {
      'concluido' => 'Concluído',
      'cancelado' => 'Cancelado',
      'agendado' => 'Agendado',
      _ => corte.status,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF303030)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(corte.nomeCliente,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            Text(hora(corte), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(corte.servicos.isEmpty ? 'Atendimento' : corte.servicos.join(' • ')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('R\$ ${corte.total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(status),
          ]),
          if (pendente) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: concluindo != null ? null : () => concluir(corte),
              icon: const Icon(Icons.check),
              label: Text(concluindo == corte.id ? 'Aguarde...' : 'Concluir corte'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Cortes de hoje'),
      actions: [
        IconButton(tooltip: 'Atualizar', onPressed: atualizar, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Sair', onPressed: () {
          ApiClient.sair();
          Navigator.pushNamedAndRemoveUntil(context, Rotas.login, (_) => false);
        }, icon: const Icon(Icons.logout)),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: FutureBuilder<List<Agendamento>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(padding: const EdgeInsets.all(24), child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 40),
                const SizedBox(height: 16),
                const Text('Não foi possível carregar os cortes de hoje. Confira a conexão. Se a sessão expirou, saia e entre novamente.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: atualizar, child: const Text('Tentar novamente')),
              ],
            ));
          }
          final cortes = [...snapshot.data ?? <Agendamento>[]]
            ..sort((a, b) => a.dataAgendamento.compareTo(b.dataAgendamento));
          final pendentes = cortes.where((a) => a.status == 'agendado').length;
          final concluidos = cortes.where((a) => a.status == 'concluido').length;
          return RefreshIndicator(
            onRefresh: atualizar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(ApiClient.usuario?.nome ?? 'Barbeiro',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(dataHoje),
                const SizedBox(height: 12),
                Text('$pendentes pendentes • $concluidos concluídos'),
                const SizedBox(height: 22),
                if (cortes.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(children: [
                      Icon(Icons.event_available_outlined, size: 48),
                      SizedBox(height: 16),
                      Text('Nenhum corte para você hoje.', textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      Text('Puxe para baixo para atualizar.', textAlign: TextAlign.center),
                    ])),
                for (final corte in cortes) cartao(corte),
              ],
            ),
          );
        },
      ),
    ))),
  );
}
