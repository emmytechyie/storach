import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum to manage the current layout state.
enum LayoutType { list, grid }

class ApprovedTopic {
  String id;
  String title;
  DateTime approvalDate;
  String approvedBy;
  String? userId; // Owner of the topic

  ApprovedTopic({
    required this.id,
    required this.title,
    required this.approvalDate,
    required this.approvedBy,
    this.userId,
  });

  factory ApprovedTopic.fromMap(Map<String, dynamic> map) {
    return ApprovedTopic(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      approvedBy: map['approved_by'] ?? '',
      approvalDate: DateTime.parse(map['approval_date']),
      userId: map['user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return {
      'id': id,
      'title': title,
      'approved_by': approvedBy,
      'approval_date': approvalDate.toIso8601String(),
      'user_id': userId,
    };
  }
}

class ApprovedTopicsScreen extends StatefulWidget {
  const ApprovedTopicsScreen({super.key});

  @override
  State<ApprovedTopicsScreen> createState() => _ApprovedTopicsScreenState();
}

class _ApprovedTopicsScreenState extends State<ApprovedTopicsScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color accentColor = Colors.greenAccent;
  static const Color iconColor = Colors.white70;

  final List<ApprovedTopic> _approvedTopics = [];
  List<ApprovedTopic> _filteredTopics = [];

  bool _isLoading = true;
  String? _currentUserRole;

  // State variables for layout and filtering.
  LayoutType _layout = LayoutType.list;
  int? _selectedYear;
  List<int> _availableYears = [];

  // A sentinel value to identify the "Enter Year" menu option.
  static const int _customYearSentinel = -1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([
      _fetchCurrentUserRole(),
      _fetchApprovedTopics(),
    ]);

