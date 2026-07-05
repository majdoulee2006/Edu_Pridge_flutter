import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'screens/onboarding/onboarding_one.dart';
import 'screens/student/nav_bar/student_home_screen.dart';
import 'screens/teacher/teacher_home.dart';
import 'screens/parents/nav_bar/parent_home.dart';
import 'screens/Head of department/nav_bar/boss_home.dart';
import 'screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:edu_pridge_flutter/services/chat_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init(); // 🌟 كشف السيرفر تلقائياً عند التشغيل
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAgT4rvWSyvaDbHujMmZTDDUZn2xMnts5M",
        authDomain: "edu-bridge-246fd.firebaseapp.com",
        projectId: "edu-bridge-246fd",
        storageBucket: "edu-bridge-246fd.firebasestorage.app",
        messagingSenderId: "1087208747554",
        appId: "1:1087208747554:web:ab689779c18d1872f9107b",
        measurementId: "G-7NNSYEDPYB",
      ),
    );
    await FcmService.initWeb();
  } else {
    await Firebase.initializeApp();
    await FcmService.init();
  }
  await AppSettings.loadFromPrefs();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatService(),
      child: const EduBridgeApp(),
    ),
  );
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final role  = prefs.getString('role')  ?? '';
    final userId = prefs.getString('user_id') ?? '';
    
    if (!mounted) return;
    
    // Initialize Pusher if logged in
    if (token.isNotEmpty && userId.isNotEmpty) {
      context.read<ChatService>().initPusher(userId);
    }

    final Widget dest;
    if (token.isEmpty) {
      dest = const OnboardingOne();
    } else {
      dest = switch (role.toLowerCase()) {
        'student' => const StudentHomeScreen(),
        'teacher' => const TeacherHomeScreen(),
        'parent' => const ParentsHomeScreen(),
        'department_head' || 'boss' || 'head' => const DeptHeadHomeScreen(),
        'affairs_officer' || 'affairs' => const AffairsOfficerHomeScreen(),
        _ => const OnboardingOne(),
      };
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
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
                  navigatorKey: appNavigatorKey,
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
                    scaffoldBackgroundColor: const Color(0xFFE8E8EE), // خلفية رمادية دافئة
                    cardColor: const Color(0xFFF2F2F7),              // كارد أغمق من الأبيض
                    brightness: Brightness.light,
                    dividerColor: const Color(0xFFD0D0DA),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(color: Color(0xFF1C1C1E)),
                      bodyMedium: TextStyle(color: Color(0xFF3A3A3C)),
                    ),
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
                  home: const _AppRouter(),
                );
              },
            );
          },
        );
      },
    );
  }
}
