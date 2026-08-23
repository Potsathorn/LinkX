import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/channel_label.dart';
import '../../data/models/parameter_requirement.dart';
import '../../data/models/user_type.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.compact = false});

  final int rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 24 : 30;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.amber,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Palette.amber,
        ),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontFamily: AppTheme.monoFallback.first,
          fontFamilyFallback: AppTheme.monoFallback,
          fontSize: compact ? 11 : 13,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Palette.black,
        ),
      ),
    );
  }
}

class ChannelChip extends StatelessWidget {
  const ChannelChip({super.key, required this.label, this.dense = false});

  final ChannelLabel label;
  final bool dense;

  static IconData iconFor(ChannelLabel label) => switch (label) {
        ChannelLabel.marketingOneLink => Icons.campaign_outlined,
        ChannelLabel.chatVoiceBot => Icons.forum_outlined,
        ChannelLabel.pushNotification => Icons.notifications_active_outlined,
        ChannelLabel.unreferenced => Icons.help_outline,
      };

  static Color colorFor(ChannelLabel label, ColorScheme scheme) =>
      label == ChannelLabel.unreferenced ? Palette.greyMuted : Palette.grey;

  @override
  Widget build(BuildContext context) {
    final Color color = colorFor(label, Theme.of(context).colorScheme);

    if (dense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label.shortLabel,
            style: AppTheme.hudLabel(color: Palette.greyMuted),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(iconFor(label), size: 11, color: color),
          const SizedBox(width: 5),
          Text(label.shortLabel, style: AppTheme.hudLabel(color: color)),
        ],
      ),
    );
  }
}

class UserTypeStrip extends StatelessWidget {
  const UserTypeStrip({super.key, required this.types});

  final List<UserType> types;

  bool get _isEveryType => types.length == UserType.values.length;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: types.map((UserType t) => t.description).join('\n'),
      child: Text(
        _isEveryType ? 'ALL' : types.map((UserType t) => t.label).join(' '),
        style: AppTheme.hudLabel(
          color: _isEveryType ? Palette.greyMuted : Palette.grey,
          size: 9.5,
        ),
      ),
    );
  }
}

class UserTypeChip extends StatelessWidget {
  const UserTypeChip({
    super.key,
    required this.type,
    this.highlighted = false,
  });

  final UserType type;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color color = highlighted ? Palette.amber : Palette.grey;

    return Tooltip(
      message: type.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: highlighted ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: color.withValues(alpha: highlighted ? 0.6 : 0.22),
          ),
        ),
        child: Text(type.label, style: AppTheme.hudLabel(color: color)),
      ),
    );
  }
}

class RequirementChip extends StatelessWidget {
  const RequirementChip({super.key, required this.requirement});

  final ParameterRequirement requirement;

  static Color colorFor(ParameterRequirement requirement, ColorScheme scheme) =>
      switch (requirement) {
        ParameterRequirement.required => Palette.amber,
        ParameterRequirement.conditional => Palette.white,
        ParameterRequirement.optional => Palette.greyMuted,
      };

  @override
  Widget build(BuildContext context) {
    final Color color = colorFor(requirement, Theme.of(context).colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            requirement.label.toLowerCase(),
            style: AppTheme.hudLabel(color: color),
          ),
        ],
      ),
    );
  }
}

class HudPanel extends StatelessWidget {
  const HudPanel({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.navy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent?.withValues(alpha: 0.45) ?? Palette.navyLine,
        ),
        boxShadow: accent == null
            ? null
            : AppTheme.glow(accent!, blur: 18, opacity: 0.14),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class TerminalBlock extends StatelessWidget {
  const TerminalBlock({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.prefix = '❯',
    this.color,
  });

  final String text;
  final int maxLines;
  final String prefix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Palette.black,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Palette.navyLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            prefix,
            style: AppTheme.mono(context, size: 11)
                .copyWith(color: Palette.amber.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.mono(context, size: 11)
                  .copyWith(color: color ?? Palette.grey),
            ),
          ),
        ],
      ),
    );
  }
}
