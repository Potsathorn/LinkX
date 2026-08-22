import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

@immutable
class StoredSpec {
  const StoredSpec({
    required this.raw,
    required this.label,
    required this.importedAt,
  });

  final String raw;
  final String label;
  final DateTime importedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'raw': raw,
        'label': label,
        'importedAt': importedAt.toIso8601String(),
      };

  factory StoredSpec.fromJson(Map<String, dynamic> json) => StoredSpec(
        raw: json['raw'] as String? ?? '',
        label: json['label'] as String? ?? 'Imported spec',
        importedAt: DateTime.tryParse(json['importedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class SpecStore {
  const SpecStore({this.fileName = 'imported_spec.json'});

  final String fileName;

  Future<File> _file() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<StoredSpec?> read() async {
    try {
      final File file = await _file();
      if (!await file.exists()) return null;

      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map);
      final StoredSpec stored = StoredSpec.fromJson(decoded);
      return stored.raw.isEmpty ? null : stored;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(StoredSpec spec) async {
    final File file = await _file();
    await file.writeAsString(jsonEncode(spec.toJson()), flush: true);
  }

  Future<void> clear() async {
    try {
      final File file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {
      return;
    }
  }
}
