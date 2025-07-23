import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chatroom_screen.dart'; 

class SupervisorChatListScreen extends StatefulWidget {
  const SupervisorChatListScreen({super.key});

  @override
  State<SupervisorChatListScreen> createState() =>
      _SupervisorChatListScreenState();
}

class _SupervisorChatListScreenState extends State<SupervisorChatListScreen> {
  final supabase = Supabase.instance.client;

  late final Future<List<Map<String, dynamic>>> _assignedStudentsFuture;

  late final String _supervisorId;

  @override
  void initState() {
    super.initState();
    // Ensures currentUser is not null before proceeding
    if (supabase.auth.currentUser == null) {
      
      _supervisorId = '';
      _assignedStudentsFuture = Future.value([]); 
      return;
    }

    _supervisorId = supabase.auth.currentUser!.id;
    _assignedStudentsFuture = _loadAssignedStudents();
  }

  Future<List<Map<String, dynamic>>> _loadAssignedStudents() async {
    try {
      
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error fetching students: $e"),
              backgroundColor: Colors.red),
        );
      }
      return []; 
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

          return 
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
                onTap: () {
                  final supervisorProfile =
                      supabase.auth.currentUser?.userMetadata;
                  final supervisorName =
                      supervisorProfile?['full_name'] as String? ??
                          'Supervisor';

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
