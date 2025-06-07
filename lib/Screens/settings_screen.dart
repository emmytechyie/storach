// lib/settings_screen.dart
import 'package:flutter/material.dart';
// For a real app, you'd likely use a state management solution or shared_preferences
// import 'package:shared_preferences/shared_preferences.dart';

// Example: To navigate back to Login screen after logout
// import 'login_page.dart'; // Assuming you have login_page.dart

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- Define Colors (reuse or adapt from your theme) ---
  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E); // For cards/sections
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color accentColor = Colors.blueAccent; // Or your app's accent
  static const Color iconColor = Colors.white70;
  
  // --- State Variables for Settings ---
  bool _notificationsEnabled = true; // Default or load from storage
  bool _isDarkModeEnabled = true; // Default or load from storage
  String _currentStudentLevel = '300 Level'; // Default or load from storage

  // Available student levels
  final List<String> _studentLevels = ['100 Level', '200 Level', '300 Level', '400 Level'];

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load initial settings (e.g., from SharedPreferences)
  }

  Future<void> _loadSettings() async {
    // TO DO: Replace with actual loading from SharedPreferences or backend
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    //   _isDarkModeEnabled = prefs.getBool('isDarkModeEnabled') ?? true;
    //   _currentStudentLevel = prefs.getString('studentLevel') ?? '300 Level';
    // });
    print("Settings loaded (mocked)");
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    // TO DO: Replace with actual saving to SharedPreferences or backend
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // if (value is bool) {
    //   await prefs.setBool(key, value);
    // } else if (value is String) {
    //   await prefs.setString(key, value);
    // }
    print("Setting '$key' saved with value '$value' (mocked)");
  }


  Future<void> _showChangeLevelDialog() async {
    String? selectedLevel = _currentStudentLevel; // Pre-select current level

    // If student is already at 400 level, maybe just show an info dialog
    if (_currentStudentLevel == '400 Level') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: darkSurfaceColor,
            title: const Text('Student Level', style: TextStyle(color: darkPrimaryText)),
            content: const Text('You are currently at the highest student level (400 Level).', style: TextStyle(color: darkSecondaryText)),
            actions: <Widget>[
              TextButton(
                child: const Text('OK', style: TextStyle(color: accentColor)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    // Allow changing to 400 level
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurfaceColor,
          title: const Text('Change Student Level', style: TextStyle(color: darkPrimaryText)),
          content: StatefulBuilder( // Use StatefulBuilder to update dialog state
            builder: (BuildContext context, StateSetter setStateDialog) {
              return DropdownButton<String>(
                value: selectedLevel,
                dropdownColor: darkSurfaceColor,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: iconColor),
                style: const TextStyle(color: darkPrimaryText),
                underline: Container(height: 1, color: darkSecondaryText.withOpacity(0.5)),
                items: _studentLevels.map((String level) {
                  // Only allow selecting "400 Level" if not already there, or current level
                  bool isSelectable = (level == '400 Level' || level == _currentStudentLevel);
                  return DropdownMenuItem<String>(
                    value: level,
                    enabled: isSelectable, // Disable other lower levels if already past them
                    child: Text(
                      level,
                      style: TextStyle(color: isSelectable ? darkPrimaryText : darkSecondaryText.withOpacity(0.5)),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setStateDialog(() {
                      selectedLevel = newValue;
                    });
                  }
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: darkSecondaryText)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirm', style: TextStyle(color: accentColor)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                if (selectedLevel != null && selectedLevel != _currentStudentLevel && selectedLevel == '400 Level') {
                  _confirmLevelChange(selectedLevel!);
                } else if (selectedLevel == _currentStudentLevel) {
                  // No change
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You can only upgrade to 400 Level from a lower level here.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLevelChange(String newLevel) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkSurfaceColor,
          title: const Text('Confirm Level Change', style: TextStyle(color: darkPrimaryText)),
          content: Text(
            'Are you sure you want to change your level to $newLevel? This may grant you access to new features and cannot be easily undone through this interface.',
            style: const TextStyle(color: darkSecondaryText),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: darkSecondaryText)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Confirm Change', style: TextStyle(color: accentColor)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _currentStudentLevel = newLevel;
      });
      _saveSetting('studentLevel', newLevel); // Save the new level
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student level updated to $newLevel! You may now access new features.')),
      );
      // TO DO: Potentially refresh app state or navigate to a specific screen
      // to reflect new feature access.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: darkPrimaryText)),
        backgroundColor: darkSurfaceColor,
        iconTheme: const IconThemeData(color: darkPrimaryText),
        elevation: 1,
      ),
      body: ListView(
        children: <Widget>[
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              // TO DO: Navigate to Edit Profile Screen
              print('Navigate to Edit Profile');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile Tapped (Placeholder)')));
            },
          ),
          _buildSettingsTile(
            icon: Icons.school_outlined,
            title: 'Student Level',
            currentValue: _currentStudentLevel,
            onTap: _showChangeLevelDialog,
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              // TO DO: Navigate to Change Password Screen
              print('Navigate to Change Password');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Change Password Tapped (Placeholder)')));
            },
          ),

          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notificationsEnabled', value);
            },
          ),
          // You could add more granular notification settings here

          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            icon: Icons.brightness_6_outlined, // Or Icons.dark_mode_outlined
            title: 'Dark Mode',
            subtitle: _isDarkModeEnabled ? 'Enabled' : 'Disabled',
            value: _isDarkModeEnabled,
            onChanged: (bool value) {
              setState(() => _isDarkModeEnabled = value);
              _saveSetting('isDarkModeEnabled', value);
              // TO DO: Actually apply theme change (e.g., using a ThemeProvider)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isDarkModeEnabled ? 'Dark Mode Enabled' : 'Dark Mode Disabled')),
              );
            },
          ),

          _buildSectionHeader('Help & Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center / FAQs',
            onTap: () {
              // TO DO: Open URL or navigate to FAQs screen
              print('Open Help Center');
            },
          ),
          _buildSettingsTile(
            icon: Icons.contact_support_outlined,
            title: 'Contact Support',
            onTap: () {
              // TO DO: Open email client or contact form
              print('Contact Support');
            },
          ),

          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            currentValue: '1.0.0', // Get from package_info_plus in real app
            onTap: null, // Non-interactive or show more details
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () { /* TO DO: Open URL */ print('Open Privacy Policy'); },
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () { /* TO DO: Open URL */ print('Open Terms of Service'); },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: darkSecondaryText.withOpacity(0.8),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? currentValue, // For displaying a value on the right
    VoidCallback? onTap,
  }) {
    return Material( // To get InkWell effect on the whole tile
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(color: darkPrimaryText, fontSize: 16)),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: darkSecondaryText.withOpacity(0.9), fontSize: 13))
            : null,
        trailing: currentValue != null
            ? Text(currentValue, style: const TextStyle(color: darkSecondaryText, fontSize: 15))
            : (onTap != null ? const Icon(Icons.chevron_right, color: iconColor) : null),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(color: darkPrimaryText, fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: darkSecondaryText.withOpacity(0.9), fontSize: 13))
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: accentColor,
      inactiveTrackColor: darkSecondaryText.withOpacity(0.3),
      inactiveThumbColor: darkSecondaryText.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }
}