// lib/home_page.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:storarch/Screens/approved_screen.dart';
import 'package:storarch/Screens/settings_screen.dart';
import 'package:storarch/Screens/upload_screen.dart';
import 'package:storarch/Screens/login_screen.dart';
//import '../models/document.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomePage({
    super.key,
    required this.onToggleTheme,
    required List uploadedDocuments,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _bottomNavIndex = 0; // Start with 'Files' selected
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Define colors (approximations from the dark theme image)
  static const Color darkScaffoldBackground =
      Color(0xFF1F1F1F); // Very dark grey
  static const Color darkSurfaceColor =
      Color(0xFF2C2C2E); // Slightly lighter for cards/search
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color darkIconColor = Colors.white70;
  static const Color activeTabColor = Colors.blueAccent; // Or a light blue
  static const Color destructiveColor = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: _buildAppDrawer(),
      backgroundColor: darkScaffoldBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildTabs(),
                Expanded(
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight -
                                  140, // Adjust height as needed
                            ),
                            child: IntrinsicHeight(
                              child: _buildFileListView('Projects'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
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
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              const Expanded(
                child: TextField(
                  style: TextStyle(color: darkPrimaryText),
                  decoration: InputDecoration(
                    hintText: 'Search Project',
                    hintStyle: TextStyle(color: darkSecondaryText),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
        backgroundColor: darkSurfaceColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Custom header with less vertical space
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 34, 16, 12),
              child: Text(
                'STORACH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Divider immediately below the title
            const Divider(
              color: Colors.grey,
              thickness: 0.3,
              height: 1,
            ),

            ListTile(
              leading: const Icon(Icons.cloud_upload, color: darkIconColor),
              title: const Text('Upload',
                  style: TextStyle(color: darkPrimaryText)),
              onTap: () {
                Navigator.pop(context); // Close the drawer first

                // Delay navigation to allow drawer closing animation to finish
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UploadDocumentScreen()),
                  );
                });

                //print('Upload tapped');
              },
            ),

            ListTile(
              leading: const Icon(Icons.check_circle, color: darkIconColor),
              title: const Text('Approved Topics',
                  style: TextStyle(color: darkPrimaryText)),
              onTap: () {
                Navigator.pop(context);

                // Delay navigation to allow drawer closing animation to finish
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ApprovedTopicsScreen()),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: darkIconColor),
              title: const Text('Settings',
                  style: TextStyle(color: darkPrimaryText)),
              onTap: () {
                Navigator.pop(context);
                // Delay navigation to allow drawer closing animation to finish
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
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
            const SizedBox(height: 300.0),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextButton(
                onPressed: _logout,
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
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ));
  }

  Future<void> _logout() async {
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: darkSurfaceColor,
        title: const Text('Logout', style: TextStyle(color: darkPrimaryText)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: darkSecondaryText)),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: darkSecondaryText)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Logout', style: TextStyle(color: destructiveColor)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    // Navigate to login screen and remove all previous routes
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false, // Remove all previous routes
    );
    ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Successfully logged out.'),
    backgroundColor: Colors.green,
  ),
);

  }
}


  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: activeTabColor,
      unselectedLabelColor: darkSecondaryText,
      indicatorColor: activeTabColor,
      indicatorWeight: 3.0,
      tabs: const [
        Tab(text: 'Projects'),
      ],
    );
  }

  Widget _buildFileListView(String tabName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  print("Sort by Name tapped in $tabName tab");
                },
                icon: const Icon(Icons.arrow_upward,
                    size: 18, color: darkSecondaryText),
                label: const Text('Name',
                    style: TextStyle(color: darkSecondaryText)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
              IconButton(
                icon:
                    const Icon(Icons.grid_view_outlined, color: darkIconColor),
                onPressed: () {
                  print("Toggle view tapped in $tabName tab");
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 190),
        Center(
          child: Text(
            '$tabName Content Area',
            style: const TextStyle(
              fontSize: 20,
              color: darkSecondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        setState(() {
          _bottomNavIndex = index;
          // TO DO: Handle navigation or content change based on index
          if (index == 0) print("Home tapped");
          if (index == 1) print("Starred tapped");
          if (index == 2) print("ChatRoom tapped (current)");
        });
      },
      type: BottomNavigationBarType.fixed, // To show all labels
      backgroundColor: darkScaffoldBackground, // Match scaffold
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
}
