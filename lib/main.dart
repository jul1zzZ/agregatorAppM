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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Агрегатор услуг',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
      routes: {
        '/register': (context) => RegisterScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/catalog': (context) => ServiceCatalogScreen(),
        '/add_service': (context) => AddEditServiceScreen(),
        '/chat_list': (context) => const ChatListScreen(),
        '/performer_profile': (context) => PerformerProfileScreen(
      performerId: ModalRoute.of(context)!.settings.arguments as String,
    ),
       '/map': (context) => ServicesMapScreen(),
        '/my_jobs': (context) => MyJobsScreen(), 
        '/responses': (context) => ResponsesScreen(), 
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

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
      // Если не залогинен, показываем LoginScreen
      setState(() {
        loading = false;
      });
      return;
    }

    // Берём данные пользователя из Firestore, коллекция 'users', документ - uid
    final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser!.uid).get();

    if (doc.exists) {
      userData = doc.data();
    } else {
      // Если данных нет, заполним по умолчанию из FirebaseUser
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
      // Пользователь не залогинен — показываем экран логина
      return LoginScreen();
    }

    // Пользователь залогинен — передаём данные в HomeScreen
    return HomeScreen(
      userId: firebaseUser!.uid,
      userName: userData?['userName'] ?? 'Пользователь',
      userEmail: userData?['userEmail'] ?? '',
      userAvatarUrl: userData?['userAvatarUrl'] ?? '',
    );
  }
}
