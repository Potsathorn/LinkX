import 'package:flutter/foundation.dart';

import '../core/constants/app_config.dart';
import '../core/utils/action_result.dart';
import '../data/models/channel_label.dart';
import '../data/models/deeplink_entry.dart';
import '../data/models/entry_usage.dart';
import '../data/models/user_type.dart';
import '../data/repositories/deeplink_repository.dart';
import '../data/repositories/usage_repository.dart';

@immutable
class RankedEntry {
  const RankedEntry({required this.entry, required this.usage});

  final DeeplinkEntry entry;
  final EntryUsage usage;

  int get count => usage.count;
}

class CatalogueViewModel extends ChangeNotifier {
  CatalogueViewModel({
    required DeeplinkRepository deeplinkRepository,
    required UsageRepository usageRepository,
  })  : _deeplinkRepository = deeplinkRepository,
        _usageRepository = usageRepository {
    _usageRepository.addListener(_reloadUsage);
    _reloadUsage();
  }

  final DeeplinkRepository _deeplinkRepository;
  final UsageRepository _usageRepository;

  Map<String, EntryUsage> _usage = <String, EntryUsage>{};
  String _query = '';
  ChannelLabel? _label;
  UserType? _userType;

  String get query => _query;
  ChannelLabel? get label => _label;
  UserType? get userType => _userType;
  bool get isSearching => _query.trim().isNotEmpty;
  bool get isFiltering => _label != null || _userType != null;
  int get totalCount => _deeplinkRepository.count;
  bool get isExampleSpec => _deeplinkRepository.isExample;

  List<ChannelLabel> get availableLabels => _deeplinkRepository.availableLabels;
  List<UserType> get availableUserTypes =>
      _deeplinkRepository.availableUserTypes;

  int countForLabel(ChannelLabel label) =>
      _deeplinkRepository.countForLabel(label);
  int countForUserType(UserType type) =>
      _deeplinkRepository.countForUserType(type);

  List<DeeplinkEntry> get entries {
    return _deeplinkRepository.all.where((DeeplinkEntry entry) {
      if (_label != null && !entry.hasLabel(_label!)) return false;
      if (_userType != null && !entry.allowsUserType(_userType!)) return false;
      return entry.matches(_query);
    }).toList();
  }

  List<RankedEntry> get mostUsed {
    final List<RankedEntry> ranked = <RankedEntry>[];
    for (final EntryUsage usage
        in _usageRepository.top(limit: AppConfig.topUsageLimit)) {
      final DeeplinkEntry? entry = _deeplinkRepository.byId(usage.entryId);
      if (entry != null) ranked.add(RankedEntry(entry: entry, usage: usage));
    }
    return ranked;
  }

  int usageCount(String entryId) => _usage[entryId]?.count ?? 0;

  void search(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearSearch() => search('');

  void selectLabel(ChannelLabel? value) {
    _label = _label == value ? null : value;
    notifyListeners();
  }

  void selectUserType(UserType? value) {
    _userType = _userType == value ? null : value;
    notifyListeners();
  }

  void clearFilters() {
    _label = null;
    _userType = null;
    notifyListeners();
  }

  Future<ActionResult> resetUsageStats() async {
    await _usageRepository.reset();
    return const ActionResult.ok('Usage statistics cleared.');
  }

  void _reloadUsage() {
    _usage = _usageRepository.loadMap();
    notifyListeners();
  }

  @override
  void dispose() {
    _usageRepository.removeListener(_reloadUsage);
    super.dispose();
  }
}
