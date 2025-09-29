import 'package:flutter/material.dart';
// import 'package:fluttertest/admin/screens/event_approval/event_approval_screen.dart';
import '../home/home_screen.dart';
import '../user/user_screen.dart';
import '../event_management/event_management_screen.dart';
import '../instructor_management/instructor_management_screen.dart';
import '../course_management/course_management_screen.dart';
import '../event_approval/event_approval_screen.dart';
import '../group/group_screen.dart';
import '../settings_screen.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_navbar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = const [
    HomeScreen(),                    // 0 - Dashboard
    UserScreen(),                    // 1 - Student Management
    InstructorManagementScreen(),    // 2 - Instructors Management
    EventManagementScreen(),         // 3 - Event Management
    EventApprovalScreen(),           // 4 - Event Approval
    CourseManagementScreen(),        // 5 - Course
    GroupScreen(),                   // 6 - Group
    SettingsScreen(),                // 7 - Settings
  ];

  final List<String> _titles = const [
    'Dashboard',                     // 0
    'Student Management',            // 1 - Must match drawer title
    'Instructors Management',        // 2
    'Event Management',              // 3
    'Event Approval',                // 4
    'Course',                        // 5
    'Group',                         // 6
    'Settings',                      // 7
  ];

  void _onItemTapped(int index) {
    // Ensure index is within valid range
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // Fallback to dashboard if invalid index
      setState(() {
        _selectedIndex = 0;
      });
    }
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    // Comprehensive safety check to prevent any index out of range errors
    int safeIndex = _selectedIndex;
    if (safeIndex < 0 || safeIndex >= _screens.length) {
      safeIndex = 0; // Default to dashboard
      // Update the state to reflect the safe index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomNavbar(
        title: safeIndex < _titles.length ? _titles[safeIndex] : 'Dashboard',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: CustomDrawer(
        selectedIndex: safeIndex,
        onItemTapped: _onItemTapped,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[safeIndex],
      ),
    );
  }
}
