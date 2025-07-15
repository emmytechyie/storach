// [FINAL and COMPLETE LoginPage.dart]

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:storarch/Screens/studentDashboard.dart'; // Import for the student's new home
import 'package:storarch/Screens/homepage_screen.dart'; // Import for the supervisor's home
import 'package:storarch/constants.dart';
import 'signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password_screen.dart'; // ADDED: Import the new screen

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordObscured = true;

  // --- UI Constants ---
  static const Color lightBeige = Color(0xFFD7CCC8);
  static const Color textBrown = Color(0xFFEFEBE9);
  static const Color primaryBrown = Color(0xFFFFFFFF);
  Color hintText = Colors.white70;
  Color accentBeige = const Color(0xFFD2B48C);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// This new function checks the user's role and navigates them to the correct screen.
  Future<void> _handleLogin(AuthResponse response) async {
    if (!mounted) return;

    try {
      final userId = response.user!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role') // You can also select 'status' here if needed
          .eq('id', userId)
          .single();

      final role = data['role'];
      final fullName = response.user?.userMetadata?['full_name'] ?? 'User';

      if (!mounted) return;

      if (role == 'student') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const StudentDashboard(),
          ),
          (route) => false,
        );
      } else if (role == 'supervisor' || role == 'super_admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomePage(
              onToggleTheme: () {}, // Pass your actual theme function
              uploadedDocuments: const [],
              fullName: fullName,
              builder: (context) {}, // Pass the correct variable
            ),
          ),
          (route) => false,
        );
      } else {
        _showError(context,
            'Your user role is not configured. Please contact support.');
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      _showError(context, 'Could not retrieve user profile. Please try again.');
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      margin: const EdgeInsets.only(bottom: 30.0),
                      decoration: BoxDecoration(
                        color: const Color(0x8088BDF2),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: const Text(
                        'STOR\nARCH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textBrown,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const Text(
                      'Login to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textBrown,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    const Text(
                      'Welcome back! Please enter your details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: lightBeige,
                        fontSize: 14.0,
                      ),
                    ),
                    const SizedBox(height: 35.0),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: textBrown),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: hintText),
                        filled: true,
                        fillColor: fillColor.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              BorderSide(color: accentBeige, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2.0),
                        ),
                        hintStyle:
                            TextStyle(color: lightBeige.withOpacity(0.6)),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscured,
                      style: const TextStyle(color: textBrown),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: hintText),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 15.0),
                        filled: true,
                        fillColor: fillColor.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              BorderSide(color: accentBeige, width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2.0),
                        ),
                        hintStyle:
                            TextStyle(color: lightBeige.withOpacity(0.6)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: hintText,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        // --- MODIFIED ---
                        onPressed: () {
                          // Navigate to the Forgot Password screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        // --- END OF MODIFICATION ---
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: lightBeige,
                        ),
                        child: const Text('Forgot Password'),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    final response = await Supabase
                                        .instance.client.auth
                                        .signInWithPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    );

                                    if (response.user != null) {
                                      await _handleLogin(response);
                                    } else {
                                      _showError(context,
                                          'Login failed. Please try again.');
                                    }
                                  } on AuthException catch (e) {
                                    _showError(context, e.message);
                                  } catch (e) {
                                    _showError(context,
                                        'An unexpected error occurred.');
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: primaryBrown,
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 25.0),
                    Row(
                      children: <Widget>[
                        const Expanded(
                            child: Divider(color: lightBeige, thickness: 0.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or',
                            style:
                                TextStyle(color: lightBeige.withOpacity(0.8)),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: lightBeige, thickness: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: lightBeige.withOpacity(0.9),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: lightBeige,
                              fontSize: 14,
                              fontFamily: 'SansSerif',
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                  color: textBrown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
