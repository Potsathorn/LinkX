import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PasteSpecDialog extends StatefulWidget {
  const PasteSpecDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const PasteSpecDialog(),
    );
  }

  @override
  State<PasteSpecDialog> createState() => _PasteSpecDialogState();
}

class _PasteSpecDialogState extends State<PasteSpecDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'PASTE SPEC JSON',
        style: AppTheme.hudLabel(color: Palette.white, size: 12),
      ),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 10,
          minLines: 6,
          style: AppTheme.mono(context, size: 11.5),
          decoration: const InputDecoration(
            hintText: '{ "deeplinks": [ ... ] }',
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final String raw = _controller.text.trim();
            Navigator.pop(context, raw.isEmpty ? null : raw);
          },
          child: const Text('Load'),
        ),
      ],
    );
  }
}
