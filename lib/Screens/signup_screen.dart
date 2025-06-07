// lib/signup_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:storarch/Screens/homepage_screen.dart';
import 'package:storarch/constants.dart';
import 'package:storarch/Screens/login_screen.dart';
// Optional: If you want to use a Google icon for the button
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//Potentially import your Login Screen file here later for navigation
// import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  // Optional: Add a const constructor if needed (good practice)
  const SignUpScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Approximate Colors from the image
    const Color primaryBrown = Color(0xFFFFFFFF); // white
    const Color accentBeige =
        Color(0xFFD2B48C); // Beige for primary button and borders
    const Color lightText = Colors.white;
    const Color hintText = Colors.white70;

    // Define common input decoration
    InputDecoration inputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: hintText),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 1.0, horizontal: 15.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: accentBeige, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
              color: Colors.white, width: 2.0), // Highlight focus
        ),
        filled: true, // Need filled = true to show fillColor
        fillColor: fillColor
            .withOpacity(0.05), // Match input background to main background
      );
    }

    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        // Avoid overlap with status bar/notches
        child: SingleChildScrollView(
          // Allow scrolling if content overflows (e.g., keyboard)
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // --- Logo ---
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
                      color: lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // --- Title ---
                const Text(
                  'Create An Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lightText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // --- Google Sign Up Button ---
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.android,
                    color: lightText,
                  ), // Replace with actual Google icon if desired
                  // icon: FaIcon(FontAwesomeIcons.google, color: lightText, size: 18), // Example using font_awesome_flutter
                  label: const Text(
                    'Create account with google',
                    style: TextStyle(color: lightText, fontSize: 16),
                  ),
                  onPressed: () {
                    // TO DO: Implement Google Sign Up Logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor, // Button background color
                    foregroundColor: lightText, // Text and icon color
                    // ignore: prefer_const_constructors
                    padding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                          color: borderColor.withOpacity(0.5),
                          width: 2), // Border matching inputs
                    ),
                    elevation: 3, // Slight shadow
                  ),
                ),
                const SizedBox(height: 20),

                // --- OR Separator ---
                const Row(
                  children: <Widget>[
                    Expanded(child: Divider(color: hintText, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Or',
                        style: TextStyle(color: hintText),
                      ),
                    ),
                    Expanded(child: Divider(color: hintText, thickness: 1)),
                  ],
                ),
                // ignore: prefer_const_constructors
                SizedBox(height: 20),

                // --- Email Field ---
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Email Address'),
                ),
                const SizedBox(height: 10),

                // --- Full Name Field ---
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Full Name'),
                ),
                const SizedBox(height: 10),

                // --- Password Field ---
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Hide password input
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Password'),
                ),
                const SizedBox(height: 10),

                // --- Confirm Password Field ---
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Confirm Password'),
                ),

                const SizedBox(height: 20),
                // --- Create Account Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_passwordController.text !=
                          _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Passwords do not match!')),
                        );
                        return;
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                HomePage(onToggleTheme: () {},  key: null, uploadedDocuments: const [],)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15), // Remove horizontal padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        color: primaryBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Login Link ---
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(color: hintText, fontSize: 14),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'LOGIN',
                          style: const TextStyle(
                              color: lightText, // Make LOGIN brighter/whiter
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration
                                  .underline, // Add underline like the image
                              fontSize: 14),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TO DO: Implement navigation to Login Screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()),
                              );
                              // Example: Replace with actual navigation
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                              // Or if login replaces signup in the stack:
                              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Add some padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
