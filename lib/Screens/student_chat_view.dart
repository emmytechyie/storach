import 'package:flutter/material.dart';
import 'package:storarch/Screens/chatroom_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentChatView extends StatefulWidget {
  const StudentChatView({super.key});

  @override
  State<StudentChatView> createState() => _StudentChatViewState();
}

class _StudentChatViewState extends State<StudentChatView> {
  @override
  void initState() {
    super.initState();
    // Start the process as soon as the widget is built
    _fetchSupervisorAndNavigate();
  }

  Future<void> _fetchSupervisorAndNavigate() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      // Handle case where user is not logged in
      _showError("You are not logged in.");
      return;
    }

    try {
      // Step 1: Get the current student's profile (we need their name)
      final studentProfile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', currentUser.id)
          .single();
      final studentName = studentProfile['full_name'] ?? 'Me';

      // Step 2: Find the supervisor assigned to this student
      final assignment = await supabase
          .from('supervisor_assignments')
          .select(
              'supervisor_id, profiles!supervisor_assignments_supervisor_id_fkey(full_name)')
          .eq('student_id', currentUser.id)
          .single();

      final supervisorId = assignment['supervisor_id'];
      final supervisorProfile = assignment['profiles'];
      final supervisorName = supervisorProfile?['full_name'] ?? 'Supervisor';

      if (!mounted) return;

      // Step 3: Navigate directly to the chat room with all the details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatroomScreen(
            isSupervisorView: false, // The student is viewing, so this is FALSE
            studentId: currentUser.id,
            studentName: studentName,
            supervisorName: supervisorName, supervisorInitial: '',
            chatPartnerName: '', supervisorId: '', String: null,
          ),
        ),
      );
    } catch (e) {
      // Handle errors, e.g., student has no supervisor assigned
      print("Error fetching supervisor: $e");
      _showError(
          "Could not find an assigned supervisor. Please contact an admin.");
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                // Pop the dialog and the chat view itself to return to the home page
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen will only show a loading indicator for a brief moment
    // before it automatically navigates away.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Opening chat..."),
          ],
        ),
      ),
    );
  }
}
