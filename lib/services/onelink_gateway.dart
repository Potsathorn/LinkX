import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';

import '../data/models/onelink_config.dart';

class OneLinkGatewayException implements Exception {
  const OneLinkGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class OneLinkGateway {
  Future<String> generate({
    required OneLinkEnvironment environment,
    required Map<String, String> customParams,
  });
}

class AppsFlyerOneLinkGateway implements OneLinkGateway {
  AppsFlyerOneLinkGateway({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  AppsflyerSdk? _sdk;
  String? _initialisedDevKey;
  String? _activeOneLinkId;

  @override
  Future<String> generate({
    required OneLinkEnvironment environment,
    required Map<String, String> customParams,
  }) async {
    final AppsflyerSdk sdk = await _sdkFor(environment);
    await _selectOneLinkTemplate(sdk, environment);

    final Completer<String> completer = Completer<String>();

    sdk.generateInviteLink(
      AppsFlyerInviteLinkParams(customParams: customParams),
      (dynamic result) {
        if (completer.isCompleted) return;
        final String? url = _readUrl(result);
        if (url == null || url.isEmpty) {
          completer.completeError(
            const OneLinkGatewayException(
              'AppsFlyer returned a response without a link.',
            ),
          );
        } else {
          completer.complete(url);
        }
      },
      (dynamic error) {
        if (completer.isCompleted) return;
        completer.completeError(
          OneLinkGatewayException('AppsFlyer rejected the request: $error'),
        );
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () => throw OneLinkGatewayException(
        'AppsFlyer did not answer within ${timeout.inSeconds}s.',
      ),
    );
  }

  Future<AppsflyerSdk> _sdkFor(OneLinkEnvironment environment) async {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: environment.afDevKey,
      appId: environment.afAppleId,
      appInviteOneLink: environment.afOneLinkId,
      showDebug: false,
    );

    final AppsflyerSdk sdk = _sdk ??= AppsflyerSdk(options);

    if (_initialisedDevKey != environment.afDevKey) {
      sdk.afOptions = options;
      await sdk.initSdk(
        registerConversionDataCallback: false,
        registerOnAppOpenAttributionCallback: false,
        registerOnDeepLinkingCallback: false,
      );
      _initialisedDevKey = environment.afDevKey;
      _activeOneLinkId = environment.afOneLinkId;
    }
    return sdk;
  }

  Future<void> _selectOneLinkTemplate(
    AppsflyerSdk sdk,
    OneLinkEnvironment environment,
  ) async {
    if (_activeOneLinkId == environment.afOneLinkId) return;

    await sdk.setAppInviteOneLinkID(environment.afOneLinkId, (dynamic _) {});
    _activeOneLinkId = environment.afOneLinkId;
  }

  String? _readUrl(dynamic result) {
    if (result is String) return result;
    if (result is Map) {
      final dynamic payload = result['payload'] ?? result;
      if (payload is Map) {
        return (payload['userInviteURL'] ?? payload['link'] ?? payload['url'])
            ?.toString();
      }
      return payload?.toString();
    }
    return result?.toString();
  }
}