    _setupRealtimeSubscription();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCurrentUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _currentUserRole = response['role'];
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching user role: $e');
        setState(() => _currentUserRole = 'final_year_student');
      }
    }
  }

  void _setupRealtimeSubscription() {
    Supabase.instance.client
        .channel('public:approved_topics')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'approved_topics',
          callback: (payload) async {
            if (mounted) {
              await _fetchApprovedTopics();
            }
          },
        )
        .subscribe();
  }

  // A centralized function to apply all active filters.
  void _applyFilters() {
    setState(() {
      Iterable<ApprovedTopic> tempTopics = _approvedTopics;

      if (_selectedYear != null) {
        tempTopics = tempTopics
            .where((topic) => topic.approvalDate.year == _selectedYear);
      }

      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        tempTopics = tempTopics.where((topic) {
          return topic.title.toLowerCase().contains(query) ||
              topic.approvedBy.toLowerCase().contains(query);
        });
      }

      _filteredTopics = tempTopics.toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _searchFocusNode.dispose();
    Supabase.instance.client.removeChannel(
        Supabase.instance.client.channel('public:approved_topics'));
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  Future<void> _fetchApprovedTopics() async {
    try {
      final response = await Supabase.instance.client
          .from('approved_topics')
          .select()
          .order('approval_date', ascending: false);

      if (mounted) {
        final topics = (response as List)
            .map((item) => ApprovedTopic.fromMap(item))
            .toList();

        final years = topics.map((t) => t.approvalDate.year).toSet().toList();
        years.sort((a, b) => b.compareTo(a));

        setState(() {
          _approvedTopics.clear();
          _approvedTopics.addAll(topics);
          _availableYears = years;
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint('Error fetching topics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load topics.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // DIALOGS (Add, Edit, Delete, Year Input)

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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('approved_topics')
                    .delete()
                    .eq('id', topic.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${topic.title}" deleted.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting topic: $e')),
                );
              }
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
            onPressed: () async {
              Navigator.of(context).pop();
              final updatedTitle = titleController.text.trim();
              final updatedApprovedBy = approvedByController.text.trim();
              try {
                await Supabase.instance.client.from('approved_topics').update({
                  'title': updatedTitle,
                  'approved_by': updatedApprovedBy,
                }).eq('id', topic.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Topic updated successfully.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating topic: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final approvedByController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: darkSurfaceColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add',
                          style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);

                      final currentUserId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (currentUserId == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error: Not logged in.')),
                        );
                        setState(() => isLoading = false);
                        return;
                      }

                      try {
                        await Supabase.instance.client
                            .from('approved_topics')
                            .insert({
                          'title': titleController.text.trim(),
                          'approved_by': approvedByController.text.trim(),
                          'approval_date': DateTime.now().toIso8601String(),
                          'user_id': currentUserId,
                        });

                        await _fetchApprovedTopics();

                        if (!mounted) return;
                        Navigator.pop(context);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding topic: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showYearInputDialog() {
    final formKey = GlobalKey<FormState>();
    final yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkSurfaceColor,
          title: const Text('Filter by Year',
              style: TextStyle(color: darkPrimaryText)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: yearController,
              autofocus: true,
              style: const TextStyle(color: darkPrimaryText),
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit year',
                labelStyle: TextStyle(color: darkSecondaryText),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a year';
                }
                if (value.length != 4) {
                  return 'Must be a 4-digit year';
                }
                final year = int.tryParse(value);
                if (year == null ||
                    year < 1990 ||
                    year > DateTime.now().year + 5) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: accentColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Apply', style: TextStyle(color: accentColor)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newYear = int.parse(yearController.text);
                  setState(() {
                    _selectedYear = newYear;
                    _applyFilters();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // UI BUILDER METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Approved Topics',
            style: TextStyle(color: darkPrimaryText)),
        backgroundColor: darkSurfaceColor,
        iconTheme: const IconThemeData(color: darkPrimaryText),
        actions: [
          _buildYearFilterButton(),
          IconButton(
            icon: Icon(_layout == LayoutType.list
                ? Icons.grid_view_rounded
                : Icons.view_list_rounded),
            onPressed: () {
              setState(() {
                _layout = _layout == LayoutType.list
                    ? LayoutType.grid
                    : LayoutType.list;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _filteredTopics.isEmpty
                      ? _buildEmptyState()
                      : _buildContent(),
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

  Widget _buildYearFilterButton() {
    return PopupMenuButton<int?>(
      onSelected: (int? year) {
        if (year == _customYearSentinel) {
          _showYearInputDialog();
        } else {
          setState(() {
            _selectedYear = year;
            _applyFilters();
          });
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<int?>> items = [];
        items.add(
          const PopupMenuItem<int?>(
            value: null,
            child: Text('All Years'),
          ),
        );
        items.add(
          const PopupMenuItem<int?>(
            value: _customYearSentinel,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20, color: darkSecondaryText),
                SizedBox(width: 12),
                Text('Enter Year...'),
              ],
            ),
          ),
        );
        items.add(const PopupMenuDivider());

        for (final year in _availableYears) {
          items.add(
            PopupMenuItem<int?>(
              value: year,
              child: Text(year.toString()),
            ),
          );
        }
        return items;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Chip(
          backgroundColor: darkSurfaceColor,
          label: Text(
            _selectedYear?.toString() ?? 'All Years',
            style: const TextStyle(color: darkSecondaryText),
          ),
          avatar: const Icon(Icons.calendar_today,
              size: 16, color: darkSecondaryText),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_layout == LayoutType.list) {
      return _buildListView();
    } else {
      return _buildGridView();
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      itemCount: _filteredTopics.length,
      itemBuilder: (context, index) {
        return _buildTopicCard(_filteredTopics[index]);
      },
    );
  }

  Widget _buildGridView() {
    // Get the total screen width and subtract padding to find available space.
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 12.0;
    final spacing = 12.0;
    final availableWidth = screenWidth - (horizontalPadding * 2) - spacing;
    final itemWidth = availableWidth / 2;

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Wrap(
        spacing: spacing, // Horizontal space between items
        runSpacing: spacing, // Vertical space between rows
        children: _filteredTopics.map((topic) {
          // Each item is given a fixed width, and its height will be determined
          // by its content.
          return SizedBox(
            width: itemWidth,
            child: _buildTopicGridItem(topic),
          );
        }).toList(),
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
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    bool isFiltering =
        _selectedYear != null || _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              isFiltering
                  ? Icons.filter_alt_off_outlined
                  : Icons.check_circle_outline,
              size: 80,
              color: darkSecondaryText.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            isFiltering
                ? 'No topics match your filters.'
                : 'No Approved Topics Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, color: darkSecondaryText.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(ApprovedTopic topic) {
    return Card(
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          topic.title,
          style: const TextStyle(
              color: darkPrimaryText, fontWeight: FontWeight.bold),
          // maxLines and overflow removed to show full title
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By: ${topic.approvedBy}',
                  style: TextStyle(
                      color: darkSecondaryText.withOpacity(0.7), fontSize: 11)),
              const SizedBox(height: 4),
              Text('Date: ${_formatDate(topic.approvalDate)}',
                  style: TextStyle(
                      color: darkSecondaryText.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ),
        trailing: _buildItemMenu(topic),
      ),
    );
  }

  Widget _buildTopicGridItem(ApprovedTopic topic) {
    return Card(
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        // This Column will now be as tall as its children need it to be.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text content
            Text(
              topic.title,
              style: const TextStyle(
                  color: darkPrimaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'By: ${topic.approvedBy}',
              style: TextStyle(
                  color: darkSecondaryText.withOpacity(0.7), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(topic.approvalDate),
              style: TextStyle(
                  color: darkSecondaryText.withOpacity(0.7), fontSize: 11),
            ),
            const SizedBox(height: 8), // Add some space before the menu
            // Menu button at the end
            Align(
              alignment: Alignment.bottomRight,
              child: _buildItemMenu(topic, isGrid: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildItemMenu(ApprovedTopic topic, {bool isGrid = false}) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool canModify =
        (_currentUserRole == 'supervisor' || topic.userId == currentUserId);

    if (!canModify) return null;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: iconColor),
      padding: isGrid ? EdgeInsets.zero : const EdgeInsets.all(8.0),
      onSelected: (value) {
        if (value == 'edit') _showEditDialog(topic);
        if (value == 'copy') {
          Clipboard.setData(ClipboardData(text: topic.title));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic copied to clipboard')),
          );
        }
        if (value == 'delete') _confirmDelete(context, topic);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
      ],
    );
  }
}
