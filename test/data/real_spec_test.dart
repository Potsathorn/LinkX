import 'package:flutter_test/flutter_test.dart';
import 'package:linkx/data/models/deeplink_entry.dart';
import 'package:linkx/data/models/spec_parameter.dart';

import '../spec_fixture.dart';

void main() {
  group('bundled deeplink_spec.json', () {
    if (!realSpecExists) {
      test('is absent — skipping conformance checks', () {
        expect(realSpecExists, isFalse);
      }, skip: 'deeplink_spec.json is not present in this checkout');
      return;
    }

    final List<DeeplinkEntry> entries = loadRealSpecEntries();

    test('parses without error', () {
      expect(entries, isNotEmpty);
    });

    test('every entry carries the keys the app depends on', () {
      for (final DeeplinkEntry entry in entries) {
        expect(entry.rank, greaterThan(0), reason: entry.destinationPage);
        expect(entry.destinationPage, isNotEmpty);
        expect(entry.pathPattern, contains('://'));
        expect(entry.labels, isNotEmpty, reason: entry.destinationPage);
        expect(entry.allowedUserTypes, isNotEmpty,
            reason: entry.destinationPage);
        expect(entry.variants, isNotEmpty, reason: entry.destinationPage);

        for (final SpecParameter p in entry.allParameters) {
          expect(p.name, isNotEmpty, reason: entry.destinationPage);
        }
      }
    });

    test('ids are unique and the list is rank ordered', () {
      expect(
        entries.map((DeeplinkEntry e) => e.id).toSet(),
        hasLength(entries.length),
      );
      final List<int> ranks = entries.map((DeeplinkEntry e) => e.rank).toList();
      expect(ranks, List<int>.from(ranks)..sort());
    });
  });
}
