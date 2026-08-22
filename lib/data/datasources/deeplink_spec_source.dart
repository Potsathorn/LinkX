import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_config.dart';
import '../models/deeplink_entry.dart';
import 'spec_store.dart';

enum SpecOrigin {
  imported('Imported'),
  bundled('Bundled'),
  example('Example');

  const SpecOrigin(this.label);
  final String label;

  bool get isExample => this == SpecOrigin.example;
}

@immutable
class SpecLoadResult {
  const SpecLoadResult({
    required this.entries,
    required this.origin,
    required this.label,
    this.importedAt,
  });

  final List<DeeplinkEntry> entries;
  final SpecOrigin origin;
  final String label;
  final DateTime? importedAt;

  bool get isExample => origin.isExample;
}

class SpecFormatException implements Exception {
  const SpecFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeeplinkSpecSource {
  const DeeplinkSpecSource({
    this.assetPath = AppConfig.specAssetPath,
    this.exampleAssetPath = AppConfig.exampleSpecAssetPath,
    this.store = const SpecStore(),
  });

  final String assetPath;
  final String exampleAssetPath;
  final SpecStore store;

  Future<SpecLoadResult> load({AssetBundle? bundle}) async {
    final AssetBundle source = bundle ?? rootBundle;

    final StoredSpec? stored = await store.read();
    if (stored != null) {
      try {
        return SpecLoadResult(
          entries: parse(stored.raw),
          origin: SpecOrigin.imported,
          label: stored.label,
          importedAt: stored.importedAt,
        );
      } catch (_) {
        await store.clear();
      }
    }

    try {
      return SpecLoadResult(
        entries: parse(await source.loadString(assetPath)),
        origin: SpecOrigin.bundled,
        label: assetPath.split('/').last,
      );
    } catch (_) {
      return SpecLoadResult(
        entries: parse(await source.loadString(exampleAssetPath)),
        origin: SpecOrigin.example,
        label: exampleAssetPath.split('/').last,
      );
    }
  }

  List<DeeplinkEntry> parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const SpecFormatException('The file is not valid JSON.');
    }

    if (decoded is! Map || decoded['deeplinks'] is! List) {
      throw const SpecFormatException(
        'Expected an object with a "deeplinks" array at the top level.',
      );
    }

    final List<DeeplinkEntry> entries = (decoded['deeplinks'] as List<dynamic>)
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) =>
            DeeplinkEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((DeeplinkEntry e) => e.pathPattern.isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      throw const SpecFormatException(
        'No usable deeplinks found — every entry needs a path_pattern.',
      );
    }

    entries.sort((DeeplinkEntry a, DeeplinkEntry b) {
      final int byRank = a.rank.compareTo(b.rank);
      return byRank != 0
          ? byRank
          : a.destinationPage.compareTo(b.destinationPage);
    });
    return entries;
  }
}
