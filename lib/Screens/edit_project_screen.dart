// lib/Screens/edit_project_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _supervisorController;
  late final TextEditingController _titleController;
  bool _isLoading = false;

  // Reusing your theme colors
  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color activeColor = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    // Pre-populate the text controllers with the existing project data
    _nameController =
        TextEditingController(text: widget.project['student_name'] ?? '');
    _supervisorController =
        TextEditingController(text: widget.project['supervisor'] ?? '');
    _titleController =
        TextEditingController(text: widget.project['title'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _supervisorController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _updateProjectDetails() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Prepare the data to be updated
      final updatedData = {
        'student_name': _nameController.text.trim(),
        'supervisor': _supervisorController.text.trim(),
        'title': _titleController.text.trim(),
      };

      // 3. Perform the update operation in Supabase
      await Supabase.instance.client
          .from('projects')
          .update(updatedData)
          .eq('id', widget.project['id']);

      _showSnackbar('Project details updated successfully!');

      // 4. Go back to the previous screen on success
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackbar('Failed to update project: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Edit Project Details',
            style: TextStyle(color: darkPrimaryText)),
        backgroundColor: darkSurfaceColor,
        iconTheme: const IconThemeData(color: darkPrimaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: darkPrimaryText),
                decoration: _inputDecoration("Student's Name"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _supervisorController,
                style: const TextStyle(color: darkPrimaryText),
                decoration: _inputDecoration("Project Supervisor's Name"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a supervisor'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: darkPrimaryText),
                decoration: _inputDecoration('Title of the Project'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProjectDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: darkSecondaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: darkSecondaryText.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: darkSecondaryText.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: activeColor, width: 1.5),
      ),
      filled: true,
      fillColor: darkSurfaceColor.withOpacity(0.5),
    );
  }
}
