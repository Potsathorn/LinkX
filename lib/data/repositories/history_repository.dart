import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_config.dart';
import '../datasources/local_storage.dart';
import '../models/generated_link.dart';
import '../models/history_entry.dart';

class HistoryRepository extends ChangeNotifier {
  HistoryRepository(this._storage);

  final LocalStorage _storage;
  final Uuid _uuid = const Uuid();

  List<HistoryEntry> loadAll() {
    final List<HistoryEntry> entries = _storage.readList<HistoryEntry>(
      AppConfig.kHistoryKey,
      HistoryEntry.fromJson,
    );
    entries.sort(
        (HistoryEntry a, HistoryEntry b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> _write(List<HistoryEntry> entries) => _storage.writeList(
        AppConfig.kHistoryKey,
        entries,
        (HistoryEntry e) => e.toJson(),
      );

  Future<HistoryEntry> add(GeneratedLink link, LinkAction action) async {
    final List<HistoryEntry> entries = loadAll();

    if (entries.isNotEmpty &&
        entries.first.url == link.url &&
        entries.first.action == action) {
      final HistoryEntry refreshed =
          entries.first.copyWith(timestamp: DateTime.now());
      entries[0] = refreshed;
      await _write(entries);
      notifyListeners();
      return refreshed;
    }

    final HistoryEntry entry = HistoryEntry(
      id: _uuid.v4(),
      link: link,
      action: action,
      timestamp: DateTime.now(),
    );
    entries.insert(0, entry);

    if (entries.length > AppConfig.historyLimit) {
      entries.removeRange(AppConfig.historyLimit, entries.length);
    }
    await _write(entries);
    notifyListeners();
    return entry;
  }

  Future<void> delete(String id) async {
    final List<HistoryEntry> entries = loadAll()
      ..removeWhere((HistoryEntry e) => e.id == id);
    await _write(entries);
    notifyListeners();
  }

  Future<void> clear() async {
    await _storage.remove(AppConfig.kHistoryKey);
    notifyListeners();
  }
}
