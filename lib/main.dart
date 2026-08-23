import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/backdrop.dart';
import 'data/datasources/deeplink_spec_source.dart';
import 'data/datasources/local_storage.dart';
import 'data/repositories/deeplink_repository.dart';
import 'data/repositories/history_repository.dart';
import 'data/repositories/onelink_repository.dart';
import 'data/repositories/usage_repository.dart';
import 'services/deeplink_form_service.dart';
import 'services/spec_import_service.dart';
import 'services/launcher_service.dart';
import 'services/link_action_runner.dart';
import 'services/link_builder_service.dart';
import 'services/onelink_gateway.dart';
import 'services/onelink_service.dart';
import 'services/qr_service.dart';
import 'services/share_service.dart';
import 'viewmodels/catalogue_viewmodel.dart';
import 'viewmodels/generator_viewmodel.dart';
import 'viewmodels/history_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/onelink_viewmodel.dart';
import 'viewmodels/spec_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final LocalStorage storage = await LocalStorage.getInstance();
  final SpecLoadResult spec = await const DeeplinkSpecSource().load();

  runApp(LinkXApp(storage: storage, spec: spec));
}

class LinkXApp extends StatefulWidget {
  const LinkXApp({super.key, required this.storage, required this.spec});

  final LocalStorage storage;
  final SpecLoadResult spec;

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
        ChangeNotifierProvider<DeeplinkRepository>(
          create: (_) => DeeplinkRepository(widget.spec),
        ),
        ChangeNotifierProvider<HistoryRepository>(
          create: (_) => HistoryRepository(widget.storage),
        ),
        ChangeNotifierProvider<UsageRepository>(
          create: (_) => UsageRepository(widget.storage),
        ),
        Provider<SpecImportService>.value(value: const SpecImportService()),
        ChangeNotifierProvider<SpecViewModel>(
          create: (BuildContext c) => SpecViewModel(
            deeplinkRepository: c.read<DeeplinkRepository>(),
            importService: c.read<SpecImportService>(),
            storage: widget.storage,
          ),
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
        ProxyProvider4<QrService, ShareService, HistoryRepository,
            UsageRepository, LinkActionRunner>(
          update: (
            BuildContext c,
            QrService qr,
            ShareService share,
            HistoryRepository history,
            UsageRepository usage,
            __,
          ) =>
              LinkActionRunner(
            qrService: qr,
            shareService: share,
            launcher: c.read<LauncherService>(),
            historyRepository: history,
            usageRepository: usage,
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (BuildContext c) => HomeViewModel(
            runner: c.read<LinkActionRunner>(),
            deeplinkRepository: c.read<DeeplinkRepository>(),
            historyRepository: c.read<HistoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<OneLinkRepository>(
          create: (_) => OneLinkRepository(widget.storage),
        ),
        Provider<OneLinkGateway>(create: (_) => AppsFlyerOneLinkGateway()),
        ProxyProvider2<OneLinkGateway, OneLinkRepository, OneLinkService>(
          update: (_, OneLinkGateway gateway, OneLinkRepository repo, __) =>
              OneLinkService(gateway: gateway, repository: repo),
        ),
        ChangeNotifierProvider<HomeOneLinkViewModel>(
          create: (BuildContext c) {
            final HomeViewModel home = c.read<HomeViewModel>();
            return HomeOneLinkViewModel(
              service: c.read<OneLinkService>(),
              deeplinkRepository: c.read<DeeplinkRepository>(),
              source: home.linkController,
              readSource: () => home.linkController.text,
              readReady: () => home.isValid,
            );
          },
        ),
        ChangeNotifierProvider<GeneratorViewModel>(
          create: (BuildContext c) => GeneratorViewModel(
            formService: c.read<DeeplinkFormService>(),
            builder: c.read<LinkBuilderService>(),
            runner: c.read<LinkActionRunner>(),
            deeplinkRepository: c.read<DeeplinkRepository>(),
          ),
        ),
        ChangeNotifierProvider<GeneratorOneLinkViewModel>(
          create: (BuildContext c) {
            final GeneratorViewModel generator = c.read<GeneratorViewModel>();
            return GeneratorOneLinkViewModel(
              service: c.read<OneLinkService>(),
              deeplinkRepository: c.read<DeeplinkRepository>(),
              source: generator,
              readSource: () => generator.url,
              readReady: () => generator.hasLink,
            );
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'LinkX',
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
