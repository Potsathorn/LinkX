import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_config.dart';
import '../models/deeplink_entry.dart';

class SpecLoadResult {
  const SpecLoadResult({required this.entries, required this.isExample});

  final List<DeeplinkEntry> entries;
  final bool isExample;
}

class DeeplinkSpecSource {
  const DeeplinkSpecSource({
    this.assetPath = AppConfig.specAssetPath,
    this.exampleAssetPath = AppConfig.exampleSpecAssetPath,
  });

  final String assetPath;
  final String exampleAssetPath;

  Future<SpecLoadResult> load({AssetBundle? bundle}) async {
    final AssetBundle source = bundle ?? rootBundle;

    try {
      return SpecLoadResult(
        entries: parse(await source.loadString(assetPath)),
        isExample: false,
      );
    } catch (_) {
      return SpecLoadResult(
        entries: parse(await source.loadString(exampleAssetPath)),
        isExample: true,
      );
    }
  }

  List<DeeplinkEntry> parse(String raw) {
    final Map<String, dynamic> decoded =
        Map<String, dynamic>.from(jsonDecode(raw) as Map);

    final List<dynamic> deeplinks =
        decoded['deeplinks'] as List<dynamic>? ?? <dynamic>[];

    final List<DeeplinkEntry> entries = deeplinks
        .map((dynamic e) =>
            DeeplinkEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((DeeplinkEntry e) => e.pathPattern.isNotEmpty)
        .toList();

    entries.sort((DeeplinkEntry a, DeeplinkEntry b) {
      final int byRank = a.rank.compareTo(b.rank);
      return byRank != 0
          ? byRank
          : a.destinationPage.compareTo(b.destinationPage);
    });
    return entries;
  }
}
