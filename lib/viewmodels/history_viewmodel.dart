import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/utils/action_result.dart';
import '../data/models/history_entry.dart';
import '../data/repositories/history_repository.dart';
import '../services/launcher_service.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    required HistoryRepository historyRepository,
    required LauncherService launcher,
  })  : _historyRepository = historyRepository,
        _launcher = launcher {
    _historyRepository.addListener(_reload);
    _reload();
  }

  final HistoryRepository _historyRepository;
  final LauncherService _launcher;

  List<HistoryEntry> _all = <HistoryEntry>[];
  String _query = '';

  String get query => _query;
  bool get isEmpty => _all.isEmpty;
  int get totalCount => _all.length;

  List<HistoryEntry> get entries =>
      _all.where((HistoryEntry e) => e.matches(_query)).toList();

  Map<DateTime, List<HistoryEntry>> get groupedByDay {
    final Map<DateTime, List<HistoryEntry>> grouped =
        <DateTime, List<HistoryEntry>>{};

    for (final HistoryEntry e in entries) {
      final DateTime day =
          DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      grouped.putIfAbsent(day, () => <HistoryEntry>[]).add(e);
    }
    return grouped;
  }

  void search(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearSearch() => search('');

  Future<ActionResult> relaunch(HistoryEntry entry) async {
    final LaunchResult result = await _launcher.launch(entry.url);
    if (!result.isSuccess) return ActionResult.error(result.message);

    await _historyRepository.add(entry.link, LinkAction.launched);
    return const ActionResult.ok('Opening the link…');
  }

  Future<ActionResult> copy(HistoryEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.url));
    return const ActionResult.ok('Link copied to the clipboard.');
  }

  Future<ActionResult> delete(HistoryEntry entry) async {
    await _historyRepository.delete(entry.id);
    return const ActionResult.ok('History entry removed.');
  }

  Future<ActionResult> clearAll() async {
    if (_all.isEmpty) return const ActionResult.none();
    await _historyRepository.clear();
    return const ActionResult.ok('History cleared.');
  }

  void _reload() {
    _all = _historyRepository.loadAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _historyRepository.removeListener(_reload);
    super.dispose();
  }
}
