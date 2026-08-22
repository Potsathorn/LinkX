import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel_label.dart';
import '../../../data/models/deeplink_entry.dart';
import '../../../data/models/user_type.dart';
import '../../widgets/spec_chips.dart';

class EntryHeaderCard extends StatelessWidget {
  const EntryHeaderCard({
    super.key,
    required this.entry,
    required this.variant,
    required this.testedUserType,
    required this.onVariantSelected,
    required this.onUserTypeSelected,
  });

  final DeeplinkEntry entry;
  final String variant;
  final UserType? testedUserType;
  final ValueChanged<String> onVariantSelected;
  final ValueChanged<UserType?> onUserTypeSelected;

  @override
  Widget build(BuildContext context) {
    final bool allowed =
        testedUserType == null || entry.allowsUserType(testedUserType!);

    return HudPanel(
      accent: Palette.amber,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RankBadge(rank: entry.rank),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.destinationPage,
                      style: AppTheme.mono(context, size: 12.5).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: <Widget>[
                        for (final ChannelLabel label in entry.labels)
                          ChannelChip(label: label, dense: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TerminalBlock(text: entry.pathPattern, maxLines: 4),
          if (entry.hasVariants) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String option in entry.variants)
                  ChoiceChip(
                    label: Text(
                      option,
                      style: AppTheme.mono(context, size: 10.5).copyWith(
                        color: option == variant ? Palette.black : Palette.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: option == variant,
                    showCheckmark: false,
                    selectedColor: Palette.amber,
                    side: BorderSide(
                      color:
                          option == variant ? Palette.amber : Palette.navyLine,
                    ),
                    onSelected: (_) => onVariantSelected(option),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text('TEST AS', style: AppTheme.hudLabel(size: 8.5)),
              if (!allowed) ...<Widget>[
                const SizedBox(width: 9),
                const Icon(Icons.block, size: 12, color: Palette.amber),
                const SizedBox(width: 5),
                Text(
                  'not allowed',
                  style: AppTheme.hudLabel(color: Palette.amber, size: 9),
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final UserType type in UserType.values)
                _UserTypeOption(
                  type: type,
                  selected: testedUserType == type,
                  allowed: entry.allowsUserType(type),
                  onSelected: () => onUserTypeSelected(
                    testedUserType == type ? null : type,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserTypeOption extends StatelessWidget {
  const _UserTypeOption({
    required this.type,
    required this.selected,
    required this.allowed,
    required this.onSelected,
  });

  final UserType type;
  final bool selected;
  final bool allowed;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        selected ? Palette.black : (allowed ? Palette.grey : Palette.greyFaint);

    return Tooltip(
      message: allowed
          ? type.description
          : '${type.description} — not in allowed list',
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(5),
        child: Opacity(
          opacity: allowed ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? Palette.amber : null,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected ? Palette.amber : Palette.navyLine,
              ),
            ),
            child: Text(
              type.label,
              style: AppTheme.hudLabel(color: accent, size: 10),
            ),
          ),
        ),
      ),
    );
  }
}
