import 'package:flutter/foundation.dart';

import '../core/constants/app_config.dart';
import '../core/utils/action_result.dart';
import '../data/datasources/local_storage.dart';
import '../data/datasources/deeplink_spec_source.dart';
import '../data/repositories/deeplink_repository.dart';
import '../services/spec_import_service.dart';

class SpecViewModel extends ChangeNotifier {
  SpecViewModel({
    required DeeplinkRepository deeplinkRepository,
    required SpecImportService importService,
    required LocalStorage storage,
  })  : _deeplinkRepository = deeplinkRepository,
        _importService = importService,
        _storage = storage;

  final DeeplinkRepository _deeplinkRepository;
  final SpecImportService _importService;
  final LocalStorage _storage;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  SpecOrigin get origin => _deeplinkRepository.origin;
  String get label => _deeplinkRepository.label;
  DateTime? get importedAt => _deeplinkRepository.importedAt;
  int get entryCount => _deeplinkRepository.count;
  bool get needsSpec => _deeplinkRepository.isExample;

  bool get exampleAccepted => _storage.flag(AppConfig.kExampleAcceptedKey);

  bool get shouldPromptForSpec => needsSpec && !exampleAccepted;

  Future<void> acceptExample() async {
    await _storage.setFlag(AppConfig.kExampleAcceptedKey, true);
    notifyListeners();
  }

  Future<ActionResult> importFromFile() => _run(_importService.pickAndImport());

  Future<ActionResult> importFromText(String raw, {String label = 'Pasted'}) =>
      _run(_importService.importRaw(raw, label: label));

  Future<ActionResult> _run(Future<SpecImportOutcome> action) async {
    if (_isBusy) return const ActionResult.none();

    _isBusy = true;
    notifyListeners();
    try {
      final SpecImportOutcome outcome = await action;
      if (outcome.loaded != null) {
        _deeplinkRepository.replace(outcome.loaded!);
      }
      return outcome.result;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
