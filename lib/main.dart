import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/admin_provider.dart';
import 'providers/ai_planner_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_store.dart';
import 'providers/connectivity_provider.dart';
import 'providers/map_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/spots_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trips_provider.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env is optional — the app runs fully on local data without it.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    /* no .env present — that's fine */
  }

  await initializeDateFormatting('ar');
  HijriCalendar.setLocal('ar');
  await Hive.initFlutter();
  await ServiceLocator.instance.init();

  final theme = ThemeProvider();
  final locale = LocaleProvider();
  final categories = CategoryStore();
  final connectivity = ConnectivityProvider();
  await Future.wait([
    theme.load(),
    locale.load(),
    categories.load(),
    connectivity.init(),
  ]);

  final auth = AuthProvider()..bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider.value(value: categories),
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => TripsProvider()),
        ChangeNotifierProvider(create: (_) => AiPlannerProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const SpotWiseApp(),
    ),
  );
}
