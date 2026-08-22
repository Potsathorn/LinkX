import 'package:flutter/foundation.dart';

import '../data/models/channel_label.dart';
import '../data/models/deeplink_entry.dart';
import '../data/models/generated_link.dart';
import '../data/models/link_parameter.dart';
import '../data/models/parameter_requirement.dart';
import '../data/models/user_type.dart';

@immutable
class LinkValidation {
  const LinkValidation({
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  static const LinkValidation valid = LinkValidation();
}

class LinkBuilderService {
  const LinkBuilderService();

  static final RegExp _tokenPattern = RegExp(r'\{([^{}]+)\}');

  GeneratedLink build({
    required DeeplinkEntry entry,
    required String variant,
    required List<LinkParameter> parameters,
    UserType? testedUserType,
  }) {
    final int queryIndex = variant.indexOf('?');
    final String rawBase =
        queryIndex >= 0 ? variant.substring(0, queryIndex) : variant;

    final String base = _substitutePathTokens(rawBase, parameters);
    final String query = _buildQuery(parameters);

    return GeneratedLink(
      url: query.isEmpty ? base : '$base?$query',
      entryId: entry.id,
      destinationPage: entry.destinationPage,
      rank: entry.rank,
      pathPattern: variant,
      parameters: List<LinkParameter>.unmodifiable(parameters),
      testedUserType: testedUserType,
    );
  }

  String _substitutePathTokens(String base, List<LinkParameter> parameters) {
    final Map<String, LinkParameter> byName = <String, LinkParameter>{
      for (final LinkParameter p in parameters) p.name: p,
    };

    return base.replaceAllMapped(_tokenPattern, (Match match) {
      final String name = match.group(1)!.trim();
      final LinkParameter? parameter = byName[name];
      if (parameter == null || !parameter.isIncluded) return match.group(0)!;
      return Uri.encodeComponent(parameter.trimmedValue);
    });
  }

  String _buildQuery(List<LinkParameter> parameters) {
    final List<String> pairs = <String>[];
    final Set<String> names = <String>{};

    for (final LinkParameter p in parameters) {
      if (p.isPathParameter || !p.isIncluded) continue;
      if (!names.add(p.name)) continue;
      pairs.add(
        '${Uri.encodeComponent(p.name)}=${Uri.encodeComponent(p.trimmedValue)}',
      );
    }
    return pairs.join('&');
  }

  LinkValidation validate({
    required DeeplinkEntry entry,
    required String variant,
    required List<LinkParameter> parameters,
    UserType? testedUserType,
  }) {
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];

    final List<LinkParameter> missing =
        parameters.where((LinkParameter p) => p.isMissing).toList();
    if (missing.isNotEmpty) {
      errors.add(
        'Fill in the required parameter(s): '
        '${missing.map((LinkParameter p) => p.displayName).join(', ')}.',
      );
    }

    final List<LinkParameter> conditional = parameters
        .where((LinkParameter p) =>
            p.requirement == ParameterRequirement.conditional)
        .toList();
    if (conditional.isNotEmpty &&
        !conditional.any((LinkParameter p) => p.isIncluded)) {
      errors.add(
        'This deeplink needs at least one of: '
        '${conditional.map((LinkParameter p) => p.displayName).join(', ')}.',
      );
    }

    for (final LinkParameter p in parameters) {
      if (!p.hasDisallowedValue) continue;
      errors.add(
        '"${p.trimmedValue}" is not an allowed value for ${p.displayName} '
        '(${p.allowedValues.join(', ')}).',
      );
    }

    if (testedUserType != null && !entry.allowsUserType(testedUserType)) {
      warnings.add(
        '${testedUserType.label} is not in this deeplink\'s allowed user types '
        '(${entry.allowedUserTypes.map((UserType u) => u.label).join(', ')}). '
        'The app will not route it for that session.',
      );
    }

    if (entry.hasLabel(ChannelLabel.unreferenced)) {
      warnings.add(
        'This deeplink is not referenced by any channel source in the spec.',
      );
    }

    final Iterable<LinkParameter> disabledRequired = parameters.where(
      (LinkParameter p) =>
          !p.enabled && p.requirement == ParameterRequirement.required,
    );
    if (disabledRequired.isNotEmpty) {
      warnings.add(
        'Required parameter(s) excluded on purpose: '
        '${disabledRequired.map((LinkParameter p) => p.displayName).join(', ')}.',
      );
    }

    return LinkValidation(errors: errors, warnings: warnings);
  }
}
