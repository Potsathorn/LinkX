import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/link_parameter.dart';
import '../../../data/models/parameter_requirement.dart';
import '../../widgets/spec_chips.dart';

class ParameterField extends StatefulWidget {
  const ParameterField({
    super.key,
    required this.parameter,
    required this.onChanged,
    required this.onToggled,
  });

  final LinkParameter parameter;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onToggled;

  @override
  State<ParameterField> createState() => _ParameterFieldState();
}

class _ParameterFieldState extends State<ParameterField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.parameter.value);

  @override
  void didUpdateWidget(covariant ParameterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parameter.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.parameter.value,
        selection:
            TextSelection.collapsed(offset: widget.parameter.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LinkParameter p = widget.parameter;
    final bool hasError = p.isMissing || p.hasDisallowedValue;

    final Color accent = hasError
        ? Palette.amber
        : (p.isIncluded ? Palette.grey : Palette.navyLine);

    return Opacity(
      opacity: p.enabled ? 1 : 0.5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Palette.navy,
          borderRadius: BorderRadius.circular(7),
          border:
              Border.all(color: hasError ? Palette.amber : Palette.navyLine),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(
                                  p.displayName,
                                  style: AppTheme.mono(context, size: 12.5)
                                      .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: p.isIncluded
                                        ? Palette.white
                                        : Palette.grey,
                                  ),
                                ),
                                RequirementChip(requirement: p.requirement),
                                if (p.isPathParameter)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Palette.navyRaised,
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: Palette.navyEdge),
                                    ),
                                    child: const Text(
                                      'path',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: Palette.greyMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (p.requirement != ParameterRequirement.required)
                            Tooltip(
                              message: p.enabled
                                  ? 'Exclude from the deeplink'
                                  : 'Include in the deeplink',
                              child: Switch(
                                value: p.enabled,
                                activeThumbColor: p.isIncluded
                                    ? Palette.amber
                                    : Palette.greyMuted,
                                activeTrackColor: p.isIncluded
                                    ? Palette.amber.withValues(alpha: 0.22)
                                    : Palette.navyRaised,
                                onChanged: widget.onToggled,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (p.hasAllowedValues)
                        _AllowedValuePicker(
                          parameter: p,
                          onChanged: widget.onChanged,
                        )
                      else
                        TextField(
                          controller: _controller,
                          enabled: p.enabled,
                          onChanged: widget.onChanged,
                          style: AppTheme.mono(context),
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText:
                                p.requirement == ParameterRequirement.required
                                    ? 'Required value'
                                    : 'Value',
                            errorText:
                                p.isMissing ? 'This value is required' : null,
                          ),
                        ),
                      if (p.hasDisallowedValue) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.block,
                                size: 12, color: Palette.amber),
                            const SizedBox(width: 6),
                            Text(
                              'Not an allowed value in code',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Palette.amber, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllowedValuePicker extends StatelessWidget {
  const _AllowedValuePicker({
    required this.parameter,
    required this.onChanged,
  });

  final LinkParameter parameter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String value in parameter.allowedValues)
          ChoiceChip(
            label: Text(
              value,
              style: AppTheme.mono(context, size: 11).copyWith(
                fontWeight: FontWeight.w700,
                color: parameter.trimmedValue == value
                    ? Palette.black
                    : Palette.grey,
              ),
            ),
            selected: parameter.trimmedValue == value,
            showCheckmark: false,
            selectedColor: Palette.amber,
            side: BorderSide(
              color: parameter.trimmedValue == value
                  ? Palette.amber
                  : Palette.navyLine,
            ),
            onSelected: parameter.enabled
                ? (bool selected) => onChanged(selected ? value : '')
                : null,
          ),
      ],
    );
  }
}
