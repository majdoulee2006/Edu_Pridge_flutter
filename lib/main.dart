import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/onboarding/onboarding_one.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.loadFromPrefs();
  runApp(const EduBridgeApp());
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.fontSize,
          builder: (context, fontScale, _) {
            return ValueListenableBuilder<String>(
              valueListenable: AppSettings.language,
              builder: (context, lang, _) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Edu-Bridge',
                  locale: Locale(lang),
                  supportedLocales: const [Locale('ar'), Locale('en')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                  theme: ThemeData(
                    primarySwatch: Colors.green,
                    fontFamily: 'Tajawal',
                    scaffoldBackgroundColor: const Color(0xFFF9F9F9),
                    cardColor: Colors.white,
                    brightness: Brightness.light,
                  ),
                  darkTheme: ThemeData(
                    primarySwatch: Colors.green,
                    fontFamily: 'Tajawal',
                    scaffoldBackgroundColor: const Color(0xFF121212),
                    cardColor: const Color(0xFF1E1E1E),
                    brightness: Brightness.dark,
                  ),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(fontScale),
                      ),
                      child: child!,
                    );
                  },
                  home: const OnboardingOne(),
                );
              },
            );
          },
        );
      },
    );
  }
}
