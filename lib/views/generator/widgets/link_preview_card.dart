import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/link_builder_service.dart';
import '../../widgets/share_origin.dart';

class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({
    super.key,
    required this.url,
    required this.validation,
    required this.onCopy,
    required this.onShare,
    required this.onLaunch,
    required this.onQr,
    this.onOneLink,
    this.isOneLinkEnabled = false,
    this.isBusy = false,
  });

  final String url;
  final LinkValidation validation;
  final VoidCallback onCopy;
  final void Function(Rect? origin) onShare;
  final VoidCallback onLaunch;
  final VoidCallback onQr;
  final VoidCallback? onOneLink;
  final bool isOneLinkEnabled;
  final bool isBusy;

  bool get _isValid => validation.isValid && url.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final Color accent = _isValid ? Palette.white : Palette.amber;
    final bool enabled = _isValid && !isBusy;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.glow(accent, blur: 24, opacity: 0.12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.navy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(accent),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (url.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 11),
                        decoration: BoxDecoration(
                          color: Palette.black,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Palette.navyLine),
                        ),
                        child: SelectableText.rich(
                          _colorize(context, url),
                          style: AppTheme.mono(context, size: 12),
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final String error in validation.errors)
                      _Message(
                          icon: Icons.close, text: error, color: Palette.amber),
                    for (final String warning in validation.warnings)
                      _Message(
                        icon: Icons.warning_amber_rounded,
                        text: warning,
                        color: Palette.grey,
                      ),
                  ],
                ),
              ),
            ),
            _actions(enabled),
          ],
        ),
      ),
    );
  }

  Widget _header(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: AppTheme.glow(accent, blur: 8, opacity: 0.9),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _isValid ? 'Generated link' : 'Link not ready',
              style: AppTheme.hudLabel(color: accent, size: 10.5),
            ),
          ),
          if (url.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Copy link (logged to history)',
              icon: const Icon(Icons.copy_all_outlined, size: 17),
              color: accent,
              onPressed: onCopy,
            ),
          if (_isValid)
            Builder(
              builder: (BuildContext buttonContext) => IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Share the deeplink',
                icon: const Icon(Icons.share, size: 17),
                color: accent,
                onPressed:
                    isBusy ? null : () => onShare(shareOriginOf(buttonContext)),
              ),
            ),
          if (_isValid)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'QR code for the link',
              icon: const Icon(Icons.qr_code_2, size: 17),
              color: accent,
              onPressed: onQr,
            ),
        ],
      ),
    );
  }

  Widget _actions(bool enabled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: enabled
                    ? AppTheme.glow(Palette.amber, blur: 18, opacity: 0.4)
                    : null,
              ),
              child: FilledButton.icon(
                onPressed: enabled ? onLaunch : null,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_outlined, size: 18),
                label: const Text('Launch'),
              ),
            ),
          ),
          if (onOneLink != null) ...<Widget>[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOneLinkEnabled && !isBusy ? onOneLink : null,
                icon: const Icon(Icons.hub_outlined, size: 18),
                label: const Text('OneLink'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextSpan _colorize(BuildContext context, String value) {
    final int queryIndex = value.indexOf('?');
    final String base =
        queryIndex >= 0 ? value.substring(0, queryIndex) : value;
    final String query = queryIndex >= 0 ? value.substring(queryIndex + 1) : '';

    final List<InlineSpan> spans = <InlineSpan>[
      TextSpan(
        text: base,
        style: const TextStyle(
          color: Palette.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];

    if (query.isNotEmpty) {
      spans.add(const TextSpan(
        text: '?',
        style: TextStyle(color: Palette.greyMuted),
      ));

      final List<String> pairs = query.split('&');
      for (int i = 0; i < pairs.length; i++) {
        final String pair = pairs[i];
        final int eq = pair.indexOf('=');
        final String key = eq >= 0 ? pair.substring(0, eq) : pair;
        final String val = eq >= 0 ? pair.substring(eq + 1) : '';

        spans.add(TextSpan(
          text: key,
          style: const TextStyle(
            color: Palette.amber,
            fontWeight: FontWeight.w600,
          ),
        ));
        if (eq >= 0) {
          spans.add(const TextSpan(
            text: '=',
            style: TextStyle(color: Palette.greyMuted),
          ));
          spans.add(TextSpan(
            text: val,
            style: const TextStyle(color: Palette.white),
          ));
        }
        if (i != pairs.length - 1) {
          spans.add(const TextSpan(
            text: '&',
            style: TextStyle(color: Palette.greyMuted),
          ));
        }
      }
    }

    return TextSpan(children: spans);
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, size: 11, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
