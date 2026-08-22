import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/catalogue_viewmodel.dart';

class MostUsedSection extends StatelessWidget {
  const MostUsedSection({
    super.key,
    required this.ranked,
    required this.onTap,
    this.onReset,
  });

  final List<RankedEntry> ranked;
  final ValueChanged<RankedEntry> onTap;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    if (ranked.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 8, 8),
            child: Row(
              children: <Widget>[
                Text('MOST USED', style: AppTheme.hudLabel(size: 9.5)),
                const Spacer(),
                if (onReset != null)
                  InkWell(
                    onTap: onReset,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.restart_alt,
                          size: 15, color: Palette.greyMuted),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ranked.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) => _Pill(
                ranked: ranked[index],
                onTap: () => onTap(ranked[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.ranked, required this.onTap});

  final RankedEntry ranked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Palette.navy,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Palette.navyLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              ranked.entry.destinationPage,
              style: AppTheme.mono(context, size: 10.5)
                  .copyWith(color: Palette.white),
            ),
            const SizedBox(width: 8),
            Text(
              '${ranked.count}x',
              style: AppTheme.hudLabel(color: Palette.amber, size: 9),
            ),
          ],
        ),
      ),
    );
  }
}
