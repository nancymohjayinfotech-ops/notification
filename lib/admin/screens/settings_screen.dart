import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/ui_service.dart';
import '../../student/screens/auth/LoginPageScreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bool _notificationsEnabled = true;
  final bool _darkModeEnabled = false;
  final bool _biometricEnabled = false;
  final bool _autoBackup = true;
  final String _selectedLanguage = 'English';
  final String _selectedTheme = 'Purple';

  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.getAdminProfile();
      if (result['success'] == true) {
        setState(() {
          _profileData = result['data'];
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF2e2d2f)
        : const Color(0xFFF6F4FB);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final scaffoldBackgroundColor = isDark ? Colors.black : Colors.white;
    final dividerColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(isDark, cardColor, textColor, subtitleColor),
            const SizedBox(height: 24),

            // App Preferences
            _buildSectionTitle('App Preferences', textColor),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Receive app notifications',
                value: _notificationsEnabled,
                onChanged: (value) {},
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                value: _darkModeEnabled,
                onChanged: (value) {},
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildDropdownTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'Change app language',
                value: _selectedLanguage,
                items: const ['English', 'Spanish', 'French', 'German'],
                onChanged: (value) {},
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildDropdownTile(
                icon: Icons.palette_outlined,
                title: 'Theme Color',
                subtitle: 'Choose your preferred theme color',
                value: _selectedTheme,
                items: const ['Purple', 'Blue', 'Green', 'Orange'],
                onChanged: (value) {},
                isDark: isDark,
              ),
            ], cardColor),
            const SizedBox(height: 24),

            // Security Settings
            _buildSectionTitle('Security & Privacy', textColor),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.fingerprint_outlined,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face recognition',
                value: _biometricEnabled,
                onChanged: (value) {},
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(isDark),
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.security_outlined,
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security to your account',
                onTap: _showTwoFactorDialog,
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Settings',
                subtitle: 'Manage your privacy preferences',
                onTap: _showPrivacySettings,
                isDark: isDark,
              ),
            ], cardColor),
            const SizedBox(height: 24),

            // Data & Storage
            _buildSectionTitle('Data & Storage', textColor),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.backup_outlined,
                title: 'Auto Backup',
                subtitle: 'Automatically backup your data',
                value: _autoBackup,
                onChanged: (value) {},
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.storage_outlined,
                title: 'Storage Usage',
                subtitle: 'View and manage storage',
                onTap: _showStorageInfo,
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.file_download_outlined,
                title: 'Export Data',
                subtitle: 'Download your data as JSON',
                onTap: _showExportDialog,
                isDark: isDark,
              ),
            ], cardColor),
            const SizedBox(height: 24),

            // Support & About
            _buildSectionTitle('Support & About', textColor),
            _buildSettingsCard([
              _buildNavigationTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () => _showHelpDialog(isDark),
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: _showFeedbackDialog,
                isDark: isDark,
              ),
              _buildDivider(dividerColor),
              _buildNavigationTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () => _showAboutDialog(isDark),
                isDark: isDark,
              ),
            ], cardColor),
            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    if (_isLoadingProfile) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.purple[300]! : const Color(0xFF9C27B0),
            ),
          ),
        ),
      );
    }

    final name = _profileData?['name'] ?? 'Admin User';
    final email = _profileData?['email'] ?? 'admin@example.com';
    final phoneNumber = _profileData?['phoneNumber'] ?? '';
    final avatar = _profileData?['avatar'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.purple[800] ?? Colors.purple,
                        Colors.purple[900] ?? Colors.purple,
                      ]
                    : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Stack(
              children: [
                avatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.network(
                          '${ApiService.baseUrl}$avatar',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 35,
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                ? Colors.purple[600]
                                : const Color(0xFF9C27B0)) ??
                            const Color(0xFF9C27B0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
                if (phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phoneNumber,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? Colors.purple[300]! : const Color(0xFF9C27B0))
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.purple[300]!
                          : const Color(0xFF9C27B0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileDialog(isDark),
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? Colors.purple[300]! : const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final iconColor = isDark ? Colors.purple[300]! : const Color(0xFF9C27B0);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subtitleColor, fontSize: 14),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: iconColor,
        activeTrackColor: iconColor.withOpacity(0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final iconColor = isDark ? Colors.purple[300]! : const Color(0xFF9C27B0);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final trailingColor = isDark ? Colors.white70 : Colors.grey;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subtitleColor, fontSize: 14),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: trailingColor),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final iconColor = isDark ? Colors.purple[300]! : const Color(0xFF9C27B0);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subtitleColor, fontSize: 14),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
        style: TextStyle(color: textColor),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Divider(height: 1, color: dividerColor, indent: 60);
  }

  Widget _buildLogoutButton(bool isDark) {
    final borderColor = isDark
        ? Colors.red.withOpacity(0.5)
        : Colors.red.withOpacity(0.3);
    final textColor = isDark ? Colors.red[300] : Colors.red;

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextButton(
        onPressed: () => _showLogoutDialog(isDark),
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods with dark theme support
  void _showEditProfileDialog([bool isDark = false]) {
    final nameController = TextEditingController(
      text: _profileData?['name'] ?? '',
    );
    final emailController = TextEditingController(
      text: _profileData?['email'] ?? '',
    );
    final bioController = TextEditingController(
      text: _profileData?['bio'] ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Theme(
          data: Theme.of(
            context,
          ).copyWith(dialogBackgroundColor: backgroundColor),
          child: AlertDialog(
            backgroundColor: backgroundColor,
            title: Text('Edit Profile', style: TextStyle(color: textColor)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bioController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Bio (Optional)',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.info_outline,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: textColor)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final result = await ApiService.updateAdminProfile(
                              name: nameController.text,
                              email: emailController.text,
                              bio: bioController.text.isEmpty
                                  ? null
                                  : bioController.text,
                            );

                            if (result['success'] == true) {
                              Navigator.pop(context);
                              UiService.showSuccess(
                                'Profile updated successfully',
                              );
                              _loadProfile();
                            } else {
                              UiService.showError(
                                result['message'] ?? 'Failed to update profile',
                              );
                            }
                          } catch (e) {
                            UiService.showError('An error occurred: $e');
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.purple[600]!
                      : const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog([bool isDark = false]) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Theme(
          data: Theme.of(
            context,
          ).copyWith(dialogBackgroundColor: backgroundColor),
          child: AlertDialog(
            backgroundColor: backgroundColor,
            title: Text('Change Password', style: TextStyle(color: textColor)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.lock_reset,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: textColor)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final result = await ApiService.updatePassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: newPasswordController.text,
                            );

                            if (result['success'] == true) {
                              Navigator.pop(context);
                              UiService.showSuccess(
                                'Password changed successfully',
                              );
                            } else {
                              UiService.showError(
                                result['message'] ??
                                    'Failed to change password',
                              );
                            }
                          } catch (e) {
                            UiService.showError('An error occurred: $e');
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.purple[600]!
                      : const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UiService.showSuccess('Two-factor authentication enabled');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    UiService.showInfo('Privacy settings opened');
  }

  void _showStorageInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Storage Usage', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Data: 45.2 MB', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('Cache: 12.8 MB', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('Documents: 23.1 MB', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('Total: 81.1 MB', style: TextStyle(color: textColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UiService.showSuccess('Cache cleared');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.purple[600]!
                  : const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Export Data', style: TextStyle(color: textColor)),
        content: Text(
          'Export your data as a JSON file. This may take a few moments.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UiService.showSuccess('Data export started');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.purple[600]!
                  : const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog([bool isDark = false]) {
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Help & Support', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Email: support@adminmi.com',
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              '• Phone: +1 (555) 123-4567',
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              '• Hours: Mon-Fri 9AM-5PM EST',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UiService.showInfo('Opening support chat...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.purple[600]!
                  : const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Send Feedback', style: TextStyle(color: textColor)),
        content: TextField(
          maxLines: 4,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UiService.showSuccess('Feedback sent successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.purple[600]!
                  : const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog([bool isDark = false]) {
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('About Admin MI', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('Build: 2024.01.15', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('© 2024 Admin MI Team', style: TextStyle(color: textColor)),
            const SizedBox(height: 16),
            Text(
              'A comprehensive management interface for administrators.',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog([bool isDark = false]) {
    bool isLoading = false;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Theme(
          data: Theme.of(
            context,
          ).copyWith(dialogBackgroundColor: backgroundColor),
          child: AlertDialog(
            backgroundColor: backgroundColor,
            title: Text('Logout', style: TextStyle(color: textColor)),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: textColor)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final result = await ApiService.adminLogout();

                          Navigator.pop(context);

                          if (result['success'] == true) {
                            UiService.showSuccess('Logged out successfully');
                          } else {
                            UiService.showInfo(
                              result['message'] ?? 'Logout completed',
                            );
                          }

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPageScreen(),
                            ),
                            (route) => false,
                          );
                        } catch (e) {
                          Navigator.pop(context);
                          UiService.showError('Error during logout: $e');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Update Profile Picture',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Choose an option to update your profile picture',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: Text('Gallery', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
            child: Text('Camera', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _uploadProfileImage(image.path, image: image);
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      await _uploadProfileImage(image.path, image: image);
    }
  }

  Future<void> _uploadProfileImage(String imagePath, {XFile? image}) async {
    bool dialogShown = false;

    try {
      print('DEBUG: Starting upload for image: $imagePath');
      print('DEBUG: Platform - Web: $kIsWeb');

      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: false,
        builder: (BuildContext dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: SizedBox(
              width: 200,
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(child: Text('Uploading image...')),
                ],
              ),
            ),
          ),
        ),
      );
      dialogShown = true;

      await Future.delayed(const Duration(milliseconds: 100));

      print('DEBUG: Calling ApiService.uploadProfileImage...');

      Map<String, dynamic> result;

      if (image != null) {
        try {
          final imageBytes = await image.readAsBytes();
          print(
            'DEBUG: Successfully read image bytes: ${imageBytes.length} bytes',
          );
          result = await ApiService.uploadProfileImage(
            imagePath,
            imageBytes: imageBytes,
          );
          print('DEBUG: Upload result (bytes): $result');
        } catch (bytesError) {
          print('DEBUG: Failed to read bytes, trying file path: $bytesError');
          result = await ApiService.uploadProfileImage(imagePath);
          print('DEBUG: Upload result (path): $result');
        }
      } else {
        result = await ApiService.uploadProfileImage(imagePath);
        print('DEBUG: Upload result (direct path): $result');
      }

      if (result['success'] == true) {
        print('DEBUG: Upload successful, showing success message');
        if (mounted) {
          UiService.showSuccess('Profile picture updated successfully');
          _loadProfile();
        }
      } else {
        print('DEBUG: Upload failed: ${result['message']}');
        if (mounted) {
          UiService.showError(result['message'] ?? 'Failed to upload image');
        }
      }
    } catch (e) {
      print('DEBUG: Exception in _uploadProfileImage: $e');
      if (mounted) {
        UiService.showError('An error occurred: $e');
      }
    } finally {
      print('DEBUG: Finally block - closing loading dialog...');
      if (dialogShown && mounted) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            print('DEBUG: Dialog closed with Navigator.pop()');
          }

          await Future.delayed(const Duration(milliseconds: 50));
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            print('DEBUG: Dialog force closed with second pop()');
          }
        } catch (e) {
          print('DEBUG: Error closing dialog: $e');
        }
      }
    }
  }
}
