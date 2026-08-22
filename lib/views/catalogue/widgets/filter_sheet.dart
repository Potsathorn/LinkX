import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel_label.dart';
import '../../../data/models/user_type.dart';
import '../../../viewmodels/catalogue_viewmodel.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final CatalogueViewModel vm = context.watch<CatalogueViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('FILTER',
                    style: AppTheme.hudLabel(color: Palette.white, size: 12)),
                const Spacer(),
                if (vm.isFiltering)
                  TextButton(
                    onPressed: vm.clearFilters,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('CHANNEL', style: AppTheme.hudLabel(size: 9)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final ChannelLabel label in vm.availableLabels)
                  _Chip(
                    label: '${label.shortLabel} ${vm.countForLabel(label)}',
                    selected: vm.label == label,
                    onTap: () => vm.selectLabel(label),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('USER TYPE', style: AppTheme.hudLabel(size: 9)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final UserType type in vm.availableUserTypes)
                  _Chip(
                    label: '${type.label} ${vm.countForUserType(type)}',
                    selected: vm.userType == type,
                    onTap: () => vm.selectUserType(type),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Show ${vm.entries.length}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: Palette.navy,
      selectedColor: Palette.amber,
      side: BorderSide(color: selected ? Palette.amber : Palette.navyLine),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: selected ? Palette.black : Palette.grey,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
