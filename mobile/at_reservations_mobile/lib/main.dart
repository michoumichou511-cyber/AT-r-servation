import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/app_preferences.dart';
import 'services/notification_service.dart';
import 'services/offline_service.dart';
import 'widgets/home_widget_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar', null);

  final prefs = AppPreferences();
  await prefs.load();

  final offline = OfflineService();
  await offline.init();

  try {
    await HomeWidgetService().initialize();
  } catch (_) {}

  runApp(ATReservationsApp(prefs: prefs, offline: offline));
}

class ATReservationsApp extends StatelessWidget {
  final AppPreferences prefs;
  final OfflineService offline;
  const ATReservationsApp({
    super.key,
    required this.prefs,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider.value(value: prefs),
        ChangeNotifierProvider.value(value: offline),
      ],
      child: const _AppWithRouter(),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();
  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter>
    with WidgetsBindingObserver {
  late final _router = buildRouter(context.read<AuthProvider>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    context.read<ThemeProvider>().onPlatformBrightnessChanged();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final prefs = context.watch<AppPreferences>();
    final themeProv = context.watch<ThemeProvider>();

    return AnimatedTheme(
      data: themeProv.isDark ? buildATThemeDark() : buildATTheme(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: MaterialApp.router(
        title: 'AT Réservations',
        theme: buildATTheme(),
        darkTheme: buildATThemeDark(),
        themeMode: themeProv.themeMode,
        locale: prefs.locale,
        supportedLocales: const [Locale('fr'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
