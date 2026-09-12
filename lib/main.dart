// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/settings/appearance_screen.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ نقراو آخر وضع محفوظ (نهاري/ليلي) قبل ما نرندريو التطبيق،
  // باش يبان بالوضع الصحيح مجرد ما يبدا (بلا "ومضة" وضع خاطئ).
  await AppThemeController.load();

  runApp(const TawafuqApp());
}

class TawafuqApp extends StatelessWidget {
  const TawafuqApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ValueListenableBuilder كيسمع لـ AppThemeController.themeMode:
    // أي تبديل وضع من AppearanceScreen (via AppThemeController.setMode)
    // كيبدّل themeMode.value، وهنا كيعاود يبني MaterialApp فوريا
    // بالثيم الجديد فـ كامل التطبيق.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tawafuq',
          themeMode: mode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kDarkGreen,
        brightness: Brightness.light,
        primary: kDarkGreen,
        secondary: kGold,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBg,
        foregroundColor: kDarkGreen,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkSurface = Color(0xFF11241C);
    const darkBg = Color(0xFF0B1712);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kDarkGreen,
        brightness: Brightness.dark,
        primary: kGold,
        secondary: kGold,
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
