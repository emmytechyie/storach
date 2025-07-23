import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _pendingUsers = [];
  List<dynamic> _allSupervisors = [];
  bool _isLoading = true;
  String? _error;

  // Maps to hold the state of dropdowns for each user card
  final Map<String, String?> _selectedStudentTypes = {};
  final Map<String, String?> _selectedSupervisors = {};

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    // Fetch both sets of data concurrently for faster loading
    await Future.wait([
      _fetchPendingRequests(),
      _fetchApprovedSupervisors(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('status', 'pending')
          .or('requested_role.eq.student,requested_role.eq.supervisor');
      if (mounted) {
        setState(() {
          _pendingUsers = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Failed to fetch pending requests: $e");
      }
    }
  }

  Future<void> _fetchApprovedSupervisors() async {
    try {
      final supabase = Supabase.instance.client;
      final supervisors = await supabase
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'supervisor')
          .eq('status', 'approved');
      if (mounted) {
        setState(() {
          _allSupervisors = supervisors;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Failed to fetch supervisors: $e");
      }
    }
  }

  Future<void> _approveUser(String id, String newRole,
      {String? studentType, String? assignedSupervisor}) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Approving user...'),
    ));

    try {
      // Single, atomic call to our new database function
      await Supabase.instance.client.rpc(
        'approve_and_assign_user',
        params: {
          'user_id_to_approve': id,
          'new_user_role': newRole,
          'new_student_type': studentType,
          'supervisor_to_assign': assignedSupervisor,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$newRole approved successfully!'),
          backgroundColor: Colors.green,
        ));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error approving user: ${e.message}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      // Refresh the dashboard data
      _initializeDashboard();
    }
  }

  Future<void> _rejectUser(String id) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'status': 'rejected'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User rejected'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error rejecting user: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      _initializeDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_pendingUsers.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.builder(
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final isStudent = user['requested_role'] == 'student';

    return StatefulBuilder(
      builder: (context, cardSetState) {
        // Get the currently selected student type for this specific card
        final currentSelectedType = _selectedStudentTypes[userId];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'Unnamed',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Role: ${user['requested_role']}'),
                Text('Matric No: ${user['matric_number'] ?? 'N/A'}'),
                if (isStudent) ...[
                  const SizedBox(height: 12),
                  // Dropdown for Student Type
                  DropdownButtonFormField<String>(
                    value: currentSelectedType,
                    decoration: const InputDecoration(
                      labelText: 'Assign Student Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Normal Student', 'Final Year Student']
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      cardSetState(() {
                        _selectedStudentTypes[userId] = value;
                        if (value != 'Final Year Student') {
                          _selectedSupervisors.remove(userId);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSupervisors[userId],
                    decoration: InputDecoration(
                      labelText: 'Assign Supervisor',
                      border: const OutlineInputBorder(),
                      hintText: currentSelectedType != 'Final Year Student'
                          ? 'Select Final Year Student first'
                          : '',
                    ),
                    items: _allSupervisors
                        .map<DropdownMenuItem<String>>(
                            (sup) => DropdownMenuItem(
                                  value: sup['id'],
                                  child: Text(sup['full_name'] ?? 'Unnamed'),
                                ))
                        .toList(),
                    // It only becomes active when the correct student type is selected.
                    onChanged: currentSelectedType == 'Final Year Student'
                        ? (value) {
                            cardSetState(() {
                              _selectedSupervisors[userId] = value;
                            });
                          }
                        : null,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        if (isStudent &&
                            _selectedStudentTypes[userId] == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Please assign the student type'),
                            backgroundColor: Colors.orange,
                          ));
                          return;
                        }
                        if (_selectedStudentTypes[userId] ==
                                'Final Year Student' &&
                            _selectedSupervisors[userId] == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Please assign a supervisor for a Final Year Student'),
                            backgroundColor: Colors.orange,
                          ));
                          return;
                        }

                        _approveUser(
                          userId,
                          user['requested_role'],
                          studentType: _selectedStudentTypes[userId],
                          assignedSupervisor: _selectedSupervisors[userId],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectUser(userId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
