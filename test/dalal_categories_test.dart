import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spot_wise/core/constants/categories.dart';
import 'package:spot_wise/core/l10n/category_labels.dart';
import 'package:spot_wise/l10n/app_localizations.dart';
import 'package:spot_wise/providers/category_store.dart';
import 'package:spot_wise/screens/home/home_feed_screen.dart';
import 'package:spot_wise/screens/shell/home_shell.dart';

void main() {
  for (final width in [320.0, 820.0]) {
    testWidgets('Category layout switches language at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final language = ValueNotifier(const Locale('ar'));
      final tab = HomeTab(2);
      final store = CategoryStore();
      addTearDown(language.dispose);
      addTearDown(tab.dispose);
      addTearDown(store.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: tab),
            ChangeNotifierProvider.value(value: store),
          ],
          child: ValueListenableBuilder(
            valueListenable: language,
            builder: (context, locale, child) => MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const DalalCategoriesScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = find.text('فئات دليل حائل');
      expect(title, findsOneWidget);
      expect(Directionality.of(tester.element(title)), TextDirection.rtl);
      expect(find.text('معالم تراثية'), findsOneWidget);

      language.value = const Locale('en');
      await tester.pumpAndSettle();
      final englishTitle = find.text('Hail Guide Categories');
      expect(englishTitle, findsOneWidget);
      expect(
        Directionality.of(tester.element(englishTitle)),
        TextDirection.ltr,
      );
      expect(find.text('Heritage Sites'), findsOneWidget);

      final englishContext = tester.element(englishTitle);
      for (final category in Categories.all) {
        expect(
          englishContext.categoryLabel(category),
          isNot(category.label),
          reason: 'English label missing for ${category.id}',
        );
      }

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Workshops and Activities'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Pharmacies'), findsOneWidget);
      expect(find.text('Restaurants'), findsOneWidget);
      await tester.tap(find.text('Restaurants'));
      await tester.pumpAndSettle();
      final burgers = find.text('Burgers');
      await tester.ensureVisible(burgers);
      await tester.tap(burgers);
      await tester.pumpAndSettle();

      expect(tab.index, 0);
      expect(tab.takeCategory(), 'restaurant_burger');
      expect(tester.takeException(), isNull);
    });
  }
}
