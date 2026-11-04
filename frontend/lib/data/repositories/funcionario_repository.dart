import '../../models/funcionario.dart';
import '../api/barbearia_api.dart';

class FuncionarioRepository {
  final BarbeariaApi api = BarbeariaApi();
  Future<List<Funcionario>> listar() => api.funcionarios();
}
