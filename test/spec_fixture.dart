import 'dart:io';

import 'package:linkx_tester/data/datasources/deeplink_spec_source.dart';
import 'package:linkx_tester/data/models/deeplink_entry.dart';

const String kFixturePath = 'test/fixtures/sample_spec.json';
const String kRealSpecPath = 'assets/spec/deeplink_spec.json';

List<DeeplinkEntry>? _fixture;

List<DeeplinkEntry> loadSpecEntries() {
  return _fixture ??=
      const DeeplinkSpecSource().parse(File(kFixturePath).readAsStringSync());
}

DeeplinkEntry entryByPattern(String fragment) {
  return loadSpecEntries().firstWhere(
    (DeeplinkEntry e) => e.pathPattern.contains(fragment),
    orElse: () => throw StateError('No fixture entry matching "$fragment"'),
  );
}

bool get realSpecExists => File(kRealSpecPath).existsSync();

List<DeeplinkEntry> loadRealSpecEntries() {
  return const DeeplinkSpecSource()
      .parse(File(kRealSpecPath).readAsStringSync());
}
