import 'package:flutter/material.dart';

import 'package:barbearia_frontend/core/config/api_config.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';

Future<void> showApiConfigDialog(BuildContext context) async {
  if (AppPlatform.web) return;
  final controller = TextEditingController(text: ApiConfig.baseUrl);
  var busy = false;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Configurar API'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                enabled: !busy,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'URL da API',
                  hintText: 'https://servidor.exemplo.com',
                  errorText: error,
                ),
              ),
              if (busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Verificando conexão com o servidor...'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final errorMessage =
                        await saveApiConfiguration(controller.text);
                    if (errorMessage == null) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('URL da API atualizada.')),
                        );
                      }
                    } else {
                      setState(() {
                        error = errorMessage;
                        busy = false;
                      });
                    }
                  },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}

Future<String?> saveApiConfiguration(String value) async {
  try {
    await ApiConfig.validateConnection(value);
    await ApiConfig.save(value);
    return null;
  } on FormatException catch (exception) {
    return exception.message;
  } catch (exception) {
    return _messageFor(exception);
  }
}

String _messageFor(Object error) {
  final text = '$error';
  if (text.contains('TimeoutException')) {
    return 'A API não respondeu dentro do tempo esperado.';
  }
  if (text.contains('SocketException') || text.contains('Falha')) {
    return 'Não foi possível conectar à API.';
  }
  return text;
}
