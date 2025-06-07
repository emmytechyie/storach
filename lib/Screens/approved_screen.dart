// lib/approved_topics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApprovedTopic {
  String id;
  String title;
  DateTime approvalDate;
  String approvedBy;

  ApprovedTopic({
    required this.id,
    required this.title,
    required this.approvalDate,
    required this.approvedBy,
  });
}

class ApprovedTopicsScreen extends StatefulWidget {
  const ApprovedTopicsScreen({super.key});

  @override
  State<ApprovedTopicsScreen> createState() => _ApprovedTopicsScreenState();
}

class _ApprovedTopicsScreenState extends State<ApprovedTopicsScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  void _confirmDelete(BuildContext context, ApprovedTopic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete "${topic.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _approvedTopics.removeWhere((t) => t.id == topic.id);
                _filteredTopics.removeWhere((t) => t.id == topic.id);
              });
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${topic.title}" has been deleted.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ApprovedTopic topic) {
    final titleController = TextEditingController(text: topic.title);
    final approvedByController = TextEditingController(text: topic.approvedBy);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurfaceColor,
        title: const Text('Edit Approved Topic',
            style: TextStyle(color: darkPrimaryText)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: darkPrimaryText),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: darkSecondaryText),
                ),
              ),
              TextField(
                controller: approvedByController,
                style: const TextStyle(color: darkPrimaryText),
                decoration: const InputDecoration(
                  labelText: 'Approved By',
                  labelStyle: TextStyle(color: darkSecondaryText),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: accentColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save', style: TextStyle(color: accentColor)),
            onPressed: () {
              setState(() {
                topic.title = titleController.text;
                topic.approvedBy = approvedByController.text;

                _approvedTopics.sort((a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                _filterTopics();
              });

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController approvedByController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkSurfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Approved Topic',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Project Title',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter project title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: approvedByController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Approved By',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter who approved this';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Add', style: TextStyle(color: Colors.black)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newTopic = ApprovedTopic(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    approvalDate: DateTime.now(),
                    approvedBy: approvedByController.text.trim(),
                  );

                  setState(() {
                    _approvedTopics.add(newTopic);
                    _approvedTopics.sort((a, b) =>
                        a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                    _filterTopics(); // refresh filtered list
                  });

                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Define Colors (reuse or adapt from your theme) ---
  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E); // For cards
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color accentColor = Colors.greenAccent; // For "approved" status
  static const Color iconColor = Colors.white70;

  final List<ApprovedTopic> _approvedTopics = [];

  List<ApprovedTopic> _filteredTopics = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredTopics = _approvedTopics;
    _searchController.addListener(_filterTopics);
  }

  void _filterTopics() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredTopics = _approvedTopics;
      });
    } else {
      setState(() {
        _filteredTopics = _approvedTopics
            .where((topic) =>
                topic.title.toLowerCase().contains(query) ||
                topic.approvedBy.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTopics);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Approved Topics',
            style: TextStyle(color: darkPrimaryText)),
        backgroundColor: darkSurfaceColor,
        iconTheme: const IconThemeData(color: darkPrimaryText),
        elevation: 1,
        // Optional: Add a search icon or direct search bar here if preferred
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _filteredTopics.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    itemCount: _filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = _filteredTopics[index];
                      return _buildTopicCard(topic);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: _showAddTopicDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: darkPrimaryText),
          decoration: InputDecoration(
            hintText: 'Search approved topics...',
            hintStyle: const TextStyle(color: darkSecondaryText),
            prefixIcon: const Icon(Icons.search, color: darkSecondaryText),
            filled: true,
            fillColor: darkSurfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: darkSecondaryText),
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus(); // 👈 Dismiss the keyboard
                    },
                  )
                : null,
          ),
        ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: darkSecondaryText.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? 'No Approved Topics Yet'
                : 'No topics match your search.',
            style: TextStyle(
                fontSize: 18, color: darkSecondaryText.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (_searchController.text.isEmpty)
            Text(
              'Approved research topics will appear here once available.',
              style: TextStyle(
                  fontSize: 14, color: darkSecondaryText.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(ApprovedTopic topic) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: accentColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        color: darkPrimaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: iconColor),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(topic);
                          break;
                        case 'copy':
                          final topicText = '''
${topic.title}

''';
                          Clipboard.setData(ClipboardData(text: topicText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Topic copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          break;
                        case 'delete':
                          _confirmDelete(context, topic);
                          break;
                      }
                    },
                    color: darkSurfaceColor,
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: iconColor),
                            SizedBox(width: 10),
                            Text('Edit',
                                style: TextStyle(color: darkPrimaryText)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: iconColor),
                            SizedBox(width: 10),
                            Text('Copy',
                                style: TextStyle(color: darkPrimaryText)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Approved by: ${topic.approvedBy}',
                        style: TextStyle(
                          color: darkSecondaryText.withOpacity(0.7),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Date: ${_formatDate(topic.approvalDate)}',
                      style: TextStyle(
                        color: darkSecondaryText.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
