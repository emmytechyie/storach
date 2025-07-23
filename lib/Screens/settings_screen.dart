import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // UI Colors
  static const Color darkScaffoldBackground = Color(0xFF1F1F1F);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;
  static const Color accentColor = Colors.blueAccent;
  static const Color iconColor = Colors.white70;

  // State Variables
  bool _isLoading = true;
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  /// Fetches the user's basic profile from Supabase.
  Future<void> _getProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      // Simplified query to only get the full name
      final data = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _userName = data['full_name'] ?? 'No name set';
          _userEmail = supabase.auth.currentUser!.email ?? 'No email found';
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching profile: ${error.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // dialog to edit the user's full name.
  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _userName);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: darkSurfaceColor,
            title: const Text('Edit Full Name',
                style: TextStyle(color: darkPrimaryText)),
            content: TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: darkPrimaryText),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: darkSecondaryText),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accentColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: darkSecondaryText),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: darkSecondaryText)),
              ),
              isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: accentColor)),
                    )
                  : TextButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Name cannot be empty.'),
                            backgroundColor: Colors.orange,
                          ));
                          return;
                        }

                        setStateDialog(() {
                          isSaving = true;
                        });

                        try {
                          final userId = supabase.auth.currentUser!.id;
                          await supabase
                              .from('profiles')
                              .update({'full_name': newName}).eq('id', userId);

                          setState(() {
                            _userName = newName;
                          });

                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ));
                        } catch (error) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Failed to update profile: ${error.toString()}'),
                            backgroundColor: Colors.red,
                          ));
                        } finally {
                          setStateDialog(() {
                            isSaving = false;
                          });
                        }
                      },
                      child: const Text('Save',
                          style: TextStyle(
                              color: accentColor, fontWeight: FontWeight.bold)),
                    ),
            ],
          );
        });
      },
    );
  }

  // dialog to change the user's password.
  Future<void> _showChangePasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;
    bool isNewPasswordObscured = true;
    bool isConfirmPasswordObscured = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: darkSurfaceColor,
            title: const Text('Change Password',
                style: TextStyle(color: darkPrimaryText)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPasswordController,
                  obscureText: isNewPasswordObscured,
                  style: const TextStyle(color: darkPrimaryText),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(color: darkSecondaryText),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor)),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: darkSecondaryText)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          isNewPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: iconColor),
                      onPressed: () {
                        setStateDialog(() {
                          isNewPasswordObscured = !isNewPasswordObscured;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: isConfirmPasswordObscured,
                  style: const TextStyle(color: darkPrimaryText),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(color: darkSecondaryText),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor)),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: darkSecondaryText)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          isConfirmPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: iconColor),
                      onPressed: () {
                        setStateDialog(() {
                          isConfirmPasswordObscured =
                              !isConfirmPasswordObscured;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: darkSecondaryText)),
              ),
              isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: accentColor)),
                    )
                  : TextButton(
                      onPressed: () async {
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword =
                            confirmPasswordController.text.trim();

                        if (newPassword.isEmpty || confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password fields cannot be empty.'),
                                  backgroundColor: Colors.orange));
                          return;
                        }
                        if (newPassword.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Password must be at least 6 characters long.'),
                              backgroundColor: Colors.orange));
                          return;
                        }
                        if (newPassword != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Passwords do not match.'),
                                  backgroundColor: Colors.orange));
                          return;
                        }

                        setStateDialog(() {
                          isSaving = true;
                        });

                        try {
                          await supabase.auth.updateUser(
                            UserAttributes(password: newPassword),
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Password updated successfully!'),
                            backgroundColor: Colors.green,
                          ));
                        } catch (error) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Failed to update password: ${error.toString()}'),
                            backgroundColor: Colors.red,
                          ));
                        } finally {
                          setStateDialog(() {
                            isSaving = false;
                          });
                        }
                      },
                      child: const Text('Save',
                          style: TextStyle(
                              color: accentColor, fontWeight: FontWeight.bold)),
                    ),
            ],
          );
        });
      },
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getProfile,
            tooltip: 'Refresh Profile',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : ListView(
              children: <Widget>[
                _buildSectionHeader('Account'),
                _buildInfoTile(
                  icon: Icons.account_circle_outlined,
                  title: _userName,
                  subtitle: _userEmail,
                ),
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile Name',
                  onTap: _showEditProfileDialog,
                ),
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
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

  Widget _buildInfoTile(
      {required IconData icon, required String title, String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(
              color: darkPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  color: darkSecondaryText.withOpacity(0.9), fontSize: 13))
          : null,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? currentValue,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title,
            style: const TextStyle(color: darkPrimaryText, fontSize: 16)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: TextStyle(
                    color: darkSecondaryText.withOpacity(0.9), fontSize: 13))
            : null,
        trailing: currentValue != null
            ? Text(currentValue,
                style: const TextStyle(color: darkSecondaryText, fontSize: 15))
            : (onTap != null
                ? const Icon(Icons.chevron_right, color: iconColor)
                : null),
        onTap: onTap,
      ),
    );
  }
}
