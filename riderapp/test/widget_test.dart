import 'package:citiride/components/bottom_nav_bar.dart';
import 'package:citiride/components/home_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home sheet and nav fit compact phone widths', (tester) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(360, 740),
      const Size(390, 844),
    ];

    for (final size in sizes) {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: Scaffold(
                body: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Column(
                    children: [
                      SizedBox(
                        width: size.width - 28,
                        height: size.height < 700 ? 94 : 96,
                        child: HomeModalSheet(
                          scrollController: scrollController,
                        ),
                      ),
                      const SizedBox(height: 26),
                      BottomNavBar(
                        currentIndex: 0,
                        onTabChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Where are we going today?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
