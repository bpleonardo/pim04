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
    final result = await showDialog<Employee>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(existing == null ? 'Novo funcionário' : 'Editar funcionário'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field('Nome', name, (value) => name = value, min: 3),
              _field('Telefone', phone, (value) => phone = value, min: 13),
              _field('CPF', cpf, (value) => cpf = value, required: false),
              _field('E-mail', email, (value) => email = value,
                  required: false),
              _field('Endereço', address, (value) => address = value, min: 5),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      await _change(() => _repository.save(result, creating: existing == null));
    }
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged,
          {int min = 1, bool required = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => onChanged(value.trim()),
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
      if (mounted) setState(() => _employees = _repository.list());
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
                      .map((employee) => Card(
                            child: ListTile(
                              title: Text(employee.name),
                              subtitle: employee.isDeleted
                                  ? const Text('Excluído')
                                  : Text(
                                      employee.email ?? employee.phone ?? ''),
                              leading: employee.isDeleted
                                  ? const Icon(Icons.person_off_outlined)
                                  : const Icon(Icons.person_outline),
                              trailing: employee.isDeleted
                                  ? null
                                  : Wrap(children: [
                                      IconButton(
                                        tooltip: 'Editar',
                                        onPressed: _busy
                                            ? null
                                            : () => _edit(employee),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Excluir',
                                        onPressed: _busy
                                            ? null
                                            : () => _delete(employee),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ]),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      );
}
