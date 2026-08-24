import 'package:flutter/foundation.dart';

import '../data/models/onelink_config.dart';
import '../data/repositories/deeplink_repository.dart';
import '../services/onelink_service.dart';

class OneLinkViewModel extends ChangeNotifier {
  OneLinkViewModel({
    required OneLinkService service,
    required DeeplinkRepository deeplinkRepository,
    required Listenable source,
    required String Function() readSource,
    required bool Function() readReady,
  })  : _service = service,
        _deeplinkRepository = deeplinkRepository,
        _source = source,
        _readSource = readSource,
        _readReady = readReady {
    _deeplinkRepository.addListener(_onSpecChanged);
    _source.addListener(_onSourceChanged);
    _link = _readSource().trim();
  }

  final OneLinkService _service;
  final DeeplinkRepository _deeplinkRepository;
  final Listenable _source;
  final String Function() _readSource;
  final bool Function() _readReady;

  String _link = '';
  String? _env;
  bool _isBusy = false;
  OneLinkOutcome? _outcome;

  OneLinkConfig get config => _deeplinkRepository.oneLink;
  bool get isConfigured => config.isAvailable;
  List<OneLinkEnvironment> get environments => config.environments;

  String? get env => _env;
  bool get isBusy => _isBusy;
  OneLinkOutcome? get outcome => _outcome;

  GeneratedOneLink? get generated => _outcome?.link;
  bool get wasReused => _outcome?.cached ?? false;
  String? get error =>
      _outcome != null && !_outcome!.isSuccess ? _outcome!.message : null;

  bool get isSourceReady => _readReady();
  bool get isEligible => isSourceReady && OneLinkService.isEligible(_link);
  bool get canGenerate =>
      isConfigured && isEligible && _env != null && !_isBusy;

  void selectEnvironment(String? value) {
    if (_env == value) return;

    _env = value;
    _outcome = null;
    notifyListeners();
  }

  Future<OneLinkOutcome> generate() async {
    if (_isBusy) {
      return const OneLinkOutcome.rejected(OneLinkRejection.noEnvironment);
    }
    if (!isSourceReady) {
      return const OneLinkOutcome.rejected(OneLinkRejection.notReady);
    }

    _isBusy = true;
    notifyListeners();
    try {
      final OneLinkOutcome result = await _service.generate(
        config: config,
        deeplink: _link,
        env: _env,
      );
      _outcome = result;
      return result;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _onSourceChanged() {
    final String next = _readSource().trim();
    if (_link == next) {
      notifyListeners();
      return;
    }

    _link = next;
    _outcome = null;
    notifyListeners();
  }

  void _onSpecChanged() {
    _env = null;
    _outcome = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _deeplinkRepository.removeListener(_onSpecChanged);
    _source.removeListener(_onSourceChanged);
    super.dispose();
  }
}

class GeneratorOneLinkViewModel extends OneLinkViewModel {
  GeneratorOneLinkViewModel({
    required super.service,
    required super.deeplinkRepository,
    required super.source,
    required super.readSource,
    required super.readReady,
  });
}
