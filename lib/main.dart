import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/performer_profile_screen.dart';
import 'screens/forgot_passwd_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/service_catalog_screen.dart';
import 'screens/addedit_service_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/my_jobs_screen.dart';
import 'screens/responses_screen.dart';
import 'screens/services_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkTheme = false;

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }

  // Функция для удобной передачи темы и callback'а в маршруты,
  // чтобы не дублировать каждый раз параметры в навигации.
  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/register':
        return MaterialPageRoute(builder: (_) =>  RegisterScreen());
      case '/forgot_password':
        return MaterialPageRoute(builder: (_) =>  ForgotPasswordScreen());
      case '/catalog':
        return MaterialPageRoute(
          builder: (_) => ServiceCatalogScreen(
            isDarkTheme: isDarkTheme,
            onToggleTheme: toggleTheme,
          ),
        );
      case '/add_service':
        return MaterialPageRoute(builder: (_) => const AddEditServiceScreen());
      case '/chat_list':
        return MaterialPageRoute(builder: (_) =>  ChatListScreen(
          isDarkTheme: isDarkTheme,
          onToggleTheme: toggleTheme,
        ));
      case '/performer_profile':
  final performerId = settings.arguments as String;
  return MaterialPageRoute(
    builder: (_) => PerformerProfileScreen(
      performerId: performerId,
      isDarkTheme: isDarkTheme,
      onToggleTheme: toggleTheme,
    ),
  );
      case '/map':
        return MaterialPageRoute(
          builder: (_) => ServicesMapScreen(
            isDarkTheme: isDarkTheme,
            onToggleTheme: toggleTheme,
          ),
        );
      case '/my_jobs':
        return MaterialPageRoute(builder: (_) => MyJobsScreen(
          isDarkTheme: isDarkTheme,
          onToggleTheme: toggleTheme,
        ));
      case '/responses':
        return MaterialPageRoute(builder: (_) => ResponsesScreen(
          isDarkTheme: isDarkTheme,
          onToggleTheme: toggleTheme,
        ));
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Агрегатор услуг',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(
        onToggleTheme: toggleTheme,
        isDarkTheme: isDarkTheme,
      ),
      onGenerateRoute: _generateRoute,
      // routes можно убрать, чтобы избежать конфликтов с onGenerateRoute
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkTheme;

  const AuthWrapper({
    super.key,
    required this.onToggleTheme,
    required this.isDarkTheme,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? firebaseUser;
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser!.uid).get();

    if (doc.exists) {
      userData = doc.data();
    } else {
      userData = {
        'userName': firebaseUser!.displayName ?? 'Пользователь',
        'userEmail': firebaseUser!.email ?? '',
        'userAvatarUrl': firebaseUser!.photoURL ?? '',
      };
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (firebaseUser == null) {
      return LoginScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkTheme: widget.isDarkTheme,
      );
    }

    return HomeScreen(
      userId: firebaseUser!.uid,
      userName: userData?['userName'] ?? 'Пользователь',
      userEmail: userData?['userEmail'] ?? '',
      userAvatarUrl: userData?['userAvatarUrl'] ?? '',
      onToggleTheme: widget.onToggleTheme,
      isDarkTheme: widget.isDarkTheme,
    );
  }
}
