import 'package:flutter/material.dart';

import 'package:barbearia_frontend/app/layout/desktop_layout.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/config/api_config.dart';
import 'package:barbearia_frontend/core/config/api_config_dialog.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  late final TextEditingController controller;
  bool busy = false;
  bool editing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void close() {
    if (widget.embedded) {
      DesktopLayout.of(context).open(AppRouter.home);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final errorMessage = await saveApiConfiguration(controller.text);
    if (!mounted) return;
    if (errorMessage == null) {
      setState(() {
        editing = false;
        busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL da API atualizada.')),
      );
    } else {
      setState(() {
        busy = false;
        error = errorMessage;
      });
    }
  }

  void cancelEditing() {
    if (!editing || busy) return;
    setState(() {
      controller.text = ApiConfig.baseUrl;
      editing = false;
      error = null;
    });
  }

  Widget buildContent() => Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 720,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'API',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (editing)
                TextField(
                  controller: controller,
                  enabled: !busy,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'URL da API',
                    hintText: 'https://servidor.exemplo.com',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => setState(() {
                    editing = true;
                    error = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(controller.text)),
                      const Icon(Icons.edit_outlined),
                    ],
                  ),
                ),
              if (busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Verificando conexão com o servidor...'),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: busy || !editing ? null : cancelEditing,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: busy || !editing ? null : save,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return buildContent();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: busy ? null : close,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: buildContent(),
    );
  }
}
