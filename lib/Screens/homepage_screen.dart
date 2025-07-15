// [FULL AND COMPLETE homepage_screen.dart]

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storarch/Screens/approved_screen.dart';
import 'package:storarch/Screens/settings_screen.dart';
import 'package:storarch/Screens/login_screen.dart';
import 'package:storarch/Screens/upload_screen.dart';
import 'package:storarch/Screens/admin_dashboard.dart';
import 'package:storarch/Screens/chat_router_screen.dart';
import 'package:storarch/Screens/edit_project_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

// Enum to manage the current layout state.
enum LayoutType { list, grid }

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String fullName;
  const HomePage({
    super.key,
    required this.onToggleTheme,
    required List uploadedDocuments,
    required this.fullName,
    required Function(dynamic context) builder,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  bool isLoadingProfile = true;

  Set<String> _supervisedStudentIds = {};
  Set<dynamic> _starredProjectIds = {};
  List<Map<String, dynamic>> _starredProjects = [];
  bool _isLoadingStarred = false;

  int _bottomNavIndex = 0;
  TabController? _tabController;

  final _searchController = TextEditingController();

  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color darkIconColor = Colors.white70;
  static const Color activeTabColor = Colors.blueAccent;
  static const Color destructiveColor = Colors.redAccent;
  static const Color starColor = Colors.amber;

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  StreamSubscription<List<Map<String, dynamic>>>? _projectSubscription;

  LayoutType _layout = LayoutType.list;
  int? _selectedYear;
  List<int> _availableYears = [];
  static const int _customYearSentinel = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _searchController.addListener(_applyFilters);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _projectSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA & STATE MANAGEMENT ---
  Future<void> _loadInitialData() async {
    await _loadUserProfile();
    if (userProfile != null) {
      await _loadInitialProjects();
      await _loadStarredProjectIds();
      _setupProjectStream();
    }
  }

  void _setupProjectStream() {
    _projectSubscription = Supabase.instance.client
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('uploaded_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            _updateProjectData(data);
          }
        });
  }

  void _updateProjectData(List<Map<String, dynamic>> projects) {
    final years = projects
        .map((p) => DateTime.parse(p['uploaded_at']).year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    setState(() {
      _projects = projects;
      _availableYears = years;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      Iterable<Map<String, dynamic>> tempProjects = _projects;
      if (_selectedYear != null) {
        tempProjects = tempProjects.where(
            (p) => DateTime.parse(p['uploaded_at']).year == _selectedYear);
      }
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        tempProjects = tempProjects.where((project) {
          final title = (project['title'] ?? '').toLowerCase();
          final studentName = (project['student_name'] ?? '').toLowerCase();
          final supervisor = (project['supervisor'] ?? '').toLowerCase();
          return title.contains(query) ||
              studentName.contains(query) ||
              supervisor.contains(query);
        });
      }
      _filteredProjects = tempProjects.toList();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        if (profileData != null) {
          setState(() {
            userProfile = profileData;
          });
          await _loadSupervisedStudentIds();
        } else {
          _showSnackbar('User profile not found. Please contact support.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Could not load user profile: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadInitialProjects() async {
    try {
      final data = await Supabase.instance.client
          .from('projects')
          .select('*')
          .order('uploaded_at', ascending: false);
      if (mounted) {
        _updateProjectData(List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Could not load projects: $e', isError: true);
      }
    }
  }

  Future<void> _deleteProject(Map<String, dynamic> project) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkSurfaceColor,
        title: const Text('Delete Project',
            style: TextStyle(color: darkPrimaryText)),
        content: const Text(
          'This action is permanent. Are you sure?',
          style: TextStyle(color: darkSecondaryText),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: darkSecondaryText)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child:
                const Text('Delete', style: TextStyle(color: destructiveColor)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final fileUrl = project['file_url'] as String?;
      if (fileUrl != null) {
        final filePath = Uri.parse(fileUrl).pathSegments.sublist(4).join('/');
        await Supabase.instance.client.storage
            .from('documents')
            .remove([filePath]);
      }
      await Supabase.instance.client
          .from('projects')
          .delete()
          .eq('id', project['id']);
      _showSnackbar('Project deleted successfully.');
    } catch (e) {
      _showSnackbar('Error deleting project: $e', isError: true);
    }
  }

  Future<void> openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('Could not launch the document.', isError: true);
      }
    } catch (e) {
      _showSnackbar('An error occurred: $e', isError: true);
    }
  }

  Future<void> _loadSupervisedStudentIds() async {
    if (userProfile?['role'] != 'supervisor') return;
    try {
      final supervisorId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('supervisor_assignments')
          .select('student_id')
          .eq('supervisor_id', supervisorId);
      if (mounted) {
        setState(() {
          _supervisedStudentIds =
              Set<String>.from(data.map((row) => row['student_id'] as String));
        });
      }
    } catch (e) {
      print("Could not load supervised student list: $e");
    }
  }

  Future<void> _loadStarredProjectIds() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('starred_projects')
          .select('project_id')
          .eq('user_id', userId);
      if (mounted) {
        setState(() {
          _starredProjectIds =
              Set<dynamic>.from(data.map((row) => row['project_id']));
        });
      }
    } catch (e) {
      _showSnackbar('Could not load starred projects: $e', isError: true);
    }
  }

  Future<void> _loadStarredProjects() async {
    if (_starredProjectIds.isEmpty) {
      if (mounted) setState(() => _starredProjects = []);
      return;
    }
    if (mounted) setState(() => _isLoadingStarred = true);
    try {
      final data = await Supabase.instance.client
          .from('projects')
          .select()
          .filter('id', 'in', '(${_starredProjectIds.toList().join(',')})')
          .order('uploaded_at', ascending: false);
      if (mounted) {
        setState(
            () => _starredProjects = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Could not load starred projects: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStarred = false);
      }
    }
  }

  Future<void> _toggleStarStatus(dynamic projectId) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final isStarred = _starredProjectIds.contains(projectId);
    try {
      if (isStarred) {
        await Supabase.instance.client
            .from('starred_projects')
            .delete()
            .match({'user_id': userId, 'project_id': projectId});
        setState(() {
          _starredProjectIds.remove(projectId);
          if (_bottomNavIndex == 1) {
            _starredProjects.removeWhere((p) => p['id'] == projectId);
          }
        });
      } else {
        await Supabase.instance.client
            .from('starred_projects')
            .insert({'user_id': userId, 'project_id': projectId});
        setState(() => _starredProjectIds.add(projectId));
      }
    } catch (e) {
      _showSnackbar('Could not update star status: $e', isError: true);
    }
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

  Future<void> _logout({bool force = false}) async {
    bool? confirmed = force;
    if (!force) {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: darkSurfaceColor,
            title:
                const Text('Logout', style: TextStyle(color: darkPrimaryText)),
            content: const Text('Are you sure you want to logout?',
                style: TextStyle(color: darkSecondaryText)),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(color: darkSecondaryText)),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Logout',
                    style: TextStyle(color: destructiveColor)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
    }

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // --- UI BUILDER METHODS ---

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return const Scaffold(
        backgroundColor: darkScaffoldBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userProfile == null) {
      return Scaffold(
        backgroundColor: darkScaffoldBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: destructiveColor, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Failed to Load Profile',
                  style: TextStyle(color: darkPrimaryText, fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'There was a problem retrieving your user data. Please contact support.',
                  style: TextStyle(color: darkSecondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => _logout(force: true),
                  child: const Text('Return to Login',
                      style: TextStyle(color: activeTabColor)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      drawer: _buildAppDrawer(),
      body: _buildBody(_bottomNavIndex),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return _buildMainHome();
      case 1:
        return SafeArea(child: _buildStarredListView());
      default:
        return _buildMainHome();
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatRouterScreen()),
          );
        } else {
          if (index == 1) _loadStarredProjects();
          setState(() => _bottomNavIndex = index);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: darkScaffoldBackground,
      selectedItemColor: activeTabColor,
      unselectedItemColor: darkSecondaryText,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.star_border_outlined),
            activeIcon: Icon(Icons.star),
            label: 'Starred'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'ChatRoom'),
      ],
    );
  }

  Widget _buildMainHome() {
    return SafeArea(
      child: Column(
        children: [
          _buildSearchBar(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildContentBody()],
            ),
          ),
        ],
      ),
    );
  }

  void _showYearInputDialog() {
    final formKey = GlobalKey<FormState>();
    final yearController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                labelStyle: TextStyle(color: darkSecondaryText)),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a year';
              if (value.length != 4) return 'Must be a 4-digit year';
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
            child:
                const Text('Cancel', style: TextStyle(color: activeTabColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Apply', style: TextStyle(color: activeTabColor)),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: darkSurfaceColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Builder(
          builder: (context) => Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: darkIconColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: darkPrimaryText),
                  decoration: const InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: TextStyle(color: darkSecondaryText),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: darkIconColor),
                  onPressed: () => _searchController.clear(),
                ),
            ],
          ),
        ),
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
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('All Years')),
        const PopupMenuItem<int?>(
          value: _customYearSentinel,
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 20, color: darkSecondaryText),
            SizedBox(width: 12),
            Text('Enter Year...'),
          ]),
        ),
        if (_availableYears.isNotEmpty) const PopupMenuDivider(),
        ..._availableYears.map((year) =>
            PopupMenuItem<int?>(value: year, child: Text(year.toString()))),
      ],
      icon: Icon(
        _selectedYear == null
            ? Icons.calendar_today_outlined
            : Icons.calendar_today,
        color: _selectedYear == null ? darkIconColor : activeTabColor,
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildYearFilterButton(),
          Expanded(
            child: TabBar(
              controller: _tabController,
              labelColor: activeTabColor,
              unselectedLabelColor: darkSecondaryText,
              indicatorColor: activeTabColor,
              indicatorWeight: 3.0,
              tabs: const [Tab(child: Center(child: Text('Projects')))],
            ),
          ),
          IconButton(
            icon: Icon(
                _layout == LayoutType.list
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
                color: darkIconColor),
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
    );
  }

  Widget _buildContentBody() {
    if (_filteredProjects.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty || _selectedYear != null
              ? 'No projects match your filters.'
              : 'No projects found.',
          style: const TextStyle(fontSize: 16, color: darkSecondaryText),
        ),
      );
    }
    if (_layout == LayoutType.list) {
      return _buildProjectListView(_filteredProjects);
    } else {
      return _buildProjectGridView(_filteredProjects);
    }
  }

  Widget _buildProjectListView(List<Map<String, dynamic>> projectsToDisplay) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: projectsToDisplay.length,
      itemBuilder: (context, index) {
        final project = projectsToDisplay[index];
        return _buildProjectListItem(project);
      },
    );
  }

  Widget _buildProjectGridView(List<Map<String, dynamic>> projectsToDisplay) {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: projectsToDisplay.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final project = projectsToDisplay[index];
        return _buildProjectGridItem(project);
      },
    );
  }

  Widget _buildProjectListItem(Map<String, dynamic> project) {
    final bool isStarred = _starredProjectIds.contains(project['id']);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: darkSurfaceColor,
      child: ListTile(
        leading: IconButton(
          icon: Icon(isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? starColor : darkIconColor),
          onPressed: () => _toggleStarStatus(project['id']),
        ),
        title: Text(project['title'] ?? 'Untitled',
            style: const TextStyle(color: darkPrimaryText)),
        subtitle: Text(
          'By: ${project['student_name'] ?? ''}\nSupervisor: ${project['supervisor'] ?? ''}',
          style: const TextStyle(color: darkSecondaryText),
        ),
        onTap: () {
          final url = project['file_url'];
          if (url != null && url.toString().isNotEmpty) {
            openInBrowser(url);
          } else {
            _showSnackbar('File URL is missing', isError: true);
          }
        },
        trailing: _buildProjectItemMenu(project),
      ),
    );
  }

  Widget _buildProjectGridItem(Map<String, dynamic> project) {
    final bool isStarred = _starredProjectIds.contains(project['id']);
    final menu = _buildProjectItemMenu(project, isGrid: true);
    return Card(
      color: darkSurfaceColor,
      child: InkWell(
        onTap: () {
          final url = project['file_url'];
          if (url != null && url.toString().isNotEmpty) {
            openInBrowser(url);
          } else {
            _showSnackbar('File URL is missing', isError: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['title'] ?? 'Untitled',
                    style: const TextStyle(
                        color: darkPrimaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By: ${project['student_name'] ?? 'N/A'}',
                    style: TextStyle(
                        color: darkSecondaryText.withOpacity(0.7),
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(isStarred ? Icons.star : Icons.star_border,
                        color: isStarred ? starColor : darkIconColor, size: 20),
                    onPressed: () => _toggleStarStatus(project['id']),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (menu != null) menu,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildProjectItemMenu(Map<String, dynamic> project,
      {bool isGrid = false}) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final projectAuthorId = project['user_id'];
    final bool isAuthor = projectAuthorId == currentUserId;
    final bool isSupervisorForThisProject =
        _supervisedStudentIds.contains(projectAuthorId);
    final bool canEditOrDelete = isAuthor || isSupervisorForThisProject;
    if (!canEditOrDelete) return null;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: darkIconColor),
      padding: isGrid ? EdgeInsets.zero : const EdgeInsets.all(8.0),
      color: darkSurfaceColor,
      onSelected: (value) {
        if (value == 'delete') {
          _deleteProject(project);
        } else if (value == 'edit') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditProjectScreen(project: project)));
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, color: darkPrimaryText, size: 22),
            SizedBox(width: 10),
            Text('Edit', style: TextStyle(color: darkPrimaryText))
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, color: destructiveColor, size: 22),
            SizedBox(width: 10),
            Text('Delete', style: TextStyle(color: destructiveColor))
          ]),
        ),
      ],
    );
  }

  Widget _buildStarredListView() {
    Widget content;
    if (_isLoadingStarred) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_starredProjects.isEmpty) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 60, color: darkSecondaryText),
            SizedBox(height: 16),
            Text(
              'No Starred Projects',
              style: TextStyle(fontSize: 18, color: darkSecondaryText),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the star icon on a project to save it here.',
              style: TextStyle(color: darkSecondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      content = _buildProjectListView(_starredProjects);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'Starred Projects',
              style: TextStyle(
                color: darkPrimaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  // ✅ THIS IS THE ONLY METHOD THAT HAS BEEN MODIFIED
  Widget _buildAppDrawer() {
    // Get the user's role and student_type from the 'userProfile' map that is already loaded.
    final userRole = userProfile?['role'] as String?;
    final studentType = userProfile?['student_type'] as String?;

    // Define a clear condition for who can see the project tools.
    // This is true if the user is a supervisor, an admin, OR a final year student.
    final bool canAccessProjectFeatures = (userRole == 'supervisor' ||
        userRole == 'super_admin' ||
        studentType == 'Final Year Student');

    return Drawer(
      backgroundColor: darkSurfaceColor,
      child: Column(
        // Using a Column + Expanded to push logout to the bottom
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 48, 16, 12),
                  child: Text(
                    'STORACH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.grey, thickness: 0.3, height: 1),

                // Wrap the protected features in the 'if' condition
                if (canAccessProjectFeatures) ...[
                  ListTile(
                    leading:
                        const Icon(Icons.cloud_upload, color: darkIconColor),
                    title: const Text('Upload',
                        style: TextStyle(color: darkPrimaryText)),
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const UploadDocumentScreen(),
                            ),
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: darkIconColor),
                    title: const Text('Approved Topics',
                        style: TextStyle(color: darkPrimaryText)),
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ApprovedTopicsScreen()),
                          );
                        }
                      });
                    },
                  ),
                ],

                // --- The rest of the items are visible to everyone ---
                ListTile(
                  leading: const Icon(Icons.settings, color: darkIconColor),
                  title: const Text('Settings',
                      style: TextStyle(color: darkPrimaryText)),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: darkIconColor),
                  title: const Text('Help & Feedback',
                      style: TextStyle(color: darkPrimaryText)),
                  onTap: () {
                    Navigator.pop(context);
                    print('Help tapped');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined,
                      color: darkIconColor),
                  title: const Text('Contact Support',
                      style: TextStyle(color: darkPrimaryText)),
                  onTap: () {
                    Navigator.pop(context);
                    print('Contact tapped');
                  },
                ),
                if (userRole == 'super_admin') ...[
                  const Divider(color: Colors.grey, thickness: 0.3, height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings,
                        color: darkIconColor),
                    title: const Text('Admin Dashboard',
                        style: TextStyle(color: darkPrimaryText)),
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AdminDashboard()),
                          );
                        }
                      });
                    },
                  ),
                ],
                const Divider(color: Colors.grey, thickness: 0.3, height: 1),
                ExpansionTile(
                  leading: const Icon(Icons.info_outline, color: darkIconColor),
                  title: const Text('About',
                      style: TextStyle(color: darkPrimaryText)),
                  collapsedIconColor: darkIconColor,
                  iconColor: darkIconColor,
                  children: [
                    ListTile(
                      title: const Text('App Version',
                          style: TextStyle(color: darkSecondaryText)),
                      trailing: const Text(
                        'v1.0.0',
                        style: TextStyle(color: darkSecondaryText),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showAboutDialog(
                          context: context,
                          applicationVersion: '1.0.0',
                          applicationName: 'StorArch',
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Privacy Policy',
                          style: TextStyle(color: darkSecondaryText)),
                      onTap: () {
                        Navigator.pop(context);
                        print('Privacy Policy tapped');
                      },
                    ),
                    ListTile(
                      title: const Text('Terms of Service',
                          style: TextStyle(color: darkSecondaryText)),
                      onTap: () {
                        Navigator.pop(context);
                        print('Terms of Service tapped');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // This ensures the logout button is always at the bottom
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: TextButton(
              onPressed: () => _logout(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: darkSurfaceColor.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: destructiveColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
