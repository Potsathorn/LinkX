import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/backdrop.dart';
import 'data/datasources/deeplink_spec_source.dart';
import 'data/datasources/local_storage.dart';
import 'data/models/deeplink_entry.dart';
import 'data/repositories/deeplink_repository.dart';
import 'data/repositories/history_repository.dart';
import 'data/repositories/usage_repository.dart';
import 'services/deeplink_form_service.dart';
import 'services/launcher_service.dart';
import 'services/link_builder_service.dart';
import 'services/qr_service.dart';
import 'services/share_service.dart';
import 'viewmodels/catalogue_viewmodel.dart';
import 'viewmodels/generator_viewmodel.dart';
import 'viewmodels/history_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final LocalStorage storage = await LocalStorage.getInstance();
  final SpecLoadResult spec = await const DeeplinkSpecSource().load();

  runApp(LinkXApp(
    storage: storage,
    entries: spec.entries,
    isExampleSpec: spec.isExample,
  ));
}

class LinkXApp extends StatefulWidget {
  const LinkXApp({
    super.key,
    required this.storage,
    required this.entries,
    this.isExampleSpec = false,
  });

  final LocalStorage storage;
  final List<DeeplinkEntry> entries;
  final bool isExampleSpec;

  @override
  State<LinkXApp> createState() => _LinkXAppState();
}

class _LinkXAppState extends State<LinkXApp> {
  late final GoRouter _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<DeeplinkFormService>.value(value: const DeeplinkFormService()),
        Provider<LinkBuilderService>.value(value: const LinkBuilderService()),
        Provider<QrService>.value(value: const QrService()),
        Provider<LauncherService>.value(value: const LauncherService()),
        ProxyProvider<QrService, ShareService>(
          update: (_, QrService qr, __) => ShareService(qr),
        ),
        Provider<DeeplinkRepository>.value(
          value: DeeplinkRepository(
            widget.entries,
            isExample: widget.isExampleSpec,
          ),
        ),
        ChangeNotifierProvider<HistoryRepository>(
          create: (_) => HistoryRepository(widget.storage),
        ),
        ChangeNotifierProvider<UsageRepository>(
          create: (_) => UsageRepository(widget.storage),
        ),
        ChangeNotifierProvider<CatalogueViewModel>(
          create: (BuildContext c) => CatalogueViewModel(
            deeplinkRepository: c.read<DeeplinkRepository>(),
            usageRepository: c.read<UsageRepository>(),
          ),
        ),
        ChangeNotifierProvider<HistoryViewModel>(
          create: (BuildContext c) => HistoryViewModel(
            historyRepository: c.read<HistoryRepository>(),
            launcher: c.read<LauncherService>(),
          ),
        ),
        ChangeNotifierProvider<GeneratorViewModel>(
          create: (BuildContext c) => GeneratorViewModel(
            formService: c.read<DeeplinkFormService>(),
            builder: c.read<LinkBuilderService>(),
            qrService: c.read<QrService>(),
            shareService: c.read<ShareService>(),
            launcher: c.read<LauncherService>(),
            deeplinkRepository: c.read<DeeplinkRepository>(),
            historyRepository: c.read<HistoryRepository>(),
            usageRepository: c.read<UsageRepository>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'LinkX Tester',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        builder: (BuildContext context, Widget? child) =>
            FuturisticBackdrop(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
