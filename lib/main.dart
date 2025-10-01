import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/tabs_controller.dart';
import 'providers/library_provider.dart';
import 'providers/theme_controller.dart';
import 'services/auth_service.dart';
import 'data/app_database.dart';
import 'splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/new_password_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // usa valores do .env ou os fixos que você passou
  const supabaseUrl = "https://osjfmilcvlefrsuittyq.supabase.co";
  const supabaseAnon =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zamZtaWxjdmxlZnJzdWl0dHlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4ODgwMjAsImV4cCI6MjA3NDQ2NDAyMH0.oGRcWoX7s64Z1BL0myufF5bzoTwfdyBN7dke5ORZOm4";

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);

  await AppDatabase.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabsController()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(
          create: (_) =>
              AuthService(Supabase.instance.client, navigatorKey: appNavigatorKey),
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entre Páginas',
      navigatorKey: appNavigatorKey,
      themeMode: themeCtrl.mode,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/new-password': (_) => const NewPasswordScreen(),
      },
    );
  }
}
