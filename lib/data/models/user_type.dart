enum UserType {
  etu('etu', 'ETU', 'Existing user, logged in'),
  etp('etp', 'ETP', 'Existing prospect'),
  ntu('ntu', 'NTU', 'New to us, registered'),
  nta('nta', 'NTA', 'New to app'),
  prospect('prospect', 'Prospect', 'Prospect / unregistered');

  const UserType(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static UserType? fromCode(String code) {
    final String normalized = code.trim().toLowerCase();
    for (final UserType type in UserType.values) {
      if (type.code == normalized) return type;
    }
    return null;
  }

  static List<UserType> parseList(List<dynamic> raw) {
    final List<UserType> result = <UserType>[];
    for (final dynamic value in raw) {
      final UserType? type = fromCode(value.toString());
      if (type != null && !result.contains(type)) result.add(type);
    }
    result.sort((UserType a, UserType b) => a.index.compareTo(b.index));
    return result;
  }
}
