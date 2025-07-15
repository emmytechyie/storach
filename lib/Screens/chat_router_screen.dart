import 'package:flutter/material.dart';
import 'package:storarch/Screens/SupervisorChatListScreen.dart';
// ✅ Import the new student chat view
import 'package:storarch/Screens/student_chat_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRouterScreen extends StatefulWidget {
  const ChatRouterScreen({super.key});

  @override
  State<ChatRouterScreen> createState() => _ChatRouterScreenState();
}

class _ChatRouterScreenState extends State<ChatRouterScreen> {
  late final Future<Map<String, dynamic>?> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _fetchUserRole();
  }

  Future<Map<String, dynamic>?> _fetchUserRole() async {
    // ... (this function remains the same, no changes needed)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return profile;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userRoleV2Future, // Changed variable name to avoid conflict
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final role = snapshot.data?['role'];

        if (role == 'supervisor') {
          return const SupervisorChatListScreen();
        } else if (role == 'student') {
          // ✅ FIX: Use the new, smart StudentChatView.
          // This widget will handle fetching the supervisor and navigating.
          // CORRECT
          return const StudentChatView();
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text("Chat")),
            body: const Center(
              child: Text("Chat is available for students and supervisors."),
            ),
          );
        }
      },
    );
  }

  // Renamed the future to avoid conflict if you copy-paste multiple times.
  // You can keep your original name.
  late final Future<Map<String, dynamic>?> _userRoleV2Future = _fetchUserRole();
}
