import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chatroom_screen.dart'; // Make sure this path is correct

class SupervisorChatListScreen extends StatefulWidget {
  const SupervisorChatListScreen({super.key});

  @override
  State<SupervisorChatListScreen> createState() =>
      _SupervisorChatListScreenState();
}

class _SupervisorChatListScreenState extends State<SupervisorChatListScreen> {
  // ✅ CHANGE: Made the supabase client final for good practice
  final supabase = Supabase.instance.client;

  // ✅ CHANGE: Using a FutureBuilder is a more robust Flutter pattern
  // This avoids managing _isLoading and _students state variables separately.
  late final Future<List<Map<String, dynamic>>> _assignedStudentsFuture;

  // ✅ CHANGE: Get the supervisor's ID once and store it.
  late final String _supervisorId;

  @override
  void initState() {
    super.initState();
    // Ensures currentUser is not null before proceeding
    if (supabase.auth.currentUser == null) {
      // Handle case where user is not logged in, maybe redirect to login
      // For now, we'll initialize with an empty future to avoid errors.
      _supervisorId = '';
      _assignedStudentsFuture = Future.value([]); // Return an empty list
      return;
    }

    _supervisorId = supabase.auth.currentUser!.id;
    _assignedStudentsFuture = _loadAssignedStudents();
  }

  Future<List<Map<String, dynamic>>> _loadAssignedStudents() async {
    try {
      // The query itself was very good! No changes needed here.
      final data = await supabase
          .from('supervisor_assignments')
          // This tells Supabase: "Join profiles using the foreign key on our 'student_id' column"
          .select('*, student_profile:profiles!student_id(full_name)')
          .eq('supervisor_id', _supervisorId);

      // Helpful for debugging to see what the database returns
      print("📦 Fetched Assigned students data: $data");

      // Supabase returns a List<dynamic>, so we cast it safely.
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("❌ Error loading assigned students: $e");
      // Show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error fetching students: $e"),
              backgroundColor: Colors.red),
        );
      }
      return []; // Return an empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Students"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _assignedStudentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("An error occurred: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No students have been assigned to you yet."));
          }

          final students = snapshot.data!;

          return // Find the ListView.builder inside your SupervisorChatListScreen's build method
// and replace it with this entire block.

              ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final assignment = students[index];
              final studentId = assignment['student_id'];

              // Safely parse the student's name from the new structure
              final profileData =
                  assignment['student_profile'] as Map<String, dynamic>?;
              final studentName =
                  profileData?['full_name'] as String? ?? "Unnamed Student";

              return ListTile(
                leading: CircleAvatar(
                    child: Text(studentName.isNotEmpty ? studentName[0] : 'U')),
                title: Text(studentName),
                subtitle: const Text("Tap to open chat"),
                trailing: const Icon(Icons.chat_bubble_outline),
                // IN: SupervisorChatListScreen.dart

// ... inside your ListView.builder ...
                onTap: () {
                  // We need the supervisor's name. Let's get it from the user profile.
                  // Note: For this to be perfect, you should fetch the supervisor's name
                  // in initState, but for now, we can use the email as a placeholder.
                  final supervisorProfile =
                      supabase.auth.currentUser?.userMetadata;
                  final supervisorName =
                      supervisorProfile?['full_name'] as String? ??
                          'Supervisor';

                  // --- THIS IS THE NEW, CORRECT NAVIGATION LOGIC ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatroomScreen(
                        // The four required parameters for the new constructor:
                        isSupervisorView: true,
                        studentId: studentId,
                        studentName: studentName,
                        supervisorName: supervisorName,
                        supervisorInitial: '',
                        chatPartnerName: '',
                        supervisorId: '',
                        String: null, // Pass the actual supervisor name
                      ),
                    ),
                  );
                },
// ...
              );
            },
          );
        },
      ),
    );
  }
}
