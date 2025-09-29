import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/theme_provider.dart';
// import 'ThemeSettingsPage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  // bool _emailNotifications = true;
  // bool _pushNotifications = true;
  // bool _autoDownload = false;
  // String _selectedLanguage = 'English';
  // String _selectedQuality = 'High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F299E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 60,
                    color: Color(0xFF5F299E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize your app experience',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // NOTIFICATIONS SECTION - Matches Image 1 (Purple "Notifications" header)
            _buildSectionHeader('Notifications'),

            // Enable Notifications Toggle - Bell icon with switch (Image 1)
            _buildSwitchTile(
              'Enable Notifications',
              'Receive notifications about courses and updates',
              Icons.notifications_outlined,
              _notificationsEnabled,
              (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),

            // Email Notifications Toggle - Email icon with switch (Image 1)
            // _buildSwitchTile(
            //   'Email Notifications',
            //   'Receive notifications via email',
            //   Icons.email_outlined,
            //   _emailNotifications,
            //   (value) {
            //     setState(() {
            //       _emailNotifications = value;
            //     });
            //   },
            // ),

            // Push Notifications Toggle - Phone icon with switch (Image 1)
            // _buildSwitchTile(
            //   'Push Notifications',
            //   'Receive push notifications on your device',
            //   Icons.phone_android,
            //   _pushNotifications,
            //   (value) {
            //     setState(() {
            //       _pushNotifications = value;
            //     });
            //   },
            // ),
            const SizedBox(height: 20),

            // APPEARANCE SECTION - Controls visual theme and language preferences
            // This section allows users to customize the app's look and feel
            _buildSectionHeader('Appearance'),

            // Theme Settings Action - Navigate to dedicated theme page
            // Users can switch between Light, Dark, and System themes
            // _buildActionTile(
            //   'Theme Settings',
            //   'Choose between light, dark, or system theme',
            //   Icons.palette_outlined,
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const ThemeSettingsPage(),
            //       ),
            //     );
            //   },
            // ),
            // Language Selection - Globe icon with dropdown menu
            // Allows users to change app language (English, Spanish, French, German, Chinese)
            // Currently supports 5 languages with English as default
            // _buildDropdownTile(
            //   'Language',
            //   'Choose your preferred language',
            //   Icons.language_outlined,
            //   _selectedLanguage,
            //   ['English', 'Spanish', 'French', 'German', 'Chinese'],
            //   (value) {
            //     setState(() {
            //       _selectedLanguage = value!;
            //     });
            //   },
            // ),
            const SizedBox(height: 20),

            // DOWNLOAD & STORAGE SECTION - Manages offline content and storage
            // Controls how course materials are downloaded and stored locally
            // _buildSectionHeader('Download & Storage'),

            // Auto Download Toggle - Automatically downloads course videos/materials
            // When enabled, new enrolled courses will download content automatically
            // _buildSwitchTile(
            //   'Auto Download',
            //   'Automatically download course materials',
            //   Icons.download_outlined,
            //   _autoDownload,
            //   (value) {
            //     setState(() {
            //       _autoDownload = value;
            //     });
            //   },
            // ),

            // Video Quality Selection - Controls default download quality
            // Options: Low (360p), Medium (720p), High (1080p), Auto (adaptive)
            // Higher quality uses more storage space but better viewing experience
            // _buildDropdownTile(
            //   'Video Quality',
            //   'Default video quality for downloads',
            //   Icons.video_settings_outlined,
            //   _selectedQuality,
            //   ['Low', 'Medium', 'High', 'Auto'],
            //   (value) {
            //     setState(() {
            //       _selectedQuality = value!;
            //     });
            //   },
            // ),

            // Clear Cache Action - Removes temporary files and cached data
            // Helps free up device storage space when running low
            // _buildActionTile(
            //   'Clear Cache',
            //   'Free up storage space',
            //   Icons.cleaning_services_outlined,
            //   () {
            //     _showClearCacheDialog();
            //   },
            // ),
            const SizedBox(height: 20),

            // ACCOUNT SECTION - User data management and account controls
            // Handles user profile data, backup, and account deletion
            // _buildSectionHeader('Account'),

            // Sync Data Action - Synchronizes learning progress across devices
            // Uploads local progress to cloud and downloads from other devices
            // _buildActionTile(
            //   'Sync Data',
            //   'Sync your progress across devices',
            //   Icons.sync,
            //   () {
            //     _syncData();
            //   },
            // ),

            // Export Data Action - Downloads user's learning data as backup
            // Creates downloadable file with courses, progress, certificates, etc.
            // _buildActionTile(
            //   'Export Data',
            //   'Download your learning data',
            //   Icons.file_download_outlined,
            //   () {
            //     _exportData();
            //   },
            // ),

            // Delete Account Action - DESTRUCTIVE: Permanently removes user account
            // Red styling indicates dangerous action - shows confirmation dialog
            // This will delete all user data, progress, and enrolled courses
            // _buildActionTile(
            //   'Delete Account',
            //   'Permanently delete your account',
            //   Icons.delete_outline,
            //   () {
            //     _showDeleteAccountDialog();
            //   },
            //   isDestructive: true,
            // ),
            const SizedBox(height: 30),

            // App Version
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'App Version',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MLI SKILL v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5F299E),
        ),
      ),
    );
  }

  /// Builds switch toggle tiles for settings options
  /// Used for: Enable Notifications, Email Notifications, Push Notifications, Auto Download
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, // Card background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        secondary: Icon(icon, color: const Color(0xFF5F299E)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF5F299E),
        activeTrackColor: const Color(0xFF5F299E).withOpacity(0.28),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF5F299E)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
        ),
      ),
    );
  }

  /// Builds action tiles for clickable settings options
  /// Used for: Clear Cache, Sync Data, Export Data, Delete Account
  /// Creates white cards with icons on left, title/subtitle in center, arrow on right
  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive =
        false, // Red styling for dangerous actions like Delete Account
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, // Card background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF5F299E),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive
                ? Colors.red
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, // Right arrow indicating clickable action
          size: 16,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text('This will free up storage space. Continue?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('This action cannot be undone. Are you sure?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                // Implement account deletion
              },
            ),
          ],
        );
      },
    );
  }

  void _syncData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data synced successfully')));
  }

  void _exportData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data export started')));
  }
}
