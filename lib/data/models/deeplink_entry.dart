import 'package:flutter/foundation.dart';

import 'channel_label.dart';
import 'parameter_requirement.dart';
import 'spec_parameter.dart';
import 'user_type.dart';

@immutable
class DeeplinkEntry {
  const DeeplinkEntry({
    required this.id,
    required this.rank,
    required this.destinationPage,
    required this.pathPattern,
    required this.variants,
    required this.labels,
    required this.allowedUserTypes,
    required this.queryParameters,
    required this.pathParameters,
  });

  final String id;
  final int rank;
  final String destinationPage;
  final String pathPattern;
  final List<String> variants;
  final List<ChannelLabel> labels;
  final List<UserType> allowedUserTypes;
  final List<SpecParameter> queryParameters;
  final List<SpecParameter> pathParameters;

  static final RegExp _tokenPattern = RegExp(r'\{([^{}]+)\}');

  static final RegExp _variantSeparator = RegExp(r'\s+\|\s+');

  static final RegExp _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

  List<String> get destinationPages => destinationPage
      .split(RegExp(r'\s*[,/]\s*'))
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList();

  String get primaryDestination =>
      destinationPages.isEmpty ? destinationPage : destinationPages.first;

  int get extraDestinationCount =>
      destinationPages.length > 1 ? destinationPages.length - 1 : 0;

  List<SpecParameter> get allParameters =>
      <SpecParameter>[...pathParameters, ...queryParameters];

  bool get hasVariants => variants.length > 1;

  bool get hasParameters => allParameters.isNotEmpty;

  List<SpecParameter> get requiredParameters => allParameters
      .where(
          (SpecParameter p) => p.requirement == ParameterRequirement.required)
      .toList();

  List<SpecParameter> get conditionalParameters => allParameters
      .where((SpecParameter p) =>
          p.requirement == ParameterRequirement.conditional)
      .toList();

  bool allowsUserType(UserType type) => allowedUserTypes.contains(type);

  bool hasLabel(ChannelLabel label) => labels.contains(label);

  String get searchIndex => <String>[
        destinationPage,
        pathPattern,
        'rank $rank',
        ...labels.map((ChannelLabel l) => '${l.raw} ${l.shortLabel}'),
        ...allowedUserTypes.map((UserType u) => '${u.code} ${u.label}'),
        ...allParameters.map((SpecParameter p) => p.name),
        ...allParameters.expand((SpecParameter p) => p.allowedValues),
      ].join(' ').toLowerCase();

  bool matches(String query) {
    final String trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    return trimmed.split(RegExp(r'\s+')).every(searchIndex.contains);
  }

  factory DeeplinkEntry.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> structure = Map<String, dynamic>.from(
        json['structure'] as Map? ?? <String, dynamic>{});
    final Map<String, dynamic> userTypes = Map<String, dynamic>.from(
        json['valid_user_types'] as Map? ?? <String, dynamic>{});

    final String pathPattern =
        (structure['path_pattern'] as String? ?? '').trim();
    final List<String> variants = pathPattern
        .split(_variantSeparator)
        .map((String part) => part.trim())
        .where((String part) => _schemePattern.hasMatch(part))
        .toList();

    final List<SpecParameter> queryParameters =
        (json['query_parameters'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                SpecParameter.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((SpecParameter p) => p.name.isNotEmpty)
            .toList();

    return DeeplinkEntry(
      id: _idFor(pathPattern),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      destinationPage:
          (json['destination_page'] as String? ?? 'Unknown').trim(),
      pathPattern: pathPattern,
      variants: variants.isEmpty ? <String>[pathPattern] : variants,
      labels: ChannelLabel.parseList(
          json['label'] as List<dynamic>? ?? <dynamic>[]),
      allowedUserTypes: UserType.parseList(
          userTypes['allowed'] as List<dynamic>? ?? <dynamic>[]),
      queryParameters: queryParameters,
      pathParameters: _pathParametersFrom(
        variants.isEmpty ? <String>[pathPattern] : variants,
      ),
    );
  }

  static List<SpecParameter> _pathParametersFrom(List<String> variants) {
    final List<SpecParameter> result = <SpecParameter>[];
    final Set<String> seen = <String>{};

    for (final String variant in variants) {
      final int queryIndex = variant.indexOf('?');
      final String base =
          queryIndex >= 0 ? variant.substring(0, queryIndex) : variant;

      for (final RegExpMatch match in _tokenPattern.allMatches(base)) {
        final String name = match.group(1)!.trim();
        if (name.isEmpty || !seen.add(name)) continue;
        result.add(SpecParameter(
          name: name,
          requirement: ParameterRequirement.required,
          isPathParameter: true,
        ));
      }
    }
    return result;
  }

  static String _idFor(String pathPattern) {
    final String slug = pathPattern
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'entry' : slug;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeeplinkEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
