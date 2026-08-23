import 'package:flutter/foundation.dart';

@immutable
class OneLinkEnvironment {
  const OneLinkEnvironment({
    required this.env,
    required this.afDevKey,
    required this.afAppleId,
    required this.afOneLinkId,
  });

  final String env;
  final String afDevKey;
  final String afAppleId;
  final String afOneLinkId;

  bool get isUsable =>
      env.isNotEmpty && afDevKey.isNotEmpty && afOneLinkId.isNotEmpty;

  factory OneLinkEnvironment.fromJson(Map<String, dynamic> json) =>
      OneLinkEnvironment(
        env: (json['env'] as String? ?? '').trim().toUpperCase(),
        afDevKey: (json['afDevKey'] as String? ?? '').trim(),
        afAppleId: (json['afAppleId'] as String? ?? '').trim(),
        afOneLinkId: (json['afOneLinkId'] as String? ?? '').trim(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OneLinkEnvironment &&
          other.env == env &&
          other.afOneLinkId == afOneLinkId;

  @override
  int get hashCode => Object.hash(env, afOneLinkId);
}

@immutable
class OneLinkConfig {
  const OneLinkConfig({required this.environments});

  static const OneLinkConfig empty = OneLinkConfig(
    environments: <OneLinkEnvironment>[],
  );

  static const Set<String> supportedEnvironments = <String>{'SIT', 'UAT'};

  final List<OneLinkEnvironment> environments;

  bool get isAvailable => environments.isNotEmpty;

  OneLinkEnvironment? byName(String env) {
    final String target = env.trim().toUpperCase();
    for (final OneLinkEnvironment option in environments) {
      if (option.env == target) return option;
    }
    return null;
  }

  factory OneLinkConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;

    final List<dynamic> options =
        json['afOption'] as List<dynamic>? ?? <dynamic>[];

    return OneLinkConfig(
      environments: options
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> e) =>
              OneLinkEnvironment.fromJson(Map<String, dynamic>.from(e)))
          .where((OneLinkEnvironment e) =>
              e.isUsable && supportedEnvironments.contains(e.env))
          .toList(),
    );
  }
}

@immutable
class GeneratedOneLink {
  const GeneratedOneLink({
    required this.env,
    required this.deeplink,
    required this.url,
    required this.createdAt,
  });

  final String env;
  final String deeplink;
  final String url;
  final DateTime createdAt;

  bool matches(String env, String deeplink) =>
      this.env == env.trim().toUpperCase() && this.deeplink == deeplink.trim();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'env': env,
        'deeplink': deeplink,
        'url': url,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeneratedOneLink.fromJson(Map<String, dynamic> json) =>
      GeneratedOneLink(
        env: json['env'] as String? ?? '',
        deeplink: json['deeplink'] as String? ?? '',
        url: json['url'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
