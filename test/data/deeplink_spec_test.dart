import 'package:flutter_test/flutter_test.dart';
import 'package:linkx_tester/data/datasources/deeplink_spec_source.dart';
import 'package:linkx_tester/data/models/channel_label.dart';
import 'package:linkx_tester/data/models/deeplink_entry.dart';
import 'package:linkx_tester/data/models/parameter_requirement.dart';
import 'package:linkx_tester/data/models/spec_parameter.dart';
import 'package:linkx_tester/data/models/user_type.dart';

import '../spec_fixture.dart';

void main() {
  final List<DeeplinkEntry> entries = loadSpecEntries();

  group('spec loading', () {
    test('parses every deeplink in the file', () {
      expect(entries, hasLength(13));
    });

    test('gives every entry a unique id', () {
      final Set<String> ids = entries.map((DeeplinkEntry e) => e.id).toSet();
      expect(ids, hasLength(entries.length));
    });

    test('sorts by rank', () {
      final List<int> ranks = entries.map((DeeplinkEntry e) => e.rank).toList();
      expect(ranks, List<int>.from(ranks)..sort());
      expect(ranks.first, 1);
    });

    test('breaks a rank tie by destination page', () {
      final List<DeeplinkEntry> tied =
          entries.where((DeeplinkEntry e) => e.rank == 12).toList();
      expect(tied, hasLength(2));
      expect(
        tied.map((DeeplinkEntry e) => e.destinationPage),
        <String>['SettingsPage', 'StatusTrackingPage'],
      );
    });

    test('every entry carries the required spec keys', () {
      for (final DeeplinkEntry entry in entries) {
        expect(entry.rank, greaterThan(0), reason: entry.destinationPage);
        expect(entry.destinationPage, isNotEmpty);
        expect(entry.pathPattern, contains('://'));
        expect(entry.labels, isNotEmpty, reason: entry.destinationPage);
        expect(entry.allowedUserTypes, isNotEmpty,
            reason: entry.destinationPage);
      }
    });

    test('drops an entry with no path pattern but keeps the rest', () {
      const String raw = '''
      {"deeplinks": [
        {"rank": 1, "destination_page": "Broken", "structure": {"path_pattern": ""},
         "valid_user_types": {"allowed": ["etu"]},
         "label": ["Push Noti"], "query_parameters": []},
        {"rank": 2, "destination_page": "Fine",
         "structure": {"path_pattern": "demoapp://deeplink/fine"},
         "valid_user_types": {"allowed": ["etu"]},
         "label": ["Push Noti"], "query_parameters": []}
      ]}''';
      final List<DeeplinkEntry> parsed = const DeeplinkSpecSource().parse(raw);
      expect(parsed.single.destinationPage, 'Fine');
    });

    test('rejects a spec with no usable entry', () {
      const String raw = '{"deeplinks": []}';
      expect(
        () => const DeeplinkSpecSource().parse(raw),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('rejects input that is not a deeplink spec', () {
      expect(
        () => const DeeplinkSpecSource().parse('{"other": 1}'),
        throwsA(isA<SpecFormatException>()),
      );
      expect(
        () => const DeeplinkSpecSource().parse('nonsense'),
        throwsA(isA<SpecFormatException>()),
      );
    });
  });

  group('rank 1 entry', () {
    final DeeplinkEntry entry = entryByPattern('/inbox?folder=');

    test('maps rank, destination page and path pattern', () {
      expect(entry.rank, 1);
      expect(entry.destinationPage, 'InboxConnectorPage');
      expect(
        entry.pathPattern,
        'demoapp://deeplink/inbox?folder={folder}&view={view}',
      );
    });

    test('maps labels', () {
      expect(entry.labels, <ChannelLabel>[
        ChannelLabel.marketingOneLink,
        ChannelLabel.chatVoiceBot,
      ]);
    });

    test('maps allowed user types', () {
      expect(entry.allowedUserTypes, <UserType>[UserType.etu]);
      expect(entry.allowsUserType(UserType.etu), isTrue);
      expect(entry.allowsUserType(UserType.nta), isFalse);
    });

    test('maps query parameter names and requirements', () {
      expect(
        entry.queryParameters.map((SpecParameter p) => p.name),
        <String>['folder', 'view', 'mode', 'refId', 'traceId', 'note'],
      );
      expect(entry.queryParameters.first.requirement,
          ParameterRequirement.conditional);
      expect(entry.queryParameters.last.requirement,
          ParameterRequirement.optional);
    });

    test('maps allowed_values_in_code', () {
      final SpecParameter folder = entry.queryParameters.first;
      expect(folder.allowedValues, <String>['alpha', 'beta', 'gamma']);
      expect(folder.allows('alpha'), isTrue);
      expect(folder.allows('nope'), isFalse);
    });

    test('a parameter without allowed values accepts anything', () {
      final SpecParameter refId = entry.queryParameters
          .firstWhere((SpecParameter p) => p.name == 'refId');
      expect(refId.hasAllowedValues, isFalse);
      expect(refId.allows('anything'), isTrue);
    });
  });

  group('path patterns', () {
    test('tokens in the path become required path parameters', () {
      final DeeplinkEntry entry = entryByPattern('/inbox/{itemId}');
      expect(entry.pathParameters.map((SpecParameter p) => p.name),
          <String>['itemId']);
      expect(entry.pathParameters.single.requirement,
          ParameterRequirement.required);
      expect(entry.pathParameters.single.isPathParameter, isTrue);
    });

    test('alternative patterns are split into variants', () {
      final DeeplinkEntry entry = entryByPattern('/feed-list');
      expect(entry.hasVariants, isTrue);
      expect(entry.variants, <String>[
        'demoapp://deeplink/feed-list',
        'demoapp://deeplink/feed',
      ]);
    });

    test('a single pattern yields exactly one variant', () {
      final DeeplinkEntry entry = entryByPattern('/settings');
      expect(entry.hasVariants, isFalse);
      expect(entry.variants, <String>['demoapp://deeplink/settings']);
    });

    test('a token with alternatives keeps both names for display', () {
      final DeeplinkEntry entry = entryByPattern('/catalog/item/');
      final SpecParameter param = entry.pathParameters.single;
      expect(param.name, 'cmsId|itemCode');
      expect(param.hasAlternatives, isTrue);
      expect(param.displayName, 'cmsId | itemCode');
    });
  });

  group('facets', () {
    test('every label maps to a known channel', () {
      final Set<ChannelLabel> labels = <ChannelLabel>{
        for (final DeeplinkEntry e in entries) ...e.labels,
      };
      expect(labels, ChannelLabel.values.toSet());
    });

    test('every allowed user type maps to a known type', () {
      final Set<UserType> types = <UserType>{
        for (final DeeplinkEntry e in entries) ...e.allowedUserTypes,
      };
      expect(types, UserType.values.toSet());
    });

    test('unreferenced deeplinks are flagged', () {
      expect(
        entries
            .where((DeeplinkEntry e) => e.hasLabel(ChannelLabel.unreferenced)),
        hasLength(1),
      );
    });
  });

  group('search', () {
    test('matches on destination page', () {
      expect(
          entryByPattern('/offer-detail').matches('offerdetailpage'), isTrue);
    });

    test('matches on parameter name and allowed value', () {
      final DeeplinkEntry entry = entryByPattern('/inbox?folder=');
      expect(entry.matches('traceId'), isTrue);
      expect(entry.matches('compact'), isTrue);
    });

    test('requires every word to match', () {
      final DeeplinkEntry entry = entryByPattern('/settings');
      expect(entry.matches('settings'), isTrue);
      expect(entry.matches('settings nonsense'), isFalse);
    });

    test('an empty query matches everything', () {
      expect(entries.every((DeeplinkEntry e) => e.matches('   ')), isTrue);
    });
  });
}
