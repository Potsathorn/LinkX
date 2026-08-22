import 'package:flutter_test/flutter_test.dart';
import 'package:linkx_tester/core/utils/action_result.dart';
import 'package:linkx_tester/data/datasources/local_storage.dart';
import 'package:linkx_tester/data/models/deeplink_entry.dart';
import 'package:linkx_tester/data/models/history_entry.dart';
import 'package:linkx_tester/data/models/link_parameter.dart';
import 'package:linkx_tester/data/models/user_type.dart';
import 'package:linkx_tester/data/repositories/deeplink_repository.dart';
import 'package:linkx_tester/data/repositories/history_repository.dart';
import 'package:linkx_tester/data/repositories/usage_repository.dart';
import 'package:linkx_tester/services/deeplink_form_service.dart';
import 'package:linkx_tester/services/launcher_service.dart';
import 'package:linkx_tester/services/link_action_runner.dart';
import 'package:linkx_tester/services/link_builder_service.dart';
import 'package:linkx_tester/services/qr_service.dart';
import 'package:linkx_tester/services/share_service.dart';
import 'package:linkx_tester/viewmodels/catalogue_viewmodel.dart';
import 'package:linkx_tester/viewmodels/generator_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../spec_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HistoryRepository historyRepository;
  late UsageRepository usageRepository;
  late DeeplinkRepository deeplinkRepository;
  late LinkActionRunner runner;
  late GeneratorViewModel vm;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferences.resetStatic();
    LocalStorage.resetForTesting();

    final LocalStorage storage = await LocalStorage.getInstance();
    historyRepository = HistoryRepository(storage);
    usageRepository = UsageRepository(storage);
    deeplinkRepository = DeeplinkRepository(fixtureSpec());

    runner = LinkActionRunner(
      qrService: const QrService(),
      shareService: const ShareService(QrService()),
      launcher: const LauncherService(),
      historyRepository: historyRepository,
      usageRepository: usageRepository,
    );

    vm = GeneratorViewModel(
      formService: const DeeplinkFormService(),
      builder: const LinkBuilderService(),
      runner: runner,
      deeplinkRepository: deeplinkRepository,
    );
  });

  tearDown(() => vm.dispose());

  group('loading an entry', () {
    test('builds the form and defaults the user type to the first allowed', () {
      vm.loadEntry(entryByPattern('/inbox?folder='));

      expect(vm.hasEntry, isTrue);
      expect(
          vm.variant, 'demoapp://deeplink/inbox?folder={folder}&view={view}');
      expect(vm.parameters, hasLength(6));
      expect(vm.testedUserType, UserType.etu);
      expect(vm.url, 'demoapp://deeplink/inbox');
    });

    test('a conditional deeplink is not ready until one value is set', () {
      vm.loadEntry(entryByPattern('/inbox?folder='));
      expect(vm.hasLink, isFalse);

      vm.updateParameter('view', 'compact');
      expect(vm.hasLink, isTrue);
      expect(vm.url, 'demoapp://deeplink/inbox?view=compact');
    });

    test('a required deeplink reports the missing parameter', () {
      vm.loadEntry(entryByPattern('/offer-detail'));

      expect(vm.hasLink, isFalse);
      expect(vm.missingParameters.single.name, 'offerCode');

      vm.updateParameter('offerCode', 'OFFER26');
      expect(vm.hasLink, isTrue);
      expect(vm.url, 'demoapp://deeplink/offer-detail?offerCode=OFFER26');
    });

    test('a parameterless deeplink is immediately ready', () {
      vm.loadEntry(entryByPattern('/profile/addresses'));

      expect(vm.parameters, isEmpty);
      expect(vm.hasLink, isTrue);
      expect(vm.url, 'demoapp://deeplink/profile/addresses');
    });

    test('groups parameters by requirement', () {
      vm.loadEntry(entryByPattern('/catalog?groupCode='));

      expect(vm.requiredParameters.map((LinkParameter p) => p.name),
          <String>['groupCode', 'itemCode', 'variantCode']);
      expect(vm.conditionalParameters, isEmpty);
      expect(vm.optionalParameters, hasLength(4));
    });

    test('loading another entry resets the previous values', () {
      vm.loadEntry(entryByPattern('/offer-detail'));
      vm.updateParameter('offerCode', 'X');

      vm.loadEntry(entryByPattern('/resume-task'));
      expect(vm.parameters.single.name, 'taskId');
      expect(vm.parameters.single.hasValue, isFalse);
    });
  });

  group('allowed values', () {
    test('a value outside allowed_values_in_code blocks generation', () {
      vm.loadEntry(entryByPattern('/inbox?folder='));
      vm.updateParameter('folder', 'gold');

      expect(vm.hasLink, isFalse);
      expect(vm.validation.errors.single, contains('gold'));
    });

    test('an allowed value passes', () {
      vm.loadEntry(entryByPattern('/inbox?folder='));
      vm.updateParameter('folder', 'beta');

      expect(vm.hasLink, isTrue);
    });
  });

  group('user type', () {
    test('flags a user type outside the allowed list', () {
      vm.loadEntry(entryByPattern('/preferences'));
      vm.setTestedUserType(UserType.nta);

      expect(vm.isUserTypeAllowed, isFalse);
      expect(vm.validation.warnings.first, contains('NTA'));
      expect(vm.hasLink, isTrue);
    });

    test('an allowed user type raises no flag', () {
      vm.loadEntry(entryByPattern('/preferences'));
      vm.setTestedUserType(UserType.etu);

      expect(vm.isUserTypeAllowed, isTrue);
    });
  });

  group('variants', () {
    test('selecting a variant rebuilds the url', () {
      vm.loadEntry(entryByPattern('/feed-list'));
      expect(vm.url, 'demoapp://deeplink/feed-list');

      vm.selectVariant('demoapp://deeplink/feed');
      expect(vm.url, 'demoapp://deeplink/feed');
    });
  });

  group('parameter toggles', () {
    test('an optional parameter can be excluded', () {
      vm.loadEntry(entryByPattern('/inbox?folder='));
      vm.updateParameter('view', 'compact');
      vm.updateParameter('refId', '55');
      expect(vm.url, contains('refId=55'));

      vm.toggleParameter('refId', false);
      expect(vm.url, isNot(contains('refId')));
      expect(vm.parameters, hasLength(6));
    });
  });

  group('actions', () {
    test('copying logs history and bumps the usage counter', () async {
      final DeeplinkEntry entry = entryByPattern('/offer-detail');
      vm.loadEntry(entry);
      vm.updateParameter('offerCode', 'OFFER26');

      final ActionResult result = await vm.copyToClipboard();

      expect(result.success, isTrue);
      expect(historyRepository.loadAll(), hasLength(1));
      expect(historyRepository.loadAll().single.action, LinkAction.generated);
      expect(usageRepository.loadMap()[entry.id]?.count, 1);
    });

    test('an incomplete deeplink is blocked and nothing is logged', () async {
      vm.loadEntry(entryByPattern('/offer-detail'));

      final ActionResult result = await vm.copyToClipboard();

      expect(result.success, isFalse);
      expect(result.message, contains('offerCode'));
      expect(historyRepository.loadAll(), isEmpty);
    });

    test('acting with no entry selected is blocked', () async {
      final ActionResult result = await vm.copyToClipboard();

      expect(result.success, isFalse);
      expect(result.message, contains('catalogue'));
    });
  });

  group('history round-trip', () {
    test('re-opening restores entry, variant, user type and values', () async {
      vm.loadEntry(entryByPattern('/inbox?folder='));
      vm.updateParameter('folder', 'alpha');
      vm.updateParameter('view', 'detail');
      vm.setTestedUserType(UserType.etu);
      await vm.copyToClipboard();

      final HistoryEntry logged = historyRepository.loadAll().single;
      final String originalUrl = vm.url;

      vm.reset();
      expect(vm.hasEntry, isFalse);

      expect(vm.loadHistoryEntry(logged), isTrue);
      expect(vm.url, originalUrl);
      expect(vm.testedUserType, UserType.etu);
      expect(
        vm.parameters.firstWhere((LinkParameter p) => p.name == 'view').value,
        'detail',
      );
    });

    test('an entry no longer in the spec cannot be restored', () {
      final DeeplinkEntry entry = entryByPattern('/offer-detail');
      vm.loadEntry(entry);
      vm.updateParameter('offerCode', 'X');

      final GeneratorViewModel isolated = GeneratorViewModel(
        formService: const DeeplinkFormService(),
        builder: const LinkBuilderService(),
        runner: runner,
        deeplinkRepository: DeeplinkRepository(emptySpec),
      );
      addTearDown(isolated.dispose);

      final HistoryEntry fake = HistoryEntry(
        id: 'x',
        link: vm.link!,
        action: LinkAction.generated,
        timestamp: DateTime.now(),
      );
      expect(isolated.loadHistoryEntry(fake), isFalse);
    });
  });

  group('catalogue view model', () {
    test('usage recorded in the generator surfaces in most used', () async {
      final CatalogueViewModel catalogue = CatalogueViewModel(
        deeplinkRepository: deeplinkRepository,
        usageRepository: usageRepository,
      );
      addTearDown(catalogue.dispose);

      expect(catalogue.mostUsed, isEmpty);
      expect(catalogue.totalCount, 13);

      final DeeplinkEntry entry = entryByPattern('/offer-detail');
      vm.loadEntry(entry);
      vm.updateParameter('offerCode', 'OFFER26');
      await vm.copyToClipboard();

      expect(catalogue.mostUsed, hasLength(1));
      expect(catalogue.mostUsed.single.entry.id, entry.id);
      expect(catalogue.usageCount(entry.id), 1);
    });
  });
}
