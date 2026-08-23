import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkx/data/datasources/deeplink_spec_source.dart';
import 'package:linkx/data/datasources/spec_store.dart';
import 'package:linkx/services/spec_import_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _TempPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TempPathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late SpecStore store;

  const String validSpec = '''
  {"deeplinks": [
    {"rank": 1, "destination_page": "ImportedPage",
     "structure": {"path_pattern": "cardx://deeplink/imported"},
     "valid_user_types": {"allowed": ["etu"]},
     "label": ["Push Noti"], "query_parameters": []}
  ]}''';

  setUp(() {
    temp = Directory.systemTemp.createTempSync('linkx_spec_test');
    PathProviderPlatform.instance = _TempPathProvider(temp.path);
    store = const SpecStore();
  });

  tearDown(() => temp.deleteSync(recursive: true));

  group('SpecStore', () {
    test('reads nothing before anything is written', () async {
      expect(await store.read(), isNull);
    });

    test('round-trips an imported spec', () async {
      await store.write(StoredSpec(
        raw: validSpec,
        label: 'build_42.json',
        importedAt: DateTime(2026, 8, 23, 10, 30),
      ));

      final StoredSpec? stored = await store.read();
      expect(stored, isNotNull);
      expect(stored!.label, 'build_42.json');
      expect(stored.importedAt, DateTime(2026, 8, 23, 10, 30));
      expect(jsonDecode(stored.raw), isA<Map<String, dynamic>>());
    });

    test('clear removes it', () async {
      await store.write(StoredSpec(
        raw: validSpec,
        label: 'x.json',
        importedAt: DateTime.now(),
      ));
      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('SpecImportService', () {
    test('saves a valid spec and reports the entry count', () async {
      const SpecImportService service = SpecImportService();
      final SpecImportOutcome outcome =
          await service.importRaw(validSpec, label: 'build_42.json');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.result.message, contains('1 deeplink'));
      expect(outcome.loaded!.origin, SpecOrigin.imported);
      expect(outcome.loaded!.entries.single.destinationPage, 'ImportedPage');
      expect((await store.read())!.label, 'build_42.json');
    });

    test('rejects malformed input and keeps the previous spec', () async {
      const SpecImportService service = SpecImportService();
      await service.importRaw(validSpec, label: 'good.json');

      final SpecImportOutcome outcome =
          await service.importRaw('not json', label: 'bad.json');

      expect(outcome.isSuccess, isFalse);
      expect(outcome.result.success, isFalse);
      expect(outcome.result.message, contains('Nothing was changed'));
      expect((await store.read())!.label, 'good.json');
    });
  });

  group('DeeplinkSpecSource', () {
    test('prefers an imported spec over the bundled assets', () async {
      await const SpecImportService()
          .importRaw(validSpec, label: 'build_42.json');

      final SpecLoadResult result = await const DeeplinkSpecSource().load(
        bundle: _StubBundle(),
      );

      expect(result.origin, SpecOrigin.imported);
      expect(result.label, 'build_42.json');
      expect(result.entries.single.destinationPage, 'ImportedPage');
    });

    test('discards a stored spec that no longer parses', () async {
      await store.write(StoredSpec(
        raw: 'corrupted',
        label: 'broken.json',
        importedAt: DateTime.now(),
      ));

      final SpecLoadResult result = await const DeeplinkSpecSource().load(
        bundle: _StubBundle(),
      );

      expect(result.origin, isNot(SpecOrigin.imported));
      expect(await store.read(), isNull);
    });
  });
}

class _StubBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final String body =
        File('assets/spec/example_spec.json').readAsStringSync();
    return ByteData.view(Uint8List.fromList(utf8.encode(body)).buffer);
  }
}
