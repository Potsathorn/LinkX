import '../data/models/deeplink_entry.dart';
import '../data/models/link_parameter.dart';
import '../data/models/parameter_requirement.dart';
import '../data/models/spec_parameter.dart';

class DeeplinkFormService {
  const DeeplinkFormService();

  static final RegExp _tokenPattern = RegExp(r'\{([^{}]+)\}');

  List<LinkParameter> buildForm(
    DeeplinkEntry entry, {
    String? variant,
    List<LinkParameter> previous = const <LinkParameter>[],
  }) {
    final Map<String, LinkParameter> previousByName = <String, LinkParameter>{
      for (final LinkParameter p in previous) p.name: p,
    };

    final List<LinkParameter> form = <LinkParameter>[];
    final Set<String> seen = <String>{};

    for (final SpecParameter spec
        in pathParametersFor(entry, variant ?? entry.variants.first)) {
      if (!seen.add(spec.name)) continue;
      form.add(_restore(spec, previousByName[spec.name]));
    }

    for (final SpecParameter spec in entry.queryParameters) {
      if (!seen.add(spec.name)) continue;
      form.add(_restore(spec, previousByName[spec.name]));
    }

    form.sort((LinkParameter a, LinkParameter b) {
      final int byRequirement =
          _weight(a.requirement).compareTo(_weight(b.requirement));
      if (byRequirement != 0) return byRequirement;
      if (a.isPathParameter != b.isPathParameter) {
        return a.isPathParameter ? -1 : 1;
      }
      return 0;
    });
    return form;
  }

  List<SpecParameter> pathParametersFor(DeeplinkEntry entry, String variant) {
    final int queryIndex = variant.indexOf('?');
    final String base =
        queryIndex >= 0 ? variant.substring(0, queryIndex) : variant;

    final Set<String> tokens = _tokenPattern
        .allMatches(base)
        .map((RegExpMatch m) => m.group(1)!.trim())
        .toSet();

    return entry.pathParameters
        .where((SpecParameter p) => tokens.contains(p.name))
        .toList();
  }

  LinkParameter _restore(SpecParameter spec, LinkParameter? previous) {
    if (previous == null) return LinkParameter(spec: spec);
    return LinkParameter(
      spec: spec,
      value: previous.value,
      enabled: previous.enabled,
    );
  }

  int _weight(ParameterRequirement requirement) => switch (requirement) {
        ParameterRequirement.required => 0,
        ParameterRequirement.conditional => 1,
        ParameterRequirement.optional => 2,
      };
}
