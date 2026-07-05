import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'services/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar', null);

  // Charge les preferences avant de demarrer l'app
  final prefs = AppPreferences();
  await prefs.load();

  runApp(ATReservationsApp(prefs: prefs));
}

class ATReservationsApp extends StatelessWidget {
  final AppPreferences prefs;
  const ATReservationsApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: prefs),
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

class _AppWithRouterState extends State<_AppWithRouter> {
  late final _router = buildRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>(); // rebuild sur auth
    final prefs = context.watch<AppPreferences>(); // rebuild sur theme/locale
    return MaterialApp.router(
      title:           'AT Réservations',
      theme:           buildATTheme(),
      darkTheme:       buildATThemeDark(),
      themeMode:       prefs.themeMode,
      locale:          prefs.locale,
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig:    _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
