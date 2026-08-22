import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/generated_link.dart';
import '../../viewmodels/generator_viewmodel.dart';

import '../../views/generator/generator_view.dart';
import '../../views/history/history_view.dart';
import '../../views/home/home_view.dart';
import '../../views/qr/qr_view.dart';
import '../../views/shell/app_shell.dart';
import '../../views/spec/setup_view.dart';
import '../../views/spec/spec_sheet.dart';
import '../../views/splash/splash_view.dart';
import '../../views/catalogue/catalogue_view.dart';
import '../../views/catalogue/widgets/filter_sheet.dart';

enum AppRoute {
  splash('/splash', 'Splash'),
  setup('/setup', 'Setup'),
  spec('/spec', 'Spec'),
  home('/home', 'Home'),
  catalogue('/catalogue', 'Catalogue'),
  generator('/generator', 'Generator'),
  history('/history', 'History'),
  qr('/qr', 'QR code'),
  filters('/filters', 'Filter');

  const AppRoute(this.path, this.label);
  final String path;
  final String label;
}

class AppRouter {
  const AppRouter._();

  static GoRouter create() {
    final GlobalKey<NavigatorState> rootNavigatorKey =
        GlobalKey<NavigatorState>(debugLabel: 'root');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoute.splash.path,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.splash.path,
          name: AppRoute.splash.name,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) =>
              const SplashView(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) =>
              AppShell(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.home.path,
                  name: AppRoute.home.name,
                  builder: (BuildContext context, GoRouterState state) =>
                      const HomeView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.catalogue.path,
                  name: AppRoute.catalogue.name,
                  builder: (BuildContext context, GoRouterState state) =>
                      const CatalogueView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.generator.path,
                  name: AppRoute.generator.name,
                  builder: (BuildContext context, GoRouterState state) =>
                      const GeneratorView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.history.path,
                  name: AppRoute.history.name,
                  builder: (BuildContext context, GoRouterState state) =>
                      const HistoryView(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoute.setup.path,
          name: AppRoute.setup.name,
          parentNavigatorKey: rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) =>
              const SetupView(),
        ),
        GoRoute(
          path: AppRoute.spec.path,
          name: AppRoute.spec.name,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              const ModalSheetPage<void>(child: SpecSheet()),
        ),
        GoRoute(
          path: AppRoute.filters.path,
          name: AppRoute.filters.name,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              const ModalSheetPage<void>(child: FilterSheet()),
        ),
        GoRoute(
          path: AppRoute.qr.path,
          name: AppRoute.qr.name,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final GeneratedLink? link = state.extra is GeneratedLink
                ? state.extra! as GeneratedLink
                : context.read<GeneratorViewModel>().link;
            return ModalSheetPage<void>(child: QrSheet(link: link));
          },
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) =>
          RouteNotFoundView(location: state.uri.toString()),
    );
  }
}

class ModalSheetPage<T> extends Page<T> {
  const ModalSheetPage({required this.child, super.key});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      builder: (BuildContext context) => child,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}

class RouteNotFoundView extends StatelessWidget {
  const RouteNotFoundView({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.wrong_location_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text('No screen matches', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                location,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRoute.catalogue.path),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to catalogue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
