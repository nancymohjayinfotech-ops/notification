// instructor_drawer.dart
import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/pages/Settings.dart';
import 'package:provider/provider.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:fluttertest/student/providers/theme_provider.dart';
import 'package:fluttertest/instructor/pages/Feedback.dart';
import 'package:fluttertest/student/screens/auth/LoginPageScreen.dart';
import 'package:fluttertest/live_session/pages/meetings_page.dart';
import 'avatar_management.dart' as avatar;

class InstructorDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final String instructorName;
  final int unreadNotifications;

  const InstructorDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.instructorName,
    required this.unreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF5F299E),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ValueListenableBuilder<String?>(
                      valueListenable:
                          avatar.AvatarManagement.avatarUrlNotifier,
                      builder: (context, avatarUrl, _) {
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : const AssetImage(
                                          "assets/images/developer.png",
                                        )
                                        as ImageProvider,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable:
                            avatar.AvatarManagement.instructorNameNotifier,
                        builder: (context, name, _) {
                          return Text(
                            name.isNotEmpty ? name : instructorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      const Text(
                        'Instructor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu items with outlined borders
          _buildDrawerItem(
            context: context,
            index: 0,
            title: 'My Courses',
            icon: Icons.school,
          ),
          _buildDrawerItem(
            context: context,
            index: 1,
            title: 'Students',
            icon: Icons.people,
          ),
          _buildDrawerItem(
            context: context,
            index: 2,
            title: 'Groups',
            icon: Icons.groups,
          ),
          _buildDrawerItem(
            context: context,
            index: 3,
            title: 'Analytics',
            icon: Icons.analytics,
          ),
          _buildActionItem(
            context: context,
            title: 'Meetings',
            icon: Icons.videocam,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeetingsPage(),
                ),
              );
            },
          ),
          _buildActionItem(
            context: context,
            title: 'Schedule',
            icon: Icons.calendar_month,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/instructorschedule');
            },
          ),
          _buildActionItem(
            context: context,
            title: 'Feedback & Reviews',
            icon: Icons.star_rate,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackPage(),
                ),
              );
            },
          ),
          const Divider(),
          _buildActionItem(
            context: context,
            title: 'Settings',
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          _buildThemeSelector(context),
          _buildActionItem(
            context: context,
            title: 'Help & Support',
            icon: Icons.help,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF5F299E) : Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF5F299E) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: () {
          onItemTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.brightness_6, color: Colors.white),
        title: const Text('Theme'),
        trailing: DropdownButton<ThemeMode>(
          value: themeProvider.themeMode,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(
            color: Color(0xFF5F299E),
            fontSize: 16,
          ),
          underline: Container(
            height: 2,
            color: const Color(0xFF5F299E),
          ),
          onChanged: (ThemeMode? newValue) {
            if (newValue != null) {
              themeProvider.setThemeMode(newValue);
            }
          },
          items: <DropdownMenuItem<ThemeMode>>[
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: const [
                  Icon(
                    Icons.wb_sunny,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text('Light',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: const [
                  Icon(
                    Icons.nightlight_round,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text('Dark',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: const [
                  Icon(
                    Icons.settings,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text('System',
                    style: TextStyle(
                      color: Colors.grey,
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

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () async {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Logout'),
                content: const Text(
                  'Are you sure you want to logout?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Logout'),
                  ),
                ],
              );
            },
          );

          if (confirmed == true) {
            // Use the proper logout method from auth service
            await InstructorAuthService.logout();

            // Navigate to login page and clear entire navigation stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginPageScreen(),
              ),
              (Route<dynamic> route) => false,
            );
          }
        },
      ),
    );
  }
}