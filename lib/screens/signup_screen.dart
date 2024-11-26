import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();

  String _errorMessage = '';

  Future<void> signUp() async {
    setState(() {
      _errorMessage = '';
    });

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _fullNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (!_isValidSaudiPhoneNumber(_phoneController.text.trim())) {
      setState(() {
        _errorMessage = 'Enter a valid Saudi phone number starting with +966';
      });
      return;
    }

    if (!_isValidFullName(_fullNameController.text.trim())) {
      setState(() {
        _errorMessage = 'Full name should only contain letters and spaces';
      });
      return;
    }

    if (!passwordConfirmed()) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password should be at least 6 characters';
      });
      return;
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role_id': 2,
          'isActive': true,
        });

        print("Sign-up successful! User ID: ${userCredential.user?.uid}");

        Navigator.of(context).pushReplacementNamed('loginScreen');
      } else {
        setState(() {
          _errorMessage = 'Unexpected issue with user creation.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email is already in use. Please try another one.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Password is too weak. Choose a stronger password.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Invalid email address. Please enter a valid email.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    }
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() ==
        _confirmPasswordController.text.trim();
  }

  bool _isValidSaudiPhoneNumber(String phone) {
    final saudiPhoneRegExp = RegExp(r'^\+9665\d{8}$');
    return saudiPhoneRegExp.hasMatch(phone);
  }

  bool _isValidFullName(String name) {
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegExp.hasMatch(name);
  }

  void openLoginScreen() {
    Navigator.of(context).pushReplacementNamed('loginScreen');
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
              const SizedBox(height: 20),
              Image.asset(
                'images/itemseeker.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              Text(
                "SIGN UP",
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoCondensed(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "",
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    filled: true,
                    fillColor: Color.fromARGB(255, 230, 230, 230),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Color.fromARGB(255, 230, 230, 230),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    hintText: 'Phone (+9665XXXXXXXX)',
                    filled: true,
                    fillColor: Color.fromARGB(255, 230, 230, 230),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Color.fromARGB(255, 230, 230, 230),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirm Password',
                    filled: true,
                    fillColor: Color.fromARGB(255, 230, 230, 230),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: signUp,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Sign Up',
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
                    'Already a member?',
                    style: GoogleFonts.robotoCondensed(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: openLoginScreen,
                    child: Text(
                      'Sign in here',
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
