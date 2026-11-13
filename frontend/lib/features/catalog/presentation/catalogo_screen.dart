import 'package:flutter/material.dart';
import 'package:barbearia_frontend/features/catalog/data/service_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _repository = ServiceRepository();
  late var _services = _repository.list();
  var _busy = false;

  Future<void> _edit([Service? existing]) async {
    final form = GlobalKey<FormState>();
    var name = existing?.name ?? '';
    var description = existing?.description ?? '';
    var price = existing?.price.toStringAsFixed(2).replaceAll('.', ',') ?? '';
    double? parsePrice(String value) =>
        double.tryParse(value.trim().replaceAll(',', '.'));

    final result = await showDialog<Service>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Novo serviço' : 'Editar serviço'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  onChanged: (value) => name = value.trim(),
                  validator: (value) => name.length < 3
                      ? 'Informe pelo menos 3 caracteres.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: description,
                  decoration:
                      const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 3,
                  onChanged: (value) => description = value.trim(),
                  validator: (value) =>
                      description.isNotEmpty && description.length < 5
                          ? 'Informe pelo menos 5 caracteres.'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: price,
                  decoration: const InputDecoration(
                      labelText: 'Preço', prefixText: 'R\$ '),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => price = value,
                  validator: (value) {
                    final amount = parsePrice(price);
                    if (amount == null ||
                        !amount.isFinite ||
                        amount < 0.01 ||
                        amount > 9999.99) {
                      return 'Informe um preço entre R\$ 0,01 e R\$ 9.999,99.';
                    }
                    return null;
                  },
                ),
              ],
            ),
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
                  Service(
                    id: existing?.id ?? '',
                    name: name,
                    description: description.isEmpty ? null : description,
                    price: double.parse(parsePrice(price)!.toStringAsFixed(2)),
                  ));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await _change(() => _repository.save(result, creating: existing == null));
  }

  Future<void> _delete(Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir serviço?'),
        content: Text('Deseja excluir “${service.name}”?'),
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
    if (confirmed != true || !mounted) return;
    await _change(() => _repository.delete(service.id));
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      final services = _repository.list();
      setState(() {
        _services = services;
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

  Widget _content() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Novo serviço'),
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: FutureBuilder<List<Service>>(
              future: _services,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final services = snapshot.data!;
                if (services.isEmpty) {
                  return const Center(child: Text('Nenhum serviço cadastrado'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final price =
                        service.price.toStringAsFixed(2).replaceAll('.', ',');
                    return Card(
                      child: ListTile(
                        title: Text(service.name),
                        subtitle: Text([
                          if (service.description case final String description)
                            description,
                          'R\$ $price',
                          if (!service.enabled) 'Desabilitado',
                        ].join('\n')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _busy ? null : () => _edit(service),
                              tooltip: 'Editar ${service.name}',
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: _busy
                                  ? null
                                  : () => _change(() => _repository.setEnabled(
                                      service, !service.enabled)),
                              tooltip: service.enabled
                                  ? 'Desabilitar serviço'
                                  : 'Reativar serviço',
                              icon: Icon(service.enabled
                                  ? Icons.block
                                  : Icons.check_circle_outline),
                            ),
                            IconButton(
                              onPressed: _busy || service.linked
                                  ? null
                                  : () => _delete(service),
                              tooltip: service.linked
                                  ? 'Serviço vinculado a agendamentos'
                                  : 'Excluir ${service.name}',
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _content()
      : Scaffold(
          appBar: AppBar(title: const Text('Serviços')), body: _content());
}
