import 'package:flutter/foundation.dart';

import '../datasources/deeplink_spec_source.dart';
import '../models/channel_label.dart';
import '../models/deeplink_entry.dart';
import '../models/user_type.dart';

class DeeplinkRepository extends ChangeNotifier {
  DeeplinkRepository(SpecLoadResult spec) : _spec = spec;

  SpecLoadResult _spec;

  List<DeeplinkEntry> get all => _spec.entries;
  SpecOrigin get origin => _spec.origin;
  String get label => _spec.label;
  DateTime? get importedAt => _spec.importedAt;
  bool get isExample => _spec.isExample;

  int get count => _spec.entries.length;

  void replace(SpecLoadResult spec) {
    _spec = spec;
    notifyListeners();
  }

  DeeplinkEntry? byId(String id) {
    for (final DeeplinkEntry entry in _spec.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<ChannelLabel> get availableLabels {
    final Set<ChannelLabel> labels = <ChannelLabel>{
      for (final DeeplinkEntry entry in _spec.entries) ...entry.labels,
    };
    return labels.toList()
      ..sort((ChannelLabel a, ChannelLabel b) => a.index.compareTo(b.index));
  }

  List<UserType> get availableUserTypes {
    final Set<UserType> types = <UserType>{
      for (final DeeplinkEntry entry in _spec.entries)
        ...entry.allowedUserTypes,
    };
    return types.toList()
      ..sort((UserType a, UserType b) => a.index.compareTo(b.index));
  }

  int countForLabel(ChannelLabel label) =>
      _spec.entries.where((DeeplinkEntry e) => e.hasLabel(label)).length;

  int countForUserType(UserType type) =>
      _spec.entries.where((DeeplinkEntry e) => e.allowsUserType(type)).length;
}
