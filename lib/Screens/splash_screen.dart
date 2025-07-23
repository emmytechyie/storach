import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storarch/Screens/homepage_screen.dart';
import 'package:storarch/Screens/login_screen.dart';
import 'package:storarch/Screens/pending_approval_screen.dart';
import 'package:storarch/Screens/reset_password_screen.dart';
import 'package:storarch/Screens/studentDashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // ✅ Listen for password recovery link (deep link)
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        print("🔐 Password recovery event triggered");
        _navigateToResetScreen();
      }
    });

    // ✅ Start normal splash logic
    _handleStartupLogic();

    // ✅ Handle runtime deep links (warm start)
    AppLinks().uriLinkStream.listen((uri) {
      print("📡 Runtime deep link: $uri");
      // Do nothing here — Supabase handles this via the above listener
    });
  }

  Future<void> _handleStartupLogic() async {
    try {
      final appLinks = AppLinks();
      final initialLink = await appLinks.getInitialLink();
      print("🔗 Initial link: $initialLink");

      // Supabase will catch this link and emit AuthChangeEvent
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        print("➡️ No session. Navigating to login.");
        _navigateToLogin();
      } else {
        print("🔐 Active session detected.");
        await _redirectBasedOnSession(session.user);
      }
    } catch (e, stack) {
      print("🚨 Splash error: $e\n$stack");
      _navigateToLogin();
    }
  }

  Future<void> _redirectBasedOnSession(User user) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, status')
          .eq('id', user.id)
          .single();

      final role = profile['role'];
      final status = profile['status'];
      final fullName = user.userMetadata?['full_name'] ?? 'User';

      if (status == 'pending') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false,
        );
      } else if (status == 'approved') {
        if (role == 'student') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
            (route) => false,
          );
        } else if (role == 'supervisor' || role == 'super_admin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => HomePage(
                onToggleTheme: () {},
                uploadedDocuments: const [],
                fullName: fullName,
                builder: (_) {},
              ),
            ),
            (route) => false,
          );
        } else {
          throw Exception('Unknown role');
        }
      } else {
        throw Exception('Unknown status');
      }
    } catch (e) {
      print("⚠️ Failed to route based on profile: $e");
      await Supabase.instance.client.auth.signOut();
      _navigateToLogin();
    }
  }

  void _navigateToResetScreen() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
