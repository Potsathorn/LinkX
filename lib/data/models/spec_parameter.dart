import 'package:flutter/foundation.dart';

import 'parameter_requirement.dart';

@immutable
class SpecParameter {
  const SpecParameter({
    required this.name,
    required this.requirement,
    this.allowedValues = const <String>[],
    this.isPathParameter = false,
  });

  final String name;
  final ParameterRequirement requirement;
  final List<String> allowedValues;
  final bool isPathParameter;

  bool get hasAllowedValues => allowedValues.isNotEmpty;

  List<String> get nameAlternatives =>
      name.split('|').map((String part) => part.trim()).toList();

  String get displayName => nameAlternatives.join(' | ');

  bool get hasAlternatives => nameAlternatives.length > 1;

  bool allows(String value) =>
      !hasAllowedValues || allowedValues.contains(value.trim());

  factory SpecParameter.fromJson(
    Map<String, dynamic> json, {
    bool isPathParameter = false,
  }) {
    return SpecParameter(
      name: (json['name'] as String? ?? '').trim(),
      requirement: ParameterRequirement.fromRaw(json['requirement'] as String?),
      allowedValues:
          (json['allowed_values_in_code'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic e) => e.toString())
              .toList(),
      isPathParameter: isPathParameter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecParameter &&
          other.name == name &&
          other.requirement == requirement &&
          other.isPathParameter == isPathParameter &&
          listEquals(other.allowedValues, allowedValues);

  @override
  int get hashCode => Object.hash(
      name, requirement, isPathParameter, Object.hashAll(allowedValues));
}
