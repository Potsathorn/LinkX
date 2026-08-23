import '../core/constants/app_config.dart';
import '../data/models/onelink_config.dart';
import '../data/repositories/onelink_repository.dart';
import 'onelink_gateway.dart';

enum OneLinkRejection {
  noConfig('The loaded spec has no AppsFlyer OneLink configuration.'),
  emptyLink('Enter a deeplink first.'),
  notADeeplink('OneLink generation only works for links that start with '
      '${AppConfig.deeplinkPrefix}.'),
  noEnvironment('Choose SIT or UAT before generating.'),
  notReady('Finish the deeplink first — Launch is still disabled.'),
  unknownEnvironment('That environment is not in the spec.');

  const OneLinkRejection(this.message);
  final String message;
}

class OneLinkOutcome {
  const OneLinkOutcome._(
      {this.link, this.rejection, this.error, this.cached = false});

  const OneLinkOutcome.generated(GeneratedOneLink link) : this._(link: link);

  const OneLinkOutcome.reused(GeneratedOneLink link)
      : this._(link: link, cached: true);

  const OneLinkOutcome.rejected(OneLinkRejection rejection)
      : this._(rejection: rejection);

  const OneLinkOutcome.failed(String error) : this._(error: error);

  final GeneratedOneLink? link;
  final OneLinkRejection? rejection;
  final String? error;
  final bool cached;

  bool get isSuccess => link != null;

  String get message {
    if (rejection != null) return rejection!.message;
    if (error != null) return error!;
    return cached
        ? 'Reused the OneLink generated earlier for this deeplink.'
        : 'OneLink generated.';
  }
}

class OneLinkService {
  const OneLinkService({
    required OneLinkGateway gateway,
    required OneLinkRepository repository,
  })  : _gateway = gateway,
        _repository = repository;

  final OneLinkGateway _gateway;
  final OneLinkRepository _repository;

  static bool isEligible(String link) =>
      link.trim().startsWith(AppConfig.deeplinkPrefix);

  Map<String, String> customParamsFor(String deeplink) => <String, String>{
        'af_dp': deeplink.trim(),
        'af_force_deeplink': 'true',
        'openExternalBrowser': '1',
      };

  Future<OneLinkOutcome> generate({
    required OneLinkConfig config,
    required String deeplink,
    required String? env,
  }) async {
    final String link = deeplink.trim();

    if (!config.isAvailable) {
      return const OneLinkOutcome.rejected(OneLinkRejection.noConfig);
    }
    if (link.isEmpty) {
      return const OneLinkOutcome.rejected(OneLinkRejection.emptyLink);
    }
    if (!isEligible(link)) {
      return const OneLinkOutcome.rejected(OneLinkRejection.notADeeplink);
    }
    if (env == null || env.isEmpty) {
      return const OneLinkOutcome.rejected(OneLinkRejection.noEnvironment);
    }

    final OneLinkEnvironment? environment = config.byName(env);
    if (environment == null) {
      return const OneLinkOutcome.rejected(OneLinkRejection.unknownEnvironment);
    }

    final GeneratedOneLink? cached =
        _repository.find(env: environment.env, deeplink: link);
    if (cached != null) return OneLinkOutcome.reused(cached);

    try {
      final String url = await _gateway.generate(
        environment: environment,
        customParams: customParamsFor(link),
      );

      final GeneratedOneLink generated = GeneratedOneLink(
        env: environment.env,
        deeplink: link,
        url: url,
        createdAt: DateTime.now(),
      );
      await _repository.save(generated);
      return OneLinkOutcome.generated(generated);
    } on OneLinkGatewayException catch (e) {
      return OneLinkOutcome.failed(e.message);
    } catch (e) {
      return OneLinkOutcome.failed('Could not generate the OneLink: $e');
    }
  }
}
