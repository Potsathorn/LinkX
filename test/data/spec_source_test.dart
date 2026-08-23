import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkx/core/constants/app_config.dart';
import 'package:linkx/data/datasources/deeplink_spec_source.dart';
import 'package:linkx/data/models/deeplink_entry.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final String? value = _files[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    final List<int> bytes = value.codeUnits;
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  const DeeplinkSpecSource source = DeeplinkSpecSource();

  final String example =
      File('assets/spec/example_spec.json').readAsStringSync();

  const String realSpec = '''
  {"deeplinks": [
    {"rank": 1, "destination_page": "RealPage",
     "structure": {"path_pattern": "demoapp://deeplink/real"},
     "valid_user_types": {"allowed": ["etu"]},
     "label": ["Push Noti"], "query_parameters": []}
  ]}''';

  test('loads the real spec when the asset is present', () async {
    final SpecLoadResult result = await source.load(
      bundle: _FakeBundle(<String, String>{
        AppConfig.specAssetPath: realSpec,
        AppConfig.exampleSpecAssetPath: example,
      }),
    );

    expect(result.isExample, isFalse);
    expect(result.entries.single.destinationPage, 'RealPage');
  });

  test('falls back to the example when the real spec is missing', () async {
    final SpecLoadResult result = await source.load(
      bundle: _FakeBundle(<String, String>{
        AppConfig.exampleSpecAssetPath: example,
      }),
    );

    expect(result.isExample, isTrue);
    expect(result.entries, isNotEmpty);
    expect(
      result.entries
          .every((DeeplinkEntry e) => e.destinationPage.startsWith('Example')),
      isTrue,
    );
  });

  test('falls back when the real spec is present but malformed', () async {
    final SpecLoadResult result = await source.load(
      bundle: _FakeBundle(<String, String>{
        AppConfig.specAssetPath: 'not json at all',
        AppConfig.exampleSpecAssetPath: example,
      }),
    );

    expect(result.isExample, isTrue);
    expect(result.entries, isNotEmpty);
  });
}
