class AppConfig {
  const AppConfig._();

  static const String specAssetPath = 'assets/spec/deeplink_spec.json';
  static const String exampleSpecAssetPath = 'assets/spec/example_spec.json';

  static const String kHistoryKey = 'linkx.history.v2';
  static const String kUsageKey = 'linkx.usage.v2';

  static const int historyLimit = 200;
  static const int topUsageLimit = 5;
}
