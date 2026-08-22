import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum LaunchStatus { launched, invalidUrl, noHandler, failed }

@immutable
class LaunchResult {
  const LaunchResult(this.status, this.message);
  final LaunchStatus status;
  final String message;

  bool get isSuccess => status == LaunchStatus.launched;
}

class LauncherService {
  const LauncherService();

  Future<LaunchResult> launch(String url) async {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const LaunchResult(LaunchStatus.invalidUrl, 'The link is empty.');
    }

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return LaunchResult(
        LaunchStatus.invalidUrl,
        'Not a valid URL: $trimmed',
      );
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return const LaunchResult(LaunchStatus.launched, 'Link launched.');
      }
      return LaunchResult(
        LaunchStatus.noHandler,
        'Nothing on this device can open "${uri.scheme}://" — is CardX installed?',
      );
    } catch (e) {
      return LaunchResult(
        LaunchStatus.failed,
        'Could not open the link: $e',
      );
    }
  }
}
