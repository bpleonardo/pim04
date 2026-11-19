import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> readDesktopApiUrl() async {
  final file = await _configFile();
  try {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return json is Map ? json['apiUrl'] as String? : null;
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

Future<void> writeDesktopApiUrl(String value) async {
  final file = await _configFile();
  await file.writeAsString(jsonEncode({'apiUrl': value}));
}

Future<File> _configFile() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return File('${directory.path}${Platform.pathSeparator}config.json');
}
