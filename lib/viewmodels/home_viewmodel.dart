import 'package:flutter/material.dart';

import '../core/utils/action_result.dart';
import '../data/models/deeplink_entry.dart';
import '../data/models/generated_link.dart';
import '../data/models/history_entry.dart';
import '../data/repositories/deeplink_repository.dart';
import '../data/repositories/history_repository.dart';
import '../services/link_action_runner.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required LinkActionRunner runner,
    required DeeplinkRepository deeplinkRepository,
    required HistoryRepository historyRepository,
  })  : _runner = runner,
        _deeplinkRepository = deeplinkRepository,
        _historyRepository = historyRepository {
    linkController.addListener(_onLinkChanged);
    _historyRepository.addListener(_reloadRecent);
    _deeplinkRepository.addListener(notifyListeners);
    _reloadRecent();
  }

  static const int recentLimit = 5;
  static const int topRankLimit = 3;

  final LinkActionRunner _runner;
  final DeeplinkRepository _deeplinkRepository;
  final HistoryRepository _historyRepository;

  final TextEditingController linkController = TextEditingController();

  static final RegExp _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

  List<HistoryEntry> _recent = <HistoryEntry>[];
  bool _isBusy = false;

  bool get isBusy => _isBusy;
  String get rawLink => linkController.text.trim();
  bool get isEmpty => rawLink.isEmpty;
  bool get isValid => _schemePattern.hasMatch(rawLink);
  bool get canLaunch => isValid && !_isBusy;

  String? get validationMessage {
    if (isEmpty || isValid) return null;
    return 'Start the link with a scheme, for example cardx:// or https://';
  }

  GeneratedLink get link => GeneratedLink.adHoc(rawLink);

  List<HistoryEntry> get recent => _recent;
  bool get hasRecent => _recent.isNotEmpty;

  List<DeeplinkEntry> get topRanked => _deeplinkRepository.all
      .where((DeeplinkEntry e) => e.rank <= topRankLimit)
      .toList();

  void setLink(String value) {
    if (linkController.text == value) return;
    linkController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void clear() => setLink('');

  Future<ActionResult> launch() =>
      _perform((GeneratedLink l) => _runner.launch(l));

  Future<ActionResult> copy() => _perform((GeneratedLink l) => _runner.copy(l));

  Future<ActionResult> shareUrl({Rect? origin}) =>
      _perform((GeneratedLink l) => _runner.shareUrl(l, origin: origin));

  Future<ActionResult> relaunch(HistoryEntry entry) async {
    if (_isBusy) return const ActionResult.none();

    _isBusy = true;
    notifyListeners();
    try {
      return await _runner.launch(entry.link);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<ActionResult> _perform(
    Future<ActionResult> Function(GeneratedLink link) body,
  ) async {
    if (isEmpty) {
      return const ActionResult.error('Paste a link to test first.');
    }
    if (!isValid) {
      return ActionResult.error(validationMessage!);
    }
    if (_isBusy) return const ActionResult.none();

    _isBusy = true;
    notifyListeners();
    try {
      return await body(link);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _onLinkChanged() => notifyListeners();

  void _reloadRecent() {
    _recent = _historyRepository.loadAll().take(recentLimit).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    linkController
      ..removeListener(_onLinkChanged)
      ..dispose();
    _historyRepository.removeListener(_reloadRecent);
    _deeplinkRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
