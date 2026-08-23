import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkx/data/datasources/deeplink_spec_source.dart';
import 'package:linkx/data/datasources/local_storage.dart';
import 'package:linkx/main.dart';
import 'package:linkx/views/catalogue/catalogue_view.dart';
import 'package:linkx/views/catalogue/widgets/deeplink_card.dart';
import 'package:linkx/views/catalogue/widgets/filter_sheet.dart';
import 'package:linkx/views/generator/generator_view.dart';
import 'package:linkx/views/history/history_view.dart';
import 'package:linkx/views/home/home_view.dart';
import 'package:linkx/views/spec/setup_view.dart';
import 'package:linkx/views/splash/splash_view.dart';
import 'package:linkx/views/widgets/empty_state.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'spec_fixture.dart';

void main() {
  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferences.resetStatic();
    LocalStorage.resetForTesting();
    storage = await LocalStorage.getInstance();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      LinkXApp(storage: storage, spec: fixtureSpec()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToCatalogue(WidgetTester tester) async {
    await tester.tap(find.text('Catalogue'));
    await tester.pumpAndSettle();
  }

  Future<void> openEntry(WidgetTester tester, String destinationPage) async {
    await goToCatalogue(tester);
    await tester.tap(find.text(destinationPage).first);
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the splash and enters the catalogue',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      LinkXApp(storage: storage, spec: fixtureSpec()),
    );
    await tester.pump();

    expect(find.byType(SplashView), findsOneWidget);
    expect(find.byType(CatalogueView), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('tapping the splash skips straight to the catalogue',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      LinkXApp(storage: storage, spec: fixtureSpec()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashView), findsOneWidget);

    await tester.tap(find.byType(SplashView));
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('starts on the catalogue with the ranked spec entries',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToCatalogue(tester);

    expect(find.byType(CatalogueView), findsOneWidget);
    expect(find.text('Deeplinks'), findsOneWidget);
    expect(find.text('InboxConnectorPage'), findsWidgets);
    expect(find.byType(DeeplinkCard), findsWidgets);
  });

  testWidgets('no demo badge when the real spec is loaded',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToCatalogue(tester);
    expect(find.text('DEMO SPEC'), findsNothing);
  });

  testWidgets('an example spec sends the tester to setup first',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      LinkXApp(
        storage: storage,
        spec: fixtureSpec(origin: SpecOrigin.example),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SetupView), findsOneWidget);
    expect(find.byType(HomeView), findsNothing);

    await tester.tap(find.text('Continue with the example spec'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);

    await goToCatalogue(tester);
    expect(find.text('DEMO SPEC'), findsOneWidget);
  });

  testWidgets('setup is not shown again once the example is accepted',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{'linkx.spec.exampleAccepted.v1': true},
    );
    SharedPreferences.resetStatic();
    LocalStorage.resetForTesting();
    final LocalStorage seeded = await LocalStorage.getInstance();

    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      LinkXApp(
        storage: seeded,
        spec: fixtureSpec(origin: SpecOrigin.example),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SetupView), findsNothing);
    expect(find.byType(HomeView), findsOneWidget);

    await goToCatalogue(tester);
    expect(find.text('DEMO SPEC'), findsOneWidget);
  });

  testWidgets('search filters by parameter name', (WidgetTester tester) async {
    await pumpApp(tester);
    await goToCatalogue(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search page, path or parameter'),
      'offerCode',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('1 of 13'), findsOneWidget);
    expect(find.text('OfferDetailPage'), findsOneWidget);
    expect(find.byType(DeeplinkCard), findsOneWidget);
  });

  testWidgets('the filter sheet narrows the list', (WidgetTester tester) async {
    await pumpApp(tester);
    await goToCatalogue(tester);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    expect(find.byType(FilterSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Push Noti 3'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Show 3'));
    await tester.pumpAndSettle();

    expect(find.text('3 of 13'), findsOneWidget);
    expect(find.byType(DeeplinkCard), findsNWidgets(3));
  });

  testWidgets('picking an entry loads it into the generator',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openEntry(tester, 'OfferDetailPage');

    expect(find.byType(GeneratorView), findsOneWidget);
    expect(find.text('offerCode'), findsOneWidget);
    expect(find.text('required'), findsOneWidget);
    expect(find.text('Link not ready'), findsOneWidget);
  });

  testWidgets('filling the required parameter produces a valid deeplink',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openEntry(tester, 'OfferDetailPage');

    await tester.enterText(
      find.widgetWithText(TextField, 'Required value'),
      'OFFER26',
    );
    await tester.pumpAndSettle();

    expect(find.text('Generated link'), findsOneWidget);
    expect(
      find.textContaining(
        'demoapp://deeplink/offer-detail?offerCode=OFFER26',
        findRichText: true,
      ),
      findsWidgets,
    );
  });

  testWidgets('allowed values render as choice chips and build the url',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openEntry(tester, 'InboxConnectorPage');

    expect(find.text('Link not ready'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'alpha'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'detail'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'alpha'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'demoapp://deeplink/inbox?folder=alpha',
        findRichText: true,
      ),
      findsWidgets,
    );
  });

  testWidgets('an unsupported user type is flagged in the header',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openEntry(tester, 'PreferenceChannelPage');

    expect(find.text('not allowed'), findsNothing);

    await tester.tap(find.text('NTA'));
    await tester.pumpAndSettle();

    expect(find.text('not allowed'), findsOneWidget);
  });

  testWidgets('the QR route opens over the shell', (WidgetTester tester) async {
    await pumpApp(tester);
    await openEntry(tester, 'PreferenceChannelPage');

    await tester.tap(find.widgetWithText(OutlinedButton, 'QR'));
    await tester.pumpAndSettle();

    expect(find.text('QR code'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('the home launcher rejects a link with no scheme',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Paste any deeplink or OneLink to test'),
      'not-a-link',
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Start the link with a scheme'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Launch'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('the home launcher enables actions for a valid link',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Paste any deeplink or OneLink to test'),
      'demoapp://deeplink/inbox?folder=alpha',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Start the link with a scheme'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Launch'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'QR'));
    await tester.pumpAndSettle();

    expect(find.text('QR code'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Ad-hoc link'), findsOneWidget);
  });

  testWidgets('home shows the top three ranked deeplinks and hides recent',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('TOP LINKS'), findsOneWidget);
    expect(find.text('RECENT'), findsNothing);
    expect(find.byType(DeeplinkCard), findsNWidgets(3));
  });

  testWidgets('the history tab starts empty', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryView), findsOneWidget);
    expect(
      tester.widget<EmptyState>(find.byType(EmptyState)).title,
      'No history yet',
    );
  });
}
