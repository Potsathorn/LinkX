import 'package:flutter/material.dart';

import '../core/utils/action_result.dart';
import '../data/models/deeplink_entry.dart';
import '../data/models/generated_link.dart';
import '../data/models/history_entry.dart';
import '../data/models/link_parameter.dart';
import '../data/models/parameter_requirement.dart';
import '../data/models/user_type.dart';
import '../data/repositories/deeplink_repository.dart';
import '../services/deeplink_form_service.dart';
import '../services/link_action_runner.dart';
import '../services/link_builder_service.dart';

class GeneratorViewModel extends ChangeNotifier {
  GeneratorViewModel({
    required DeeplinkFormService formService,
    required LinkBuilderService builder,
    required LinkActionRunner runner,
    required DeeplinkRepository deeplinkRepository,
  })  : _formService = formService,
        _builder = builder,
        _runner = runner,
        _deeplinkRepository = deeplinkRepository {
    _deeplinkRepository.addListener(_onSpecChanged);
  }

  void _onSpecChanged() {
    if (_entry == null) return;
    if (_deeplinkRepository.byId(_entry!.id) == null) reset();
  }

  final DeeplinkFormService _formService;
  final LinkBuilderService _builder;
  final LinkActionRunner _runner;
  final DeeplinkRepository _deeplinkRepository;

  DeeplinkEntry? _entry;
  String _variant = '';
  List<LinkParameter> _parameters = <LinkParameter>[];
  UserType? _testedUserType;
  GeneratedLink? _link;
  LinkValidation _validation = LinkValidation.valid;
  bool _isBusy = false;

  DeeplinkEntry? get entry => _entry;
  String get variant => _variant;
  List<LinkParameter> get parameters =>
      List<LinkParameter>.unmodifiable(_parameters);
  UserType? get testedUserType => _testedUserType;
  LinkValidation get validation => _validation;
  bool get isBusy => _isBusy;
  GeneratedLink? get link => _link;
  String get url => _link?.url ?? '';

  bool get hasEntry => _entry != null;
  bool get hasLink => url.isNotEmpty && _validation.isValid;

  bool get isUserTypeAllowed =>
      _entry == null ||
      _testedUserType == null ||
      _entry!.allowsUserType(_testedUserType!);

  List<LinkParameter> get requiredParameters => _parameters
      .where(
          (LinkParameter p) => p.requirement == ParameterRequirement.required)
      .toList();

  List<LinkParameter> get conditionalParameters => _parameters
      .where((LinkParameter p) =>
          p.requirement == ParameterRequirement.conditional)
      .toList();

  List<LinkParameter> get optionalParameters => _parameters
      .where(
          (LinkParameter p) => p.requirement == ParameterRequirement.optional)
      .toList();

  List<LinkParameter> get missingParameters =>
      _parameters.where((LinkParameter p) => p.isMissing).toList();

  void loadEntry(DeeplinkEntry entry) {
    _entry = entry;
    _variant = entry.variants.first;
    _parameters = _formService.buildForm(entry, variant: _variant);
    _testedUserType =
        entry.allowedUserTypes.isEmpty ? null : entry.allowedUserTypes.first;
    _recompute();
  }

  void selectVariant(String variant) {
    if (_entry == null || _variant == variant) return;
    _variant = variant;
    _parameters = _formService.buildForm(
      _entry!,
      variant: variant,
      previous: _parameters,
    );
    _recompute();
  }

  void setTestedUserType(UserType? type) {
    if (_testedUserType == type) return;
    _testedUserType = type;
    _recompute();
  }

  void updateParameter(String name, String value) {
    _updateWhere(name, (LinkParameter p) => p.copyWith(value: value));
  }

  void toggleParameter(String name, bool enabled) {
    _updateWhere(name, (LinkParameter p) => p.copyWith(enabled: enabled));
  }

  void clearParameter(String name) {
    _updateWhere(name, (LinkParameter p) => p.copyWith(value: ''));
  }

  bool loadHistoryEntry(HistoryEntry historyEntry) {
    final DeeplinkEntry? entry =
        _deeplinkRepository.byId(historyEntry.link.entryId);
    if (entry == null) return false;

    _entry = entry;
    _variant = entry.variants.contains(historyEntry.link.pathPattern)
        ? historyEntry.link.pathPattern
        : entry.variants.first;
    _testedUserType = historyEntry.link.testedUserType;
    _parameters = _formService.buildForm(
      entry,
      variant: _variant,
      previous: historyEntry.link.parameters,
    );
    _recompute();
    return true;
  }

  void reset() {
    _entry = null;
    _variant = '';
    _parameters = <LinkParameter>[];
    _testedUserType = null;
    _link = null;
    _validation = LinkValidation.valid;
    notifyListeners();
  }

  void _updateWhere(
    String name,
    LinkParameter Function(LinkParameter) transform,
  ) {
    bool changed = false;
    _parameters = _parameters.map((LinkParameter p) {
      if (p.name != name) return p;
      changed = true;
      return transform(p);
    }).toList();
    if (changed) _recompute();
  }

  void _recompute() {
    final DeeplinkEntry? entry = _entry;
    if (entry == null) {
      _link = null;
      _validation = LinkValidation.valid;
      notifyListeners();
      return;
    }

    _validation = _builder.validate(
      entry: entry,
      variant: _variant,
      parameters: _parameters,
      testedUserType: _testedUserType,
    );
    _link = _builder.build(
      entry: entry,
      variant: _variant,
      parameters: _parameters,
      testedUserType: _testedUserType,
    );
    notifyListeners();
  }

  Future<ActionResult> copyToClipboard() =>
      _perform((GeneratedLink link) => _runner.copy(link));

  Future<ActionResult> launch() =>
      _perform((GeneratedLink link) => _runner.launch(link));

  Future<ActionResult> shareUrl({Rect? origin}) =>
      _perform((GeneratedLink link) => _runner.shareUrl(link, origin: origin));

  Future<ActionResult> shareQrImage({Rect? origin}) => _perform(
      (GeneratedLink link) => _runner.shareQrImage(link, origin: origin));

  Future<ActionResult> saveQrToGallery() =>
      _perform((GeneratedLink link) => _runner.saveQrToGallery(link));

  Future<ActionResult> _perform(
    Future<ActionResult> Function(GeneratedLink link) body,
  ) async {
    if (!hasLink) return _blocked();
    if (_isBusy) return const ActionResult.none();

    _isBusy = true;
    notifyListeners();
    try {
      return await body(_link!);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  ActionResult _blocked() {
    if (_entry == null) {
      return const ActionResult.error(
          'Pick a deeplink from the catalogue first.');
    }
    return ActionResult.error(
      _validation.errors.isNotEmpty
          ? _validation.errors.first
          : 'The deeplink is not ready yet.',
    );
  }

  @override
  void dispose() {
    _deeplinkRepository.removeListener(_onSpecChanged);
    super.dispose();
  }
}
