enum ParameterRequirement {
  required('required', 'Required'),
  conditional('conditional', 'Conditional'),
  optional('optional', 'Optional');

  const ParameterRequirement(this.raw, this.label);

  final String raw;
  final String label;

  bool get mustBeFilled => this == ParameterRequirement.required;

  static ParameterRequirement fromRaw(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    for (final ParameterRequirement requirement
        in ParameterRequirement.values) {
      if (requirement.raw == normalized) return requirement;
    }
    return ParameterRequirement.optional;
  }
}
