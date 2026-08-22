import 'package:flutter_test/flutter_test.dart';
import 'package:linkx_tester/data/models/deeplink_entry.dart';
import 'package:linkx_tester/data/models/generated_link.dart';
import 'package:linkx_tester/data/models/link_parameter.dart';
import 'package:linkx_tester/data/models/user_type.dart';
import 'package:linkx_tester/services/deeplink_form_service.dart';
import 'package:linkx_tester/services/link_builder_service.dart';

import '../spec_fixture.dart';

void main() {
  const LinkBuilderService builder = LinkBuilderService();
  const DeeplinkFormService formService = DeeplinkFormService();

  List<LinkParameter> formFor(DeeplinkEntry entry, Map<String, String> values) {
    return formService
        .buildForm(entry, variant: entry.variants.first)
        .map((LinkParameter p) =>
            values.containsKey(p.name) ? p.copyWith(value: values[p.name]) : p)
        .toList();
  }

  String buildUrl(
    DeeplinkEntry entry,
    Map<String, String> values, {
    String? variant,
  }) {
    return builder
        .build(
          entry: entry,
          variant: variant ?? entry.variants.first,
          parameters: formFor(entry, values),
        )
        .url;
  }

  LinkValidation validate(
    DeeplinkEntry entry,
    Map<String, String> values, {
    UserType? userType,
  }) {
    return builder.validate(
      entry: entry,
      variant: entry.variants.first,
      parameters: formFor(entry, values),
      testedUserType: userType,
    );
  }

  group('query building', () {
    final DeeplinkEntry accounts = entryByPattern('/inbox?folder=');

    test('appends filled parameters', () {
      expect(
        buildUrl(
            accounts, <String, String>{'folder': 'alpha', 'view': 'compact'}),
        'demoapp://deeplink/inbox?folder=alpha&view=compact',
      );
    });

    test('omits empty parameters entirely', () {
      expect(
        buildUrl(accounts, <String, String>{'folder': 'alpha'}),
        'demoapp://deeplink/inbox?folder=alpha',
      );
    });

    test('produces a bare path when nothing is filled', () {
      expect(
          buildUrl(accounts, <String, String>{}), 'demoapp://deeplink/inbox');
    });

    test('percent-encodes values with %20 rather than +', () {
      final DeeplinkEntry products = entryByPattern('/catalog?groupCode=');
      final String url = buildUrl(products, <String, String>{
        'groupCode': 'ALPHA',
        'itemCode': 'a b',
        'variantCode': 'x/y',
      });
      expect(url, contains('itemCode=a%20b'));
      expect(url, contains('variantCode=x%2Fy'));
      expect(url, isNot(contains('+')));
    });

    test('drops a parameter that is toggled off', () {
      final List<LinkParameter> parameters = formFor(
              accounts, <String, String>{'folder': 'alpha', 'view': 'compact'})
          .map((LinkParameter p) =>
              p.name == 'view' ? p.copyWith(enabled: false) : p)
          .toList();

      final GeneratedLink link = builder.build(
        entry: accounts,
        variant: accounts.variants.first,
        parameters: parameters,
      );
      expect(link.url, 'demoapp://deeplink/inbox?folder=alpha');
    });
  });

  group('path token substitution', () {
    final DeeplinkEntry accountById = entryByPattern('/inbox/{itemId}');

    test('substitutes and encodes the token', () {
      expect(
        buildUrl(accountById, <String, String>{'itemId': 'ENC/123'}),
        'demoapp://deeplink/inbox/ENC%2F123',
      );
    });

    test('leaves the token visible while unfilled', () {
      expect(
        buildUrl(accountById, <String, String>{}),
        'demoapp://deeplink/inbox/{itemId}',
      );
    });

    test('handles a token with alternative names', () {
      final DeeplinkEntry entry = entryByPattern('/catalog/item/');
      expect(
        buildUrl(entry, <String, String>{'cmsId|itemCode': 'CMS99'}),
        'demoapp://deeplink/catalog/item/CMS99',
      );
    });
  });

  group('variants', () {
    final DeeplinkEntry campaigns = entryByPattern('/feed-list');

    test('builds from the selected variant', () {
      expect(buildUrl(campaigns, <String, String>{}),
          'demoapp://deeplink/feed-list');
      expect(
        buildUrl(campaigns, <String, String>{},
            variant: 'demoapp://deeplink/feed'),
        'demoapp://deeplink/feed',
      );
    });
  });

  group('validation — requirement', () {
    test('a required parameter blocks generation and is named', () {
      final DeeplinkEntry entry = entryByPattern('/offer-detail');
      final LinkValidation result = validate(entry, <String, String>{});

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('offerCode'));
    });

    test('filling every required parameter validates', () {
      final DeeplinkEntry entry = entryByPattern('/offer-detail');
      final LinkValidation result =
          validate(entry, <String, String>{'offerCode': 'OFFER26'});

      expect(result.isValid, isTrue);
    });

    test('conditional parameters need at least one value', () {
      final DeeplinkEntry entry = entryByPattern('/inbox?folder=');

      final LinkValidation empty = validate(entry, <String, String>{});
      expect(empty.isValid, isFalse);
      expect(empty.errors.single, contains('at least one'));

      final LinkValidation filled =
          validate(entry, <String, String>{'view': 'compact'});
      expect(filled.isValid, isTrue);
    });

    test('optional parameters never block generation', () {
      final DeeplinkEntry entry = entryByPattern('/home');
      expect(validate(entry, <String, String>{}).isValid, isTrue);
    });
  });

  group('validation — allowed_values_in_code', () {
    final DeeplinkEntry accounts = entryByPattern('/inbox?folder=');

    test('rejects a value outside the allowed list', () {
      final LinkValidation result =
          validate(accounts, <String, String>{'folder': 'gold'});

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('gold'));
      expect(result.errors.single, contains('alpha, beta, gamma'));
    });

    test('accepts a value from the allowed list', () {
      expect(
        validate(accounts, <String, String>{'folder': 'gamma'}).isValid,
        isTrue,
      );
    });

    test('a parameter with no allowed list accepts free text', () {
      final DeeplinkEntry entry = entryByPattern('/resume-task');
      expect(
        validate(entry, <String, String>{'taskId': 'anything-goes'}).isValid,
        isTrue,
      );
    });
  });

  group('validation — valid_user_types', () {
    final DeeplinkEntry etuOnly = entryByPattern('/preferences');

    test('warns when the tested user type is not allowed', () {
      final LinkValidation result =
          validate(etuOnly, <String, String>{}, userType: UserType.nta);

      expect(result.isValid, isTrue);
      expect(result.warnings.first, contains('NTA'));
      expect(result.warnings.first, contains('ETU'));
    });

    test('stays quiet for an allowed user type', () {
      final LinkValidation result =
          validate(etuOnly, <String, String>{}, userType: UserType.etu);

      expect(
        result.warnings.any((String w) => w.contains('allowed user types')),
        isFalse,
      );
    });
  });

  group('validation — label', () {
    test('warns that an unreferenced deeplink has no channel source', () {
      final DeeplinkEntry entry = entryByPattern('demoapp://deeplink/settings');
      final LinkValidation result = validate(entry, <String, String>{});

      expect(
        result.warnings.any((String w) => w.contains('not referenced')),
        isTrue,
      );
    });
  });

  group('GeneratedLink snapshot', () {
    test('captures the spec identity and applied parameters', () {
      final DeeplinkEntry entry = entryByPattern('/inbox?folder=');
      final GeneratedLink link = builder.build(
        entry: entry,
        variant: entry.variants.first,
        parameters: formFor(entry, <String, String>{'folder': 'alpha'}),
        testedUserType: UserType.etu,
      );

      expect(link.entryId, entry.id);
      expect(link.rank, 1);
      expect(link.destinationPage, 'InboxConnectorPage');
      expect(link.appliedParameters, <String, String>{'folder': 'alpha'});
      expect(link.testedUserType, UserType.etu);
    });

    test('survives a JSON round-trip', () {
      final DeeplinkEntry entry = entryByPattern('/inbox/{itemId}');
      final GeneratedLink link = builder.build(
        entry: entry,
        variant: entry.variants.first,
        parameters: formFor(entry, <String, String>{'itemId': '9001'}),
        testedUserType: UserType.etu,
      );

      final GeneratedLink restored = GeneratedLink.fromJson(link.toJson());

      expect(restored.url, link.url);
      expect(restored.entryId, link.entryId);
      expect(restored.testedUserType, UserType.etu);
      expect(restored.parameters.single.name, 'itemId');
      expect(restored.parameters.single.isPathParameter, isTrue);
    });
  });
}
