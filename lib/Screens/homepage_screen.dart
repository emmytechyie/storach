// lib/home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
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
  static const Color darkScaffoldBackground = Color(0xFF1F1F1F); // Very dark grey
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);    // Slightly lighter for cards/search
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color darkIconColor = Colors.white70;
  static const Color activeTabColor = Colors.blueAccent; // Or a light blue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(),
      backgroundColor: darkScaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFileListView('Projects'),
                ],
              ),
            ),
          ],
        ),
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
          builder: (context) =>
        Row(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 34, 16, 12),
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
          title: const Text('Upload', style: TextStyle(color: darkPrimaryText)),
          onTap: () {
            Navigator.pop(context);
            print('Upload tapped');
          },
        ),
        ListTile(
          leading: const Icon(Icons.check_circle, color: darkIconColor),
          title: const Text('Approved Topics', style: TextStyle(color: darkPrimaryText)),
          onTap: () {
            Navigator.pop(context);
            print('Approved tapped');
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: darkIconColor),
          title: const Text('Settings', style: TextStyle(color: darkPrimaryText)),
          onTap: () {
            Navigator.pop(context);
            print('Settings tapped');
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline, color: darkIconColor),
          title: const Text('Help & Feedback', style: TextStyle(color: darkPrimaryText)),
          onTap: () {
            Navigator.pop(context);
            print('Help tapped');
          },
        ),
        ListTile(
          leading: const Icon(Icons.brightness_6, color: darkIconColor),
          title: const Text('Light/Dark Mode', style: TextStyle(color: darkPrimaryText)),
          onTap: () {
            Navigator.pop(context);
            print('Toggle Theme tapped');
          },
        ),
      ],
    ),
  );
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
              icon: const Icon(Icons.arrow_upward, size: 18, color: darkSecondaryText),
              label: const Text('Name', style: TextStyle(color: darkSecondaryText)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
            IconButton(
              icon: const Icon(Icons.grid_view_outlined, color: darkIconColor),
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
          style: const TextStyle(fontSize: 20, color: darkSecondaryText,),
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
          // TODO: Handle navigation or content change based on index
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
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.star_border_outlined), activeIcon: Icon(Icons.star), label: 'Starred'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'ChatRoom'),
      ],
    );
  }
}