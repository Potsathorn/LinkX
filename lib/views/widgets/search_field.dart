import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.initialValue = '',
    this.debounce = const Duration(milliseconds: 220),
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  Timer? _debounceTimer;

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged(value));
    setState(() {});
  }

  void _clear() {
    _debounceTimer?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: AppTheme.mono(context, size: 12.5),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTheme.mono(context, size: 12.5)
            .copyWith(color: Palette.greyMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: Palette.amber),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear search',
                onPressed: _clear,
              ),
      ),
    );
  }
}
