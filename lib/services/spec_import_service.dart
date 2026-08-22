import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/action_result.dart';
import '../data/datasources/deeplink_spec_source.dart';
import '../data/datasources/spec_store.dart';
import '../data/models/deeplink_entry.dart';

@immutable
class SpecImportOutcome {
  const SpecImportOutcome({required this.result, this.loaded});

  final ActionResult result;
  final SpecLoadResult? loaded;

  bool get isSuccess => loaded != null;
}

class SpecImportService {
  const SpecImportService({
    this.source = const DeeplinkSpecSource(),
    this.store = const SpecStore(),
  });

  final DeeplinkSpecSource source;
  final SpecStore store;

  Future<SpecImportOutcome> pickAndImport() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        dialogTitle: 'Choose a deeplink spec',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
    } catch (e) {
      return SpecImportOutcome(
        result: ActionResult.error('Could not open the file picker: $e'),
      );
    }

    if (picked.isEmpty) {
      return const SpecImportOutcome(result: ActionResult.none());
    }

    final PlatformFile file = picked.first;
    final String raw;
    try {
      raw = utf8.decode(await file.readAsBytes());
    } catch (e) {
      return SpecImportOutcome(
        result: ActionResult.error('Could not read "${file.name}": $e'),
      );
    }

    return importRaw(raw, label: file.name);
  }

  Future<SpecImportOutcome> importRaw(
    String raw, {
    required String label,
  }) async {
    final List<DeeplinkEntry> entries;
    try {
      entries = source.parse(raw);
    } on SpecFormatException catch (e) {
      return SpecImportOutcome(
        result: ActionResult.error('${e.message} Nothing was changed.'),
      );
    } catch (e) {
      return SpecImportOutcome(
        result: ActionResult.error('Could not read the spec: $e'),
      );
    }

    final StoredSpec stored = StoredSpec(
      raw: raw,
      label: label,
      importedAt: DateTime.now(),
    );
    await store.write(stored);

    return SpecImportOutcome(
      result: ActionResult.ok(
        'Loaded ${entries.length} deeplink(s) from "$label".',
      ),
      loaded: SpecLoadResult(
        entries: entries,
        origin: SpecOrigin.imported,
        label: label,
        importedAt: stored.importedAt,
      ),
    );
  }

  Future<void> forget() => store.clear();
}
