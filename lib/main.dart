import 'package:flutter/material.dart';
import '../screens/intro_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_screen.dart';
import '../screens/matchmaking_screen.dart';
import '../screens/account_screen.dart';
import '../screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talkio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/intro', // Start the app at the Intro Screen
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/matchmaking': (context) => const MatchmakingScreen(),
        '/account': (context) => const AccountScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
