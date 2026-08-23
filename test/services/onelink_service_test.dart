import 'package:flutter_test/flutter_test.dart';
import 'package:linkx/data/datasources/local_storage.dart';
import 'package:linkx/data/models/onelink_config.dart';
import 'package:linkx/data/repositories/onelink_repository.dart';
import 'package:linkx/services/onelink_gateway.dart';
import 'package:linkx/services/onelink_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../spec_fixture.dart';

class _FakeGateway implements OneLinkGateway {
  _FakeGateway({this.failure});

  final String? failure;
  int calls = 0;
  final List<Map<String, String>> received = <Map<String, String>>[];
  final List<OneLinkEnvironment> environments = <OneLinkEnvironment>[];

  @override
  Future<String> generate({
    required OneLinkEnvironment environment,
    required Map<String, String> customParams,
  }) async {
    calls++;
    received.add(customParams);
    environments.add(environment);
    if (failure != null) throw OneLinkGatewayException(failure!);
    return 'https://demo.onelink.me/${environment.afOneLinkId}/call$calls';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OneLinkRepository repository;
  late _FakeGateway gateway;
  late OneLinkService service;

  final OneLinkConfig config = loadFixtureSpec().oneLink;
  const String deeplink = 'cardx://deeplink/inbox?folder=alpha';

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferences.resetStatic();
    LocalStorage.resetForTesting();

    repository = OneLinkRepository(await LocalStorage.getInstance());
    gateway = _FakeGateway();
    service = OneLinkService(gateway: gateway, repository: repository);
  });

  group('config parsing', () {
    test('keeps only SIT and UAT', () {
      expect(config.environments.map((OneLinkEnvironment e) => e.env),
          <String>['SIT', 'UAT']);
      expect(config.byName('PROD'), isNull);
      expect(config.byName('sit')?.afOneLinkId, 'fxSI');
    });
  });

  group('eligibility', () {
    test('accepts only a cardx deeplink', () {
      expect(OneLinkService.isEligible(deeplink), isTrue);
      expect(OneLinkService.isEligible('https://example.com'), isFalse);
      expect(OneLinkService.isEligible('cardx://other/path'), isFalse);
    });

    test('rejects a link that is not a deeplink', () async {
      final OneLinkOutcome outcome = await service.generate(
        config: config,
        deeplink: 'https://example.com',
        env: 'SIT',
      );
      expect(outcome.isSuccess, isFalse);
      expect(outcome.rejection, OneLinkRejection.notADeeplink);
      expect(gateway.calls, 0);
    });

    test('rejects when no environment is chosen', () async {
      final OneLinkOutcome outcome =
          await service.generate(config: config, deeplink: deeplink, env: null);
      expect(outcome.rejection, OneLinkRejection.noEnvironment);
      expect(gateway.calls, 0);
    });

    test('rejects an unsupported environment', () async {
      final OneLinkOutcome outcome = await service.generate(
        config: config,
        deeplink: deeplink,
        env: 'PROD',
      );
      expect(outcome.rejection, OneLinkRejection.unknownEnvironment);
      expect(gateway.calls, 0);
    });

    test('rejects when the spec has no onelink block', () async {
      final OneLinkOutcome outcome = await service.generate(
        config: OneLinkConfig.empty,
        deeplink: deeplink,
        env: 'SIT',
      );
      expect(outcome.rejection, OneLinkRejection.noConfig);
      expect(gateway.calls, 0);
    });
  });

  group('generation', () {
    test('sends exactly the required custom params', () async {
      await service.generate(config: config, deeplink: deeplink, env: 'SIT');

      expect(gateway.received.single, <String, String>{
        'af_dp': deeplink,
        'af_force_deeplink': 'true',
        'openExternalBrowser': '1',
      });
      expect(gateway.environments.single.afOneLinkId, 'fxSI');
    });

    test('returns the generated link', () async {
      final OneLinkOutcome outcome = await service.generate(
          config: config, deeplink: deeplink, env: 'SIT');

      expect(outcome.isSuccess, isTrue);
      expect(outcome.cached, isFalse);
      expect(outcome.link!.env, 'SIT');
      expect(outcome.link!.url, contains('fxSI'));
    });

    test('surfaces a gateway failure without caching it', () async {
      service = OneLinkService(
        gateway: _FakeGateway(failure: 'network down'),
        repository: repository,
      );

      final OneLinkOutcome outcome = await service.generate(
          config: config, deeplink: deeplink, env: 'SIT');

      expect(outcome.isSuccess, isFalse);
      expect(outcome.message, contains('network down'));
      expect(repository.loadAll(), isEmpty);
    });
  });

  group('cache', () {
    test('reuses a link for the same deeplink and environment', () async {
      final OneLinkOutcome first = await service.generate(
          config: config, deeplink: deeplink, env: 'SIT');
      final OneLinkOutcome second = await service.generate(
          config: config, deeplink: deeplink, env: 'SIT');

      expect(gateway.calls, 1);
      expect(second.cached, isTrue);
      expect(second.link!.url, first.link!.url);
      expect(second.message, contains('Reused'));
    });

    test('generates again for a different environment', () async {
      await service.generate(config: config, deeplink: deeplink, env: 'SIT');
      final OneLinkOutcome uat = await service.generate(
          config: config, deeplink: deeplink, env: 'UAT');

      expect(gateway.calls, 2);
      expect(uat.cached, isFalse);
      expect(uat.link!.url, contains('fxUA'));
    });

    test('generates again for a different deeplink', () async {
      await service.generate(config: config, deeplink: deeplink, env: 'SIT');
      await service.generate(
        config: config,
        deeplink: 'cardx://deeplink/settings',
        env: 'SIT',
      );

      expect(gateway.calls, 2);
      expect(repository.loadAll(), hasLength(2));
    });

    test('survives a repository reload', () async {
      await service.generate(config: config, deeplink: deeplink, env: 'SIT');

      final OneLinkRepository reopened =
          OneLinkRepository(await LocalStorage.getInstance());
      expect(reopened.find(env: 'SIT', deeplink: deeplink), isNotNull);
    });

    test('ignores surrounding whitespace when matching', () async {
      await service.generate(config: config, deeplink: deeplink, env: 'SIT');
      final OneLinkOutcome outcome = await service.generate(
        config: config,
        deeplink: '  $deeplink  ',
        env: 'sit',
      );

      expect(gateway.calls, 1);
      expect(outcome.cached, isTrue);
    });
  });
}
