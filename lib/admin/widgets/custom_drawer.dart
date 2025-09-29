import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ui_service.dart';
import '../screens/auth/login_screen.dart';
import '../../student/screens/auth/LoginPageScreen.dart';

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? const Color(0xFF2e2d2f): const Color(0xFFF6F4FB);
    final headerGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF2D1856), Color(0xFF181824)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final headerTextColor = Colors.white;
    final headerSubtitleColor = Colors.white70;
    final avatarBg = isDark ? Colors.black : Colors.white;
    final avatarIconColor = isDark
        ? Colors.purple[200]
        : const Color(0xFF9C27B0);
    final closeIconColor = Colors.white;
    final footerBg = isDark ? const Color(0xFF2e2d2f): const Color(0xFFF6F4FB);
    final neutralBorderColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(gradient: headerGradient),
            child: Stack(
              children: [
                // Centered content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: avatarBg,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: avatarIconColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Admin MI',
                        style: TextStyle(
                          color: headerTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Management Interface',
                        style: TextStyle(
                          color: headerSubtitleColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: closeIconColor, size: 24),
                    tooltip: 'Close drawer',
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items with decreased height borders
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                  borderColor: neutralBorderColor,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.school,
                  title: 'Student Management',
                  index: 1,
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                  borderColor: neutralBorderColor,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Instructors Management',
                  index: 2,
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                  borderColor: neutralBorderColor,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Event Management',
                  index: 3,
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                  borderColor: neutralBorderColor,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Event Approval',
                  index: 4,
                  isSelected: selectedIndex == 4,
                  onTap: () => onItemTapped(4),
                  borderColor: neutralBorderColor,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.inventory,
                  title: 'Course',
                  index: 5,
                  isSelected: selectedIndex == 5,
                  onTap: () => onItemTapped(5),
                  borderColor: neutralBorderColor,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.groups,
                  title: 'Group',
                  index: 6,
                  isSelected: selectedIndex == 6,
                  onTap: () => onItemTapped(6),
                  borderColor: neutralBorderColor,
                ),
                const Divider(height: 24, color: Colors.grey),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  index: 7,
                  isSelected: selectedIndex == 7,
                  onTap: () => onItemTapped(7),
                  borderColor: neutralBorderColor,
                ),
              ],
            ),
          ),

          // Footer (without border)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: footerBg),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: ApiService.getUserData(),
              builder: (context, snapshot) {
                final userData = snapshot.data;
                final displayName = userData?['name'] ?? 'Admin User';
                final displayEmail = userData?['email'] ?? 'admin@example.com';
                final tileTextColor = isDark ? Colors.white : Colors.black;
                final tileSubtitleColor = isDark
                    ? Colors.white
                    : Colors.black;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? Colors.purple[800]
                        : const Color(0xFF2196F3),
                    child: Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: tileTextColor,
                    ),
                  ),
                  subtitle: Text(
                    displayEmail,
                    style: TextStyle(fontSize: 12, color: tileSubtitleColor),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.logout,
                      size: 20,
                      color: isDark ? Colors.red[300] : Colors.red,
                    ),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark
        ? Colors.purple[900]!.withOpacity(0.15)
        : const Color(0xFF9C27B0).withOpacity(0.1);
    final iconColor = isSelected
        ? (isDark ? Colors.purple[200] : const Color(0xFF9C27B0))
        : (isDark ? Colors.white70 : Colors.grey[600]);
    final textColor = isSelected
        ? (isDark ? Colors.purple[200] : const Color(0xFF9C27B0))
        : (isDark ? Colors.white : Colors.black);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected ? selectedBg : null,
        border: Border.all(
          color: borderColor,
          width: 0.8, // Decreased border width
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
          size: 20,
        ), // Slightly smaller icon
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16, // Slightly smaller font
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ), // Decreased padding
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        minVerticalPadding: 0, // Remove extra vertical padding
        dense: true, // Make the list tile more compact
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
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

                        // Navigate to login screen
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
