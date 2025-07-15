// [CORRECTED AND FINAL StudentDashboard.dart]
// Please replace the entire content of your file with this code.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storarch/screens/homepage_screen.dart';

// 1. IMPORT YOUR ACTUAL SCREEN FILES
// Make sure the paths are correct for your project structure.
import 'package:storarch/screens/upload_screen.dart';
import 'package:storarch/screens/approved_screen.dart'; // I see you named your widget 'Approved', so this file likely contains it.

// Note: We have deleted the placeholder classes `UploadTopicScreen` and `ApprovedTopicScreen`
// because we are now importing and using your real screens.

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final supabase = Supabase.instance.client;
  bool _isFinalYearStudent = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    // ✅ ADD THIS LINE
    print("--- StudentDashboard initState has started! ---");

    super.initState();
    _checkStudentStatus();
  }

  /// Fetches the 'student_type' column and checks if the value is 'Final Year Student'.
  // In _StudentDashboardState...

  Future<void> _checkStudentStatus() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw 'User is not logged in.';
      }

      final data = await supabase
          .from('profiles')
          .select('student_type')
          .eq('id', userId)
          .single();

      // ✅ --- ADD THIS DEBUGGING LINE ---
      print(
          "DATABASE CHECK: Raw value for 'student_type' is: ->'${data['student_type']}'<-");
      // The arrows ->' '<- will make invisible spaces visible.
      // ------------------------------------

      if (mounted) {
        bool isFinalYear = false; // Default to false

        // We will make the check more robust
        if (data['student_type'] != null &&
            data['student_type'].toString().trim() == 'Final Year Student') {
          isFinalYear = true;
        }

        // ✅ --- ADD THIS SECOND DEBUGGING LINE ---
        print(
            "LOGIC CHECK: Is this user a Final Year Student? -> $isFinalYear");
        // ------------------------------------------

        setState(() {
          _isFinalYearStudent = isFinalYear;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("ERROR during student status check: $e");
        setState(() {
          _errorMessage = 'Could not verify student status: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_const_constructors
      backgroundColor: Color(0xFF03182C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03182C),
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const Text(
                      'Project Management',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // The core access control logic is here
                    _buildFeatureCard(
                      title: 'Upload Project Topic',
                      icon: Icons.upload_file,
                      isEnabled: _isFinalYearStudent,
                      onTap: () {
                        // 2. NAVIGATE TO YOUR REAL WIDGET
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const UploadDocumentScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      title: 'View Approved Topic',
                      icon: Icons.check_circle_outline,
                      isEnabled: _isFinalYearStudent,
                      onTap: () {
                        // 2. NAVIGATE TO YOUR REAL WIDGET
                        // From your code, it looks like your widget is named 'Approved'.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ApprovedTopicsScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'General',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      // ✅ RENAMED FOR CLARITY
                      title: 'Proceed to Homepage',
                      icon: Icons.home_outlined, // Changed the icon to match
                      isEnabled: true,
                      onTap: () {
                        // ✅ THIS IS THE CORRECTED LOGIC

                        // 1. Get the current user's full name from Supabase auth metadata
                        final fullName = Supabase.instance.client.auth
                                .currentUser?.userMetadata?['full_name'] ??
                            'Student';

                        // 2. Navigate to your existing HomePage, passing the required parameters
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              onToggleTheme:
                                  () {}, // Pass the required functions/parameters
                              uploadedDocuments: const [],
                              fullName: fullName,
                              builder: (context) {},
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  /// A reusable widget to build the feature cards, showing a disabled state.
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    if (!isEnabled) {
      return Opacity(
        opacity: 0.5,
        child: Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: const Text('Available for Final Year Students only'),
            trailing: const Icon(Icons.lock),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
