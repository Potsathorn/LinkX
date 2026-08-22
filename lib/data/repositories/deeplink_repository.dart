import '../models/channel_label.dart';
import '../models/deeplink_entry.dart';
import '../models/user_type.dart';

class DeeplinkRepository {
  DeeplinkRepository(List<DeeplinkEntry> entries, {this.isExample = false})
      : _entries = List<DeeplinkEntry>.unmodifiable(entries);

  final List<DeeplinkEntry> _entries;
  final bool isExample;

  List<DeeplinkEntry> get all => _entries;

  int get count => _entries.length;

  DeeplinkEntry? byId(String id) {
    for (final DeeplinkEntry entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<ChannelLabel> get availableLabels {
    final Set<ChannelLabel> labels = <ChannelLabel>{
      for (final DeeplinkEntry entry in _entries) ...entry.labels,
    };
    return labels.toList()
      ..sort((ChannelLabel a, ChannelLabel b) => a.index.compareTo(b.index));
  }

  List<UserType> get availableUserTypes {
    final Set<UserType> types = <UserType>{
      for (final DeeplinkEntry entry in _entries) ...entry.allowedUserTypes,
    };
    return types.toList()
      ..sort((UserType a, UserType b) => a.index.compareTo(b.index));
  }

  int countForLabel(ChannelLabel label) =>
      _entries.where((DeeplinkEntry e) => e.hasLabel(label)).length;

  int countForUserType(UserType type) =>
      _entries.where((DeeplinkEntry e) => e.allowsUserType(type)).length;
}
