import 'package:flutter/material.dart';
import 'package:storarch/constants.dart';
import 'Screens/signup_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // For potential form validation
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- Define Colors based on the image ---
  static const Color lightBeige = Color(0xFFD7CCC8); // Text, borders, button bg
  static const Color textBrown = Color(0xFFEFEBE9); // Main text color (off-white/light beige)
  static const Color primaryBrown = Color(0xFFFFFFFF);
  Color hintText = Colors.white70;
  Color accentBeige = const Color(0xFFD2B48C);
  static const Color lightText = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( // Allows scrolling on smaller screens
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
            child: Form( // Optional: Use Form for validation later
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: <Widget>[
                  // --- Logo ---
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.only(bottom: 30.0), // Add margin below logo
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
                          height: 1.2, // Line height
                        ),
                      ),
                    ),
                  
                  // Removed SizedBox after logo as margin is added above

                  // --- Title ---
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

                  // --- Subtitle ---
                  const Text(
                    'Welcome back! Please enter your details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: lightBeige, // Slightly dimmer color
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 35.0),

                  // --- Email Field ---
                  TextFormField(
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  style: const TextStyle(color: textBrown),
  decoration: InputDecoration(
    labelText: 'Email Address',
    labelStyle: TextStyle(color: hintText), // Your preferred color
   filled: true,
    fillColor: fillColor.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: accentBeige, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.white, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.8),
    ),
    hintStyle: TextStyle(color: lightBeige.withOpacity(0.6)),
  ),
  validator: (value) {
    if (value == null || value.isEmpty || !value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  },
),

                  const SizedBox(height: 10.0),

                  // --- Password Field ---
                  TextFormField(
  controller: _passwordController,
  obscureText: true, // Hide password input
  style: const TextStyle(color: textBrown),
  decoration: InputDecoration(
    labelText: 'Password',
    labelStyle: TextStyle(color: hintText), // Light color for placeholder text
    contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
    filled: true,
    fillColor: fillColor.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: accentBeige, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.white, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.8),
    ),
    hintStyle: TextStyle(color: lightBeige.withOpacity(0.6)),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  },
),

                  // --- Forgot Password ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement Forgot Password action
                        print('Forgot Password tapped');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Remove default padding
                        minimumSize: Size.zero, // Allow smaller size
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area
                        foregroundColor: lightBeige,
                      ),
                      child: const Text('Forgot Password'),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // --- Log In Button ---
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Login action
                      if (_formKey.currentState?.validate() ?? false) {
                        print('Logging in with:');
                        print('Email: ${_emailController.text}');
                        print('Password: ${_passwordController.text}');
                        // Example: Navigate to home screen after successful login
                        // Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor, // Button background
                      foregroundColor: primaryBrown, // Text color
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 150.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), // Highly rounded corners
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Log In'),
                  ),
                  const SizedBox(height: 25.0),

                  // --- Or Divider ---
                  Row(
                    children: <Widget>[
                      const Expanded(child: Divider(color: lightBeige, thickness: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or',
                          style: TextStyle(color: lightBeige.withOpacity(0.8)),
                        ),
                      ),
                      const Expanded(child: Divider(color: lightBeige, thickness: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 25.0),

                  // --- Log in with Google Button ---
                  ElevatedButton.icon(
                  icon: const Icon(Icons.android, color: lightText,), // Replace with actual Google icon if desired
                  // icon: FaIcon(FontAwesomeIcons.google, color: lightText, size: 18), // Example using font_awesome_flutter
                  label: const Text(
                    'Login with google',
                    style: TextStyle(color: lightText, fontSize: 16),
                  ),
                  onPressed: () {
                    // TODO: Implement Google Sign Up Logic
                    print('Google Sign Up Tapped');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appBackgroundColor.withOpacity(0.8), // Button background color
                    foregroundColor: lightText, // Text and icon color
                    // ignore: prefer_const_constructors
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 90,),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: borderColor.withOpacity(0.5), width: 2), // Border matching inputs
                    ),
                    elevation: 3, // Slight shadow
                  ),
                ),
                  const SizedBox(height: 30.0), // Space before register link

                  // --- Register Link ---
                   Align(
                    alignment: Alignment.center,
                    child: TextButton(
                       onPressed: () {
                         // TODO: Implement Register navigation/action
                         print('Register tapped - Navigating to SignUpScreen');
                          Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const SignUpScreen()),
                         );
                       },
                       style: TextButton.styleFrom(
                         padding: EdgeInsets.zero,
                         minimumSize: Size.zero,
                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                         foregroundColor: lightBeige.withOpacity(0.9), // Base text color
                       ),
                       child: RichText( // Use RichText to style parts differently
                         text: const TextSpan(
                           text: 'Already have an account? ', // Corrected spelling from image
                           style: TextStyle(
                               color: lightBeige,
                               fontSize: 14,
                               fontFamily: 'SansSerif' // Ensure font is consistent if needed
                           ), // Default style
                           children: <TextSpan>[
                             TextSpan(
                               text: 'Register', // Corrected spelling from image
                               style: TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.underline, 
                                 fontWeight: FontWeight.bold, // Make Register bold
                                 color: textBrown, // Make it slightly brighter
                                 // decoration: TextDecoration.underline, // Optional: Add underline
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
    );
  }
}