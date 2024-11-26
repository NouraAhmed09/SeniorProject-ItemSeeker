import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = "";

  Future<void> signIn() async {
    if (!mounted) return;

    setState(() {
      _errorMessage = '';
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final roleId = userDoc['role_id'];
          final isActive = userDoc['isActive'];

          if (!isActive) {
            setState(() {
              _errorMessage =
              'Your account has been deactivated by the admin. Please contact support.';
            });
            return;
          }

          if (roleId == 1) {
            Navigator.of(context).pushReplacementNamed('adminScreen');
          } else if (roleId == 2) {
            Navigator.of(context).pushReplacementNamed('homeScreen');
          } else {
            setState(() {
              _errorMessage = 'Unknown role. Please contact support.';
            });
          }
        } else {
          setState(() {
            _errorMessage =
            'Your account has been deleted. Please contact support.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'No user found for that email';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Incorrect password for that email';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again later.';
      });
    }
  }

  void openSignupScreen() {
    Navigator.of(context).pushReplacementNamed('signupScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/itemseeker.jpg',
                key: const Key('loginImage'), // مفتاح للصورة
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                "SIGN IN",
                key: const Key('loginTitle'), // مفتاح لعنوان الشاشة
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoCondensed(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 230, 230, 230),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      key: const Key('emailField'), // مفتاح لحقل البريد الإلكتروني
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Email',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 230, 230, 230),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      key: const Key('passwordField'), // مفتاح لحقل كلمة المرور
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Password',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    key: const Key('errorMessage'), // مفتاح لرسالة الخطأ
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: signIn,
                  child: Container(
                    key: const Key('signInButton'), // مفتاح لزر تسجيل الدخول
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.robotoCondensed(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member? ',
                    key: const Key('signupPrompt'), // مفتاح لنص "Not a member?"
                    style: GoogleFonts.robotoCondensed(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: openSignupScreen,
                    child: Text(
                      'Sign up now',
                      key: const Key('signupNow'), // مفتاح لنص "Sign up now"
                      style: GoogleFonts.robotoCondensed(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
