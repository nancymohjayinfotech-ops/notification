import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import '../student/screens/auth/LoginPageScreen.dart';
import 'screens/home/home_screen.dart';
import 'screens/user/user_screen.dart';
import 'screens/event_management/event_management_screen.dart';
import 'screens/instructor_management/instructor_management_screen.dart';
import 'screens/course_management/course_management_screen.dart';
import 'screens/event_approval/event_approval_screen.dart';
import 'screens/group/group_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/custom_navbar.dart';
import 'widgets/state_views.dart';
import 'services/api_service.dart';
import 'services/navigation_service.dart';


class AdminApp extends StatelessWidget {
  final String? initialRoute;

  const AdminApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin MI',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF9C27B0),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF9C27B0),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.grey),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      // If initialRoute is provided, use it; otherwise use home: AuthWrapper
      initialRoute: initialRoute,
      home: initialRoute == null ? const AuthWrapper() : null,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/loginpage': (context) => const LoginPageScreen(),
        '/main': (context) => const MainScreen(),
      
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: 'Checking session...'));
    }

    return _isLoggedIn ? const MainScreen() : const LoginPageScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Register the navigation callback
    print('MainScreen: Registering navigation callback');
    NavigationService.setInternalNavigationCallback(_onItemTapped);
  }

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
    print('MainScreen: _onItemTapped called with index $index');
    // Ensure index is within valid range
    if (index >= 0 && index < _screens.length) {
      print('MainScreen: Index is valid, updating selectedIndex to $index');
      setState(() {
        _selectedIndex = index;
      });
    } else {
      print('MainScreen: Index $index is invalid, falling back to dashboard');
      // Fallback to dashboard if invalid index
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _onDrawerItemTapped(int index) {
    _onItemTapped(index);
    Navigator.pop(context); // Close drawer after navigation
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
        onItemTapped: _onDrawerItemTapped,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[safeIndex],
      ),
    );
  }
}
