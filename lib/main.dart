import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seeker_app/screens/admin_screen.dart';
import 'package:seeker_app/screens/home_screen.dart';
import 'package:seeker_app/screens/login_screen.dart';
import 'package:seeker_app/screens/signup_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إذا كنت تقوم بتشغيل اختبارات الوحدة
  const bool isTesting = bool.fromEnvironment('dart.vm.product') == false;
  if (isTesting) {
    print("Running in a testing environment. Mocking Firebase setup...");
  } else {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => const LoginScreen(),
        'homeScreen': (context) => const HomeScreen(),
        'signupScreen': (context) => const SignupScreen(),
        'loginScreen': (context) => const LoginScreen(),
        'adminScreen': (context) => const AdminScreen(),
      },
    );
  }
}

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Future.microtask(
              () => Navigator.pushReplacementNamed(context, 'homeScreen'));
    } else {
      Future.microtask(
              () => Navigator.pushReplacementNamed(context, 'loginScreen'));
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
