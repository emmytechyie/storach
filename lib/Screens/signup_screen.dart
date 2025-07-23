import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:storarch/Screens/pending_approval_screen.dart';
import 'package:storarch/constants.dart';
import 'package:storarch/Screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _matricController = TextEditingController();
  bool _isLoading = false;

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  String requestedRole = 'student';
  static const dropdownTextStyle = TextStyle(color: Colors.white);
  User? _newlyCreatedUser;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _matricController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 1.0, horizontal: 15.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFFD2B48C), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.white, width: 2.0),
      ),
      filled: true,
      fillColor: fillColor.withOpacity(0.05),
    );
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final fullName = _nameController.text.trim();
    final matricNumber = _matricController.text.trim();

    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')));
      return;
    }
    if (requestedRole == 'student' && matricNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Matric number is required for students.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        setState(() {
          _newlyCreatedUser = response.user;
        });
        if (!mounted) return;
        _showVerificationDialog(fullName, matricNumber);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Signup failed: Could not create user.')));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signup failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- THIS IS THE CORRECTED METHOD ---
  void _showVerificationDialog(String fullName, String matricNumber) {
    bool isVerifying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // StatefulBuilder allows the dialog to have its own state for the loading indicator
        return StatefulBuilder(builder: (context, setStateInDialog) {
          return AlertDialog(
            title: const Text('Verify Your Email'),
            content: const Text(
                'A verification link has been sent to your email. Please check your inbox and verify before continuing.'),
            actions: [
              isVerifying
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ))
                  : TextButton(
                      onPressed: () async {
                        setStateInDialog(() {
                          isVerifying = true;
                        });

                        try {
                          // Step 1: Temporarily sign in the user.
                          // This will FAIL if they haven't clicked the email link yet
                          // This gives us a valid session to write to the 'profiles' table.
                          final authResponse = await Supabase
                              .instance.client.auth
                              .signInWithPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                          if (authResponse.user != null) {
                            // Now that we are authenticated, create the user's profile.
                            await Supabase.instance.client
                                .from('profiles')
                                .upsert({
                              'id': authResponse.user!.id,
                              'full_name': fullName,
                              'requested_role': requestedRole,
                              'matric_number':
                                  matricNumber.isEmpty ? null : matricNumber,
                              'role': requestedRole,
                              'status': 'pending', // Set status to pending
                            });

                            // IMPORTANT! Immediately sign the user out.
                            // This removes their session so they cannot access the main app.
                            await Supabase.instance.client.auth.signOut();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Email verified! Your account is pending admin approval.'),
                              backgroundColor: Colors.green,
                            ));

                            // Navigate to the pending screen.
                            Navigator.of(context).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PendingApprovalScreen()),
                              (route) => false,
                            );
                          }
                        } on AuthException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Verification Failed: ${e.message}. Please ensure you have clicked the link in your email."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("An error occurred: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          // Ensure the loading indicator is always turned off
                          if (mounted) {
                            setStateInDialog(() {
                              isVerifying = false;
                            });
                          }
                        }
                      },
                      child: const Text('I HAVE VERIFIED'),
                    ),
              TextButton(
                onPressed: () async {
                  try {
                    await Supabase.instance.client.auth.resend(
                      type: OtpType.signup,
                      email: _emailController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Verification email resent.')));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resend: $e')));
                  }
                },
                child: const Text('RESEND LINK'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color lightText = Colors.white;
    const Color hintText = Colors.white70;

    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                margin: const EdgeInsets.only(bottom: 5.0),
                decoration: BoxDecoration(
                  color: const Color(0x8088BDF2),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: const Text('STOR\nARCH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2)),
              ),
              const Text('Create An Account',
                  style: TextStyle(
                      color: lightText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Email Address')),
              const SizedBox(height: 10),
              TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Full Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Password').copyWith(
                      suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70),
                          onPressed: () => setState(() =>
                              _isPasswordObscured = !_isPasswordObscured)))),
              const SizedBox(height: 10),
              TextField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  style: const TextStyle(color: lightText),
                  decoration: inputDecoration('Confirm Password').copyWith(
                      suffixIcon: IconButton(
                          icon: Icon(
                              _isConfirmPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70),
                          onPressed: () => setState(() =>
                              _isConfirmPasswordObscured =
                                  !_isConfirmPasswordObscured)))),
              const SizedBox(height: 10),
              _buildDropdown<String>(
                  value: requestedRole,
                  items: ['student', 'supervisor'],
                  onChanged: (value) => setState(() => requestedRole = value!)),
              const SizedBox(height: 10.0),
              if (requestedRole == 'student')
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TextField(
                      controller: _matricController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration('Matric Number')),
                ),
              const SizedBox(height: 10),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              elevation: 5),
                          child: const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
              RichText(
                  text: TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(color: hintText, fontSize: 14),
                      children: [
                    TextSpan(
                        text: 'LOGIN',
                        style: const TextStyle(
                            color: lightText,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 14),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage())))
                  ])),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: fillColor.withOpacity(0.05),
        border: Border.all(color: const Color(0xFFD2B48C), width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: DropdownButton<String>(
          dropdownColor: appBackgroundColor,
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isExpanded: true,
          underline: const SizedBox(),
          style: dropdownTextStyle,
          items: items
              .map((item) => DropdownMenuItem(
                  value: item, child: Text(item, style: dropdownTextStyle)))
              .toList(),
          onChanged: onChanged),
    );
  }
}
