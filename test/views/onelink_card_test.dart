import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkx/core/theme/app_theme.dart';
import 'package:linkx/data/datasources/local_storage.dart';
import 'package:linkx/data/models/onelink_config.dart';
import 'package:linkx/data/repositories/deeplink_repository.dart';
import 'package:linkx/data/repositories/onelink_repository.dart';
import 'package:linkx/services/onelink_gateway.dart';
import 'package:linkx/services/onelink_service.dart';
import 'package:linkx/viewmodels/onelink_viewmodel.dart';
import 'package:linkx/views/widgets/onelink_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../spec_fixture.dart';

class _FakeGateway implements OneLinkGateway {
  @override
  Future<String> generate({
    required OneLinkEnvironment environment,
    required Map<String, String> customParams,
  }) async {
    return 'https://demo.onelink.me/${environment.afOneLinkId}/'
        'generated?deep_link_value=inbox&deep_link_sub1=alpha'
        '&af_dp=cardx%3A%2F%2Fdeeplink%2Finbox%3Ffolder%3Dalpha';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String deeplink = 'cardx://deeplink/inbox?folder=alpha';

  late OneLinkViewModel vm;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferences.resetStatic();
    LocalStorage.resetForTesting();

    final LocalStorage storage = await LocalStorage.getInstance();
    final TextEditingController source = TextEditingController(text: deeplink);
    addTearDown(source.dispose);

    vm = OneLinkViewModel(
      service: OneLinkService(
        gateway: _FakeGateway(),
        repository: OneLinkRepository(storage),
      ),
      deeplinkRepository: DeeplinkRepository(fixtureSpec()),
      source: source,
      readSource: () => source.text,
      readReady: () => true,
    );
    addTearDown(vm.dispose);
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: vm,
                builder: (BuildContext context, _) => OneLinkCard(
                  vm: vm,
                  onGenerate: vm.generate,
                  onCopy: () {},
                  onLaunch: () {},
                  onShare: () {},
                  onQr: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the result block is present but disabled before generating',
      (WidgetTester tester) async {
    await pumpCard(tester);
    vm.selectEnvironment('SIT');
    await tester.pumpAndSettle();

    expect(find.text('Not generated yet\n--'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Launch'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'QR'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.copy_all_outlined))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.share))
          .onPressed,
      isNull,
    );
  });

  testWidgets('the card keeps the same height once a OneLink is generated',
      (WidgetTester tester) async {
    await pumpCard(tester);
    vm.selectEnvironment('SIT');
    await tester.pumpAndSettle();

    final double before = tester.getSize(find.byType(OneLinkCard)).height;

    await tester.tap(find.widgetWithText(FilledButton, 'Generate OneLink'));
    await tester.pumpAndSettle();

    expect(vm.generated, isNotNull);
    expect(tester.getSize(find.byType(OneLinkCard)).height, before);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Launch'))
          .onPressed,
      isNotNull,
    );
  });
}
