import 'package:flutter/material.dart';

import '../data/models/onelink_config.dart';
import '../data/repositories/deeplink_repository.dart';
import '../services/onelink_service.dart';

class OneLinkViewModel extends ChangeNotifier {
  OneLinkViewModel({
    required OneLinkService service,
    required DeeplinkRepository deeplinkRepository,
    required TextEditingController sourceController,
  })  : _service = service,
        _deeplinkRepository = deeplinkRepository,
        _sourceController = sourceController {
    _deeplinkRepository.addListener(_onSpecChanged);
    _sourceController.addListener(_onSourceChanged);
    _source = _sourceController.text.trim();
  }

  final OneLinkService _service;
  final DeeplinkRepository _deeplinkRepository;
  final TextEditingController _sourceController;

  String _source = '';
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

  bool get isEligible => OneLinkService.isEligible(_source);
  bool get canGenerate =>
      isConfigured && isEligible && _env != null && !_isBusy;

  Map<String, String> get previewParams => _service.customParamsFor(_source);

  void _onSourceChanged() {
    final String next = _sourceController.text.trim();
    if (_source == next) return;

    _source = next;
    _outcome = null;
    notifyListeners();
  }

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

    _isBusy = true;
    notifyListeners();
    try {
      final OneLinkOutcome result = await _service.generate(
        config: config,
        deeplink: _source,
        env: _env,
      );
      _outcome = result;
      return result;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _onSpecChanged() {
    _env = null;
    _outcome = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _deeplinkRepository.removeListener(_onSpecChanged);
    _sourceController.removeListener(_onSourceChanged);
    super.dispose();
  }
}
