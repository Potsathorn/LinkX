import 'package:flutter/foundation.dart';

import 'parameter_requirement.dart';
import 'spec_parameter.dart';

@immutable
class LinkParameter {
  const LinkParameter({
    required this.spec,
    this.value = '',
    this.enabled = true,
  });

  final SpecParameter spec;
  final String value;
  final bool enabled;

  String get name => spec.name;
  String get displayName => spec.displayName;
  ParameterRequirement get requirement => spec.requirement;
  List<String> get allowedValues => spec.allowedValues;
  bool get isPathParameter => spec.isPathParameter;
  bool get hasAllowedValues => spec.hasAllowedValues;

  String get trimmedValue => value.trim();
  bool get hasValue => trimmedValue.isNotEmpty;

  bool get isIncluded => enabled && hasValue;

  bool get isMissing =>
      requirement == ParameterRequirement.required && enabled && !hasValue;

  bool get hasDisallowedValue =>
      enabled && hasValue && !spec.allows(trimmedValue);

  LinkParameter copyWith({
    SpecParameter? spec,
    String? value,
    bool? enabled,
  }) {
    return LinkParameter(
      spec: spec ?? this.spec,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': spec.name,
        'requirement': spec.requirement.raw,
        'allowed_values_in_code': spec.allowedValues,
        'isPathParameter': spec.isPathParameter,
        'value': value,
        'enabled': enabled,
      };

  factory LinkParameter.fromJson(Map<String, dynamic> json) => LinkParameter(
        spec: SpecParameter.fromJson(
          json,
          isPathParameter: json['isPathParameter'] as bool? ?? false,
        ),
        value: json['value'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkParameter &&
          other.spec == spec &&
          other.value == value &&
          other.enabled == enabled;

  @override
  int get hashCode => Object.hash(spec, value, enabled);
}
