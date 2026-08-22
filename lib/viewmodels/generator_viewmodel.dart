import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/action_result.dart';
import '../data/models/deeplink_entry.dart';
import '../data/models/generated_link.dart';
import '../data/models/history_entry.dart';
import '../data/models/link_parameter.dart';
import '../data/models/parameter_requirement.dart';
import '../data/models/user_type.dart';
import '../data/repositories/deeplink_repository.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/usage_repository.dart';
import '../services/deeplink_form_service.dart';
import '../services/launcher_service.dart';
import '../services/link_builder_service.dart';
import '../services/qr_service.dart';
import '../services/share_service.dart';

class GeneratorViewModel extends ChangeNotifier {
  GeneratorViewModel({
    required DeeplinkFormService formService,
    required LinkBuilderService builder,
    required QrService qrService,
    required ShareService shareService,
    required LauncherService launcher,
    required DeeplinkRepository deeplinkRepository,
    required HistoryRepository historyRepository,
    required UsageRepository usageRepository,
  })  : _formService = formService,
        _builder = builder,
        _qrService = qrService,
        _shareService = shareService,
        _launcher = launcher,
        _deeplinkRepository = deeplinkRepository,
        _historyRepository = historyRepository,
        _usageRepository = usageRepository;

  final DeeplinkFormService _formService;
  final LinkBuilderService _builder;
  final QrService _qrService;
  final ShareService _shareService;
  final LauncherService _launcher;
  final DeeplinkRepository _deeplinkRepository;
  final HistoryRepository _historyRepository;
  final UsageRepository _usageRepository;

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
      _perform(LinkAction.generated, () async {
        await Clipboard.setData(ClipboardData(text: url));
        return const ActionResult.ok('Deeplink copied to the clipboard.');
      });

  Future<ActionResult> launch() => _perform(LinkAction.launched, () async {
        final LaunchResult result = await _launcher.launch(url);
        return result.isSuccess
            ? const ActionResult.ok('Opening the deeplink…')
            : ActionResult.error(result.message);
      });

  Future<ActionResult> shareUrl({Rect? origin}) =>
      _perform(LinkAction.shared, () async {
        final ShareResult result =
            await _shareService.shareUrl(_link!, origin: origin);
        return _fromShare(result, 'Deeplink shared.');
      });

  Future<ActionResult> shareQrImage({Rect? origin}) =>
      _perform(LinkAction.shared, () async {
        final ShareResult result =
            await _shareService.shareQrImage(_link!, origin: origin);
        return _fromShare(result, 'QR code shared.');
      });

  Future<ActionResult> saveQrToGallery() =>
      _perform(LinkAction.qrSaved, () async {
        final QrSaveResult result = await _qrService.saveToGallery(
          url,
          fileName: _fileNameForQr(),
        );
        return result.isSuccess
            ? ActionResult.ok(result.message)
            : ActionResult.error(result.message);
      });

  Future<ActionResult> _perform(
    LinkAction action,
    Future<ActionResult> Function() body,
  ) async {
    if (!hasLink) return _blocked();
    if (_isBusy) return const ActionResult.none();

    _isBusy = true;
    notifyListeners();
    try {
      final ActionResult result = await body();
      if (result.success && !result.silent) {
        await _historyRepository.add(_link!, action);
        await _usageRepository.increment(_entry?.id);
      }
      return result;
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

  ActionResult _fromShare(ShareResult result, String successMessage) {
    return switch (result.status) {
      ShareResultStatus.success => ActionResult.ok(successMessage),
      ShareResultStatus.dismissed => const ActionResult.none(),
      ShareResultStatus.unavailable => ActionResult.ok(successMessage),
    };
  }

  String _fileNameForQr() {
    final String slug = (_entry?.destinationPage ?? 'deeplink')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'linkx_qr_${slug}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
