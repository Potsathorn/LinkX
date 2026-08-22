import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
import '../datasources/local_storage.dart';
import '../models/entry_usage.dart';

class UsageRepository extends ChangeNotifier {
  UsageRepository(this._storage);

  final LocalStorage _storage;

  List<EntryUsage> loadAll() => _storage.readList<EntryUsage>(
        AppConfig.kUsageKey,
        EntryUsage.fromJson,
      );

  Map<String, EntryUsage> loadMap() => <String, EntryUsage>{
        for (final EntryUsage u in loadAll()) u.entryId: u,
      };

  Future<void> increment(String? entryId) async {
    if (entryId == null || entryId.isEmpty) return;

    final List<EntryUsage> usages = loadAll();
    final int index = usages.indexWhere((EntryUsage u) => u.entryId == entryId);

    if (index >= 0) {
      usages[index] = usages[index].increment();
    } else {
      usages.add(EntryUsage(
        entryId: entryId,
        count: 1,
        lastUsedAt: DateTime.now(),
      ));
    }
    await _storage.writeList(
      AppConfig.kUsageKey,
      usages,
      (EntryUsage u) => u.toJson(),
    );
    notifyListeners();
  }

  List<EntryUsage> top({int limit = AppConfig.topUsageLimit}) {
    final List<EntryUsage> usages = loadAll()
      ..sort((EntryUsage a, EntryUsage b) {
        final int byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : b.lastUsedAt.compareTo(a.lastUsedAt);
      });
    return usages.take(limit).toList();
  }

  Future<void> reset() async {
    await _storage.remove(AppConfig.kUsageKey);
    notifyListeners();
  }
}
