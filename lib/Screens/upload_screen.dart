import 'dart:io'; // Required for File type
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:storarch/Screens/homepage_screen.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _statusMessage = "No project selected.";
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  // --- Define Colors (you can reuse colors from your theme or define new ones) ---
  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color activeColor = Colors.blueAccent;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'jpg',
          'png'
        ], // Specify allowed types
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _statusMessage = "Selected: $_fileName";
          _uploadProgress = 0.0; // Reset progress
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error picking file: $e";
      });
    }
  }

  Future<void> _uploadFile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first!")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = "Uploading $_fileName...";
      _uploadProgress = 0.0;
    });

    // --- Simulate Upload ---
    // In a real app, you would use http.MultipartRequest or a similar method
    // to send the file to your backend.
    try {
      // Simulate progress
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(
            const Duration(milliseconds: 200)); // Simulate network delay
        if (!mounted) return; // Check if widget is still in the tree
        setState(() {
          _uploadProgress = i / 10.0;
        });
      }

      // Simulate successful upload
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => HomePage(
      onToggleTheme: () {}, uploadedDocuments: const [],
    ),
  ),
);
      }
      setState(() {
        _statusMessage = "$_fileName uploaded successfully!";
        //Colors.green; // ✅ Set background color to green
        _selectedFile = null;
        _fileName = null;
        _descriptionController.clear();
        _uploadProgress = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_statusMessage)),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Upload failed: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Upload Project',
            style: TextStyle(color: darkPrimaryText)),
        backgroundColor: darkSurfaceColor,
        iconTheme:
            const IconThemeData(color: darkPrimaryText), // For back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 10),
              // --- File Picker Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Select Document'),
                onPressed: _isUploading ? null : _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              const SizedBox(height: 5.0),

              // --- Selected File Info & Status ---
              if (_fileName != null || _isUploading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _statusMessage,
                      style:
                          const TextStyle(color: darkPrimaryText, fontSize: 15),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: darkSecondaryText.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(activeColor),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            color: darkSecondaryText, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              if (_fileName == null &&
                  !_isUploading) // Show default status if nothing is happening
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: darkSecondaryText, fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 44.0),

              //Document Description
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isUploading,
                      style: const TextStyle(color: darkPrimaryText),
                      decoration: _inputDecoration('Your Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter your name'
                              : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Supervisor Name
                    TextFormField(
                      controller: _supervisorController,
                      enabled: !_isUploading,
                      style: const TextStyle(color: darkPrimaryText),
                      decoration:
                          _inputDecoration('Project Supervisor\'s Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter supervisor\'s name'
                              : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Project Title
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isUploading,
                      style: const TextStyle(color: darkPrimaryText),
                      decoration: _inputDecoration('Title of the Project'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter the project title'
                              : null,
                    ),
                    const SizedBox(height: 30.0),
                  ],
                ),
              ),

              const SizedBox(height: 30.0),

              //  Upload Button
              if (_selectedFile != null) ...[
                ElevatedButton.icon(
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _isUploading ? 'UPLOADING...' : 'UPLOAD DOCUMENT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: (_selectedFile == null || _isUploading)
                      ? null
                      : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // ✅ Always green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    textStyle: const TextStyle(fontSize: 16),
                    disabledBackgroundColor:
                        Colors.green, // ✅ Keep green even when disabled
                    disabledForegroundColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ]),
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