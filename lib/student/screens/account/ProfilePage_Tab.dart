import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/auth/LoginPageScreen.dart';
import 'package:provider/provider.dart';
import 'profile/EditProfilePage.dart';
import 'settings/SettingsPage.dart';
import 'profile/PrivacyPolicyPage.dart';
import 'profile/TermsConditionsPage.dart';
import 'profile/AboutUsPage.dart';
import '../event/enrolled_events_page.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../models/dashboard_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePageTab extends StatefulWidget {
  final String selectedRole;
  final String selectedLanguage;

  const ProfilePageTab({
    super.key,
    required this.selectedRole,
    required this.selectedLanguage,
  });

  @override
  _ProfilePageTabState createState() => _ProfilePageTabState();
}

class _ProfilePageTabState extends State<ProfilePageTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  DashboardStats? _dashboardStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardStats();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    // Always reload user profile to get latest data
    await authService.loadCurrentUser();

    // Force UI refresh after loading user data
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with the updated user data
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        _isLoadingStats = true;
      });

      final stats = await _courseService.getDashboardStats();
      setState(() {
        _dashboardStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final cardColor =
            Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
        final shadowColor = Theme.of(context).shadowColor;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5F299E),
                      const Color(0xFF5F299E).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5F299E).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              user != null && user.avatar.isNotEmpty
                              ? NetworkImage(
                                  'http://54.82.53.11:5001${user.avatar}',
                                )
                              : const AssetImage('assets/images/homescreen.png')
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF5F299E),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'User Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? 'No email',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.studentId ?? 'No student ID',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.phoneNumber != null
                          ? '${user!.phoneNumber}'
                          : 'No phone number',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.selectedRole} • ${widget.selectedLanguage}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _isLoadingStats
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                _dashboardStats?.totalCourses.toString() ?? '0',
                                'Courses',
                              ),
                              _buildStatColumn(
                                _dashboardStats?.formattedRating ?? '0.0',
                                'Rating',
                              ),
                              _buildStatColumn(
                                _dashboardStats?.formattedLearningHours ?? '0h',
                                'Learning',
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tab Bar + Content
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF5F299E),
                  unselectedLabelColor: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  indicatorColor: const Color(0xFF5F299E),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.person_outline, size: 18),
                      text: 'Profile',
                    ),
                    Tab(
                      icon: Icon(Icons.settings_outlined, size: 18),
                      text: 'Settings',
                    ),
                  ],
                ),
              ),

              // Tab Content (no inner box, no fixed height, no scroll)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final tabIndex = _tabController.index;
                  if (tabIndex == 0) {
                    return _buildProfileTab();
                  } else {
                    return _buildSettingsTab();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Column(
      children: [
        _buildMenuOption(
          Icons.person_outline,
          'Edit Profile',
          'Update your personal information',
          () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage()),
            );
            // Refresh profile data if edit was successful
            if (result == true) {
              await _loadUserProfile();
            }
          },
        ),
        _buildMenuOption(
          Icons.event_available,
          'View Your Event',
          'See your enrolled events',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EnrolledEventsPage()),
            );
          },
        ),
        _buildMenuOption(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          'Read our privacy policy',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
            );
          },
        ),
        _buildMenuOption(
          Icons.description_outlined,
          'Terms & Conditions',
          'Read our terms and conditions',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TermsConditionsPage()),
            );
          },
        ),
        _buildMenuOption(
          Icons.info_outline,
          'About Us',
          'Learn more about our company',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutUsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Column(
      children: [
        _buildMenuOption(
          Icons.settings_outlined,
          'App Settings',
          'Configure app preferences',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
        ),
        _buildMenuOption(
          Icons.notifications_outlined,
          'Notifications',
          'Manage notification preferences',
          () {},
        ),
        _buildMenuOption(
          Icons.dark_mode_outlined,
          'Theme',
          'Switch between light and dark mode',
          () {
            _showThemeDialog();
          },
        ),
        _buildMenuOption(
          Icons.help_outline,
          'Help & Support',
          'Get help and contact support',
          () {},
        ),
        const SizedBox(height: 20),
        _buildMenuOption(
          Icons.logout,
          'Logout',
          'Sign out of your account',
          () {
            _showLogoutDialog();
          },
          isLogout: true,
        ),
      ],
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final themeMode = themeProvider.themeMode;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 16,
              backgroundColor: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F299E).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dark_mode_outlined,
                            color: Color(0xFF5F299E),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Choose Theme',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildThemeOption(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Light Mode',
                      subtitle: 'Use light theme',
                      selected: themeMode == ThemeMode.light,
                      onTap: () {
                        themeProvider.setThemeMode(ThemeMode.light);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildThemeOption(
                      icon: Icons.nightlight_round,
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme',
                      selected: themeMode == ThemeMode.dark,
                      onTap: () {
                        themeProvider.setThemeMode(ThemeMode.dark);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildThemeOption(
                      icon: Icons.phone_android,
                      title: 'System Default',
                      subtitle: 'Follow system theme',
                      selected: themeMode == ThemeMode.system,
                      onTap: () {
                        themeProvider.setThemeMode(ThemeMode.system);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF5F299E),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5F299E).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF5F299E)
                : Colors.grey.withOpacity(0.18),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF5F299E) : Colors.grey[600],
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: selected
                          ? const Color(0xFF5F299E)
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(
                      Icons.check_circle,
                      color: const Color(0xFF5F299E),
                      size: 22,
                      key: ValueKey(true),
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey[400],
                      size: 22,
                      key: ValueKey(false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: Colors.grey[700]!, width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final authService = Provider.of<AuthService>(
                          context,
                          listen: false,
                        );
                        await authService.logout();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPageScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red[50]
                : const Color(0xFF5F299E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : const Color(0xFF5F299E),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isLogout
                ? Colors.red
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.4),
        ),
        onTap: onTap,
      ),
    );
  }
}
