import 'package:flutter/material.dart';
import 'package:barbearia_frontend/features/employees/data/employee_repository.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, this.embedded = false, this.repository});
  final bool embedded;
  final EmployeeRepository? repository;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late final _repository = widget.repository ?? EmployeeRepository();
  late Future<List<Employee>> _employees = _repository.list();
  bool _busy = false;

  Future<void> _edit([Employee? existing]) async {
    final form = GlobalKey<FormState>();
    var name = existing?.name ?? '';
    var phone = existing?.phone ?? '';
    var cpf = existing?.cpf ?? '';
    var email = existing?.email ?? '';
    var address = existing?.address ?? '';
    var login = '';
    var initialPassword = '';
    var credentialsStep = false;
    final result = await showDialog<Employee>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
                title: Text(existing == null
                    ? (credentialsStep
                        ? 'Dados de acesso — 2 de 2'
                        : 'Novo funcionário — 1 de 2')
                    : 'Editar funcionário'),
                content: SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (!credentialsStep) ...[
                        _field('Nome', name, (value) => name = value, min: 3),
                        _field('Telefone', phone, (value) => phone = value,
                            min: 13),
                        _field('CPF', cpf, (value) => cpf = value,
                            required: false),
                        _field('E-mail', email, (value) => email = value,
                            required: false),
                        _field('Endereço', address, (value) => address = value,
                            min: 5),
                      ] else ...[
                        const Text(
                            'O funcionário deverá trocar a senha inicial no primeiro acesso.'),
                        const SizedBox(height: 16),
                        _field('Login', login, (value) => login = value,
                            min: 3),
                        _field('Senha inicial', initialPassword,
                            (value) => initialPassword = value,
                            min: 6, password: true),
                      ],
                    ]),
                  ),
                ),
                actions: [
                  if (credentialsStep)
                    TextButton(
                        onPressed: () =>
                            updateDialog(() => credentialsStep = false),
                        child: const Text('Voltar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  FilledButton(
                    onPressed: () {
                      if (!form.currentState!.validate()) return;
                      if (existing == null && !credentialsStep) {
                        updateDialog(() => credentialsStep = true);
                        return;
                      }
                      Navigator.pop(
                          context,
                          Employee(
                            id: existing?.id ?? '',
                            name: name,
                            phone: phone,
                            cpf: cpf.isEmpty ? null : cpf,
                            email: email.isEmpty ? null : email,
                            address: address,
                          ));
                    },
                    child: Text(existing == null && !credentialsStep
                        ? 'Continuar'
                        : 'Salvar'),
                  ),
                ],
              )),
    );
    if (result != null && mounted) {
      await _change(() => _repository.save(result,
          creating: existing == null,
          login: existing == null ? login : null,
          initialPassword: existing == null ? initialPassword : null));
    }
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged,
          {int min = 1, bool required = true, bool password = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey(label),
          initialValue: value,
          obscureText: password,
          enableSuggestions: !password,
          autocorrect: !password,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => onChanged(password ? value : value.trim()),
          validator: (value) => !required && (value?.isEmpty ?? true)
              ? null
              : (value == null || value.length < min
                  ? 'Informe um valor válido.'
                  : null),
        ),
      );

  Future<void> _delete(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir funcionário?'),
        content: Text('Deseja excluir “${employee.name}”?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _change(() => _repository.delete(employee.id));
    }
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      final employees = _repository.list();
      setState(() {
        _employees = employees;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Novo funcionário'),
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: FutureBuilder<List<Employee>>(
              future: _employees,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return snapshot.hasError
                      ? Center(child: Text('Erro: ${snapshot.error}'))
                      : const Center(child: CircularProgressIndicator());
                }
                final employees = snapshot.data!;
                if (employees.isEmpty) {
                  return const Center(
                      child: Text('Nenhum funcionário cadastrado'));
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: employees
                      .map((employee) =>
                          LayoutBuilder(builder: (context, constraints) {
                            final compact = constraints.maxWidth < 560;
                            final actions =
                                Wrap(alignment: WrapAlignment.end, children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: _busy ? null : () => _edit(employee),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Excluir',
                                onPressed:
                                    _busy ? null : () => _delete(employee),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ]);
                            final details = ListTile(
                              title: Text(employee.name),
                              subtitle: employee.isDeleted
                                  ? const Text('Excluído')
                                  : Text(
                                      employee.email ?? employee.phone ?? ''),
                              leading: employee.isDeleted
                                  ? const Icon(Icons.person_off_outlined)
                                  : const Icon(Icons.person_outline),
                              trailing: employee.isDeleted || compact
                                  ? null
                                  : actions,
                            );
                            return Card(
                                child: compact && !employee.isDeleted
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                            details,
                                            Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        8, 0, 8, 8),
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: actions)),
                                          ])
                                    : details);
                          }))
                      .toList(),
                );
              },
            ),
          ),
        ],
      );
}
