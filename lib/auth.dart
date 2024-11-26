import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seeker_app/screens/home_screen.dart';
import 'package:seeker_app/screens/login_screen.dart';

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
