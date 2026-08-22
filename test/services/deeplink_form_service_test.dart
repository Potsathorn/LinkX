import 'package:flutter_test/flutter_test.dart';
import 'package:linkx_tester/data/models/deeplink_entry.dart';
import 'package:linkx_tester/data/models/link_parameter.dart';
import 'package:linkx_tester/data/models/parameter_requirement.dart';
import 'package:linkx_tester/services/deeplink_form_service.dart';

import '../spec_fixture.dart';

void main() {
  const DeeplinkFormService service = DeeplinkFormService();

  test('builds a field for every path and query parameter', () {
    final DeeplinkEntry entry = entryByPattern('/inbox?folder=');
    final List<LinkParameter> form = service.buildForm(entry);

    expect(form.map((LinkParameter p) => p.name).toSet(), <String>{
      'folder',
      'view',
      'mode',
      'traceId',
      'refId',
      'note',
    });
  });

  test('orders required, then conditional, then optional', () {
    final DeeplinkEntry entry = entryByPattern('/listing/catalog');
    final List<ParameterRequirement> order = service
        .buildForm(entry)
        .map((LinkParameter p) => p.requirement)
        .toList();

    final List<ParameterRequirement> sorted =
        List<ParameterRequirement>.from(order)
          ..sort((ParameterRequirement a, ParameterRequirement b) =>
              a.index.compareTo(b.index));
    expect(order, sorted);
    expect(order.first, ParameterRequirement.required);
  });

  test('includes the path token as a required field', () {
    final DeeplinkEntry entry = entryByPattern('/inbox/{itemId}');
    final LinkParameter itemId = service.buildForm(entry).single;

    expect(itemId.name, 'itemId');
    expect(itemId.isPathParameter, isTrue);
    expect(itemId.requirement, ParameterRequirement.required);
  });

  test('fields start empty and enabled', () {
    final DeeplinkEntry entry = entryByPattern('/offer-detail');
    final LinkParameter offerCode = service.buildForm(entry).single;

    expect(offerCode.hasValue, isFalse);
    expect(offerCode.enabled, isTrue);
    expect(offerCode.isMissing, isTrue);
  });

  test('switching variant preserves values already typed', () {
    final DeeplinkEntry entry = entryByPattern('/feed-list');
    final List<LinkParameter> first = service
        .buildForm(entry, variant: entry.variants.first)
        .map((LinkParameter p) => p.copyWith(value: 'kept'))
        .toList();

    final List<LinkParameter> second = service.buildForm(
      entry,
      variant: entry.variants.last,
      previous: first,
    );

    for (final LinkParameter p in second) {
      expect(p.value, 'kept');
    }
  });

  test('a deeplink with no parameters yields an empty form', () {
    final DeeplinkEntry entry = entryByPattern('/profile/addresses');
    expect(service.buildForm(entry), isEmpty);
  });

  test('exposes only the path parameters present in the chosen variant', () {
    final DeeplinkEntry entry = entryByPattern('/feed-list');
    expect(
      service.pathParametersFor(entry, entry.variants.first),
      isEmpty,
    );
  });
}
