import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/deeplink_entry.dart';
import '../../../viewmodels/generator_viewmodel.dart';
import 'entry_header_card.dart';

class EntryInfoSheet extends StatelessWidget {
  const EntryInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final GeneratorViewModel vm = context.watch<GeneratorViewModel>();
    final DeeplinkEntry? entry = vm.entry;

    if (entry == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Text(
            'No deeplink selected.',
            style: AppTheme.hudLabel(color: Palette.grey, size: 11),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'DEEPLINK INFO',
                  style: AppTheme.hudLabel(color: Palette.white, size: 12),
                ),
              ),
              EntryHeaderCard(
                entry: entry,
                variant: vm.variant,
                testedUserType: vm.testedUserType,
                onVariantSelected: vm.selectVariant,
                onUserTypeSelected: vm.setTestedUserType,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
