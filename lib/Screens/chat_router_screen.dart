import 'package:flutter/material.dart';
import 'package:storarch/Screens/SupervisorChatListScreen.dart';
import 'package:storarch/Screens/student_chat_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRouterScreen extends StatefulWidget {
  const ChatRouterScreen({super.key});

  @override
  State<ChatRouterScreen> createState() => _ChatRouterScreenState();
}

class _ChatRouterScreenState extends State<ChatRouterScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>?> _fetchUserRole() async {
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
      future: _userRoleV2Future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final role = snapshot.data?['role'];

        if (role == 'supervisor') {
          return const SupervisorChatListScreen();
        } else if (role == 'student') {
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

  // You can keep your original name.
  late final Future<Map<String, dynamic>?> _userRoleV2Future = _fetchUserRole();
}
