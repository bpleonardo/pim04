import '../../models/agendamento.dart';
import '../api/barbearia_api.dart';

class AgendamentoRepository {
  final BarbeariaApi api = BarbeariaApi();
  Future<List<Agendamento>> listar() => api.agendamentos();
  Future<void> alterarStatus(String id, String status) =>
      api.status(id, status);
  // Agendamentos nunca são confirmados localmente: a API decide conflitos e disponibilidade.
}
