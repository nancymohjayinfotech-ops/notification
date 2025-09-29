import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertest/student/pages/notifications_page.dart';
import 'package:provider/provider.dart';
import 'package:fluttertest/student/screens/group/GroupsPage_Tab.dart';
import 'package:fluttertest/student/providers/app_state_provider.dart';
import 'package:fluttertest/student/providers/navigation_provider.dart';
import 'package:fluttertest/student/services/auth_service.dart';
import 'package:fluttertest/student/utils/image_utils.dart';
import '../courses/AllCoursesPage.dart';
import 'HomePage_Tab.dart';
import '../courses/CoursesPage_Tab.dart';
import '../account/ProfilePage_Tab.dart';
import 'CartPage.dart';
import 'FavoritesPage.dart';
import '../auth/LoginPageScreen.dart';
import 'package:fluttertest/instructor/pages/notifications_page.dart';

// CartService class definition
class CartService extends ChangeNotifier {
  int cartCount = 0;

  void addToCart() {
    cartCount++;
    notifyListeners();
  }

  void removeFromCart() {
    if (cartCount > 0) cartCount--;
    notifyListeners();
  }

  void clearCart() {
    cartCount = 0;
    notifyListeners();
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final CartService _cartService = CartService();
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.forward();

    // Initialize cart count and listen to changes
    _cartCount = _cartService.cartCount;
    _cartService.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {
        _cartCount = _cartService.cartCount;
      });
    }
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    _animationController.dispose();
    // ...existing code...
    super.dispose();
  }

  // Helper method to get avatar image with proper base URL
  ImageProvider? _getAvatarImage(user) {
    return ImageUtils.getAvatarImageProvider(user?.avatar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.setSelectedRole(args['role'] ?? '');
      appState.setSelectedLanguage(args['language'] ?? '');
    }
  }

  // Method to get current tab content with animation
  Widget _getCurrentTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _getTabWidget(),
    );
  }

  Widget _getTabWidget() {
    return Consumer2<AppStateProvider, NavigationProvider>(
      builder: (context, appState, navigation, child) {
        final currentIndex = navigation.currentIndex;
        final selectedLanguage = appState.selectedLanguage;
        final selectedRole = appState.selectedRole;

        switch (currentIndex) {
          case 0:
            return HomePageTab(
              key: const ValueKey(0),
              selectedLanguage: selectedLanguage,
            );
          case 1:
            return AllCoursesPage(
              key: const ValueKey(1),
              selectedLanguage: selectedLanguage,
            );
          case 2:
            return CoursesPageTab(key: const ValueKey(2));
          case 3:
            return GroupPageTab(
              key: const ValueKey(3),
              selectedLanguage: selectedLanguage,
            );
          case 4:
            return ProfilePageTab(
              key: const ValueKey(4),
              selectedRole: selectedRole,
              selectedLanguage: selectedLanguage,
            );
          default:
            return HomePageTab(
              key: const ValueKey(0),
              selectedLanguage: selectedLanguage,
            );
        }
      },
    );
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () {
        print(
          "<>klvjbgfjckhvbfdujhvcgdfujhvcbbdukvjhbdvcujdfhgvgukfduhgbvdfhbf",
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildFavoritesIcon() {
    return GestureDetector(
      onTap: () {
        print(
          ">>>.>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",
        );
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FavoritesPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.favorite_border, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCartIcon() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 22,
            ),
            if (_cartCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(),
                  child: Text(
                    _cartCount > 99 ? '99+' : _cartCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final navigation = Provider.of<NavigationProvider>(context);
    final isSelected = navigation.currentIndex == index;

    return Consumer<NavigationProvider>(
      builder: (context, navigation, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            navigation.setCurrentIndex(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: isSelected ? 1.1 : 1.0,
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 6 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Use sidebar layout for web/desktop/macbook (width > 800px)
        if (screenWidth > 800) {
          return _buildWebLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // Web Layout with Sidebar
  Widget _buildWebLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF2e2d2f)
          : const Color(0xFFF6F4FB),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: isDark ? const Color(0x002e2d2f) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo/Brand Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5F299E), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Color(0xFF5F299E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'MI SKILLS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Menu
                Expanded(
                  child: Consumer<NavigationProvider>(
                    builder: (context, navigation, child) {
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSidebarItem(
                            Icons.dashboard_outlined,
                            'Dashboard',
                            0,
                            navigation.currentIndex == 0,
                          ),
                          _buildSidebarItem(
                            Icons.language_outlined,
                            'All Courses',
                            1,
                            navigation.currentIndex == 1,
                          ),
                          _buildSidebarItem(
                            Icons.play_circle_outline,
                            'My Courses',
                            2,
                            navigation.currentIndex == 2,
                          ),
                          _buildSidebarItem(
                            Icons.group_outlined,
                            'Groups',
                            3,
                            navigation.currentIndex == 3,
                          ),
                          _buildSidebarItem(
                            Icons.person_outline,
                            'Profile',
                            4,
                            navigation.currentIndex == 4,
                          ),

                          const Divider(height: 40, color: Colors.grey),

                          // Additional Menu Items
                          _buildSidebarItem(
                            Icons.favorite_outline,
                            'Favorites',
                            -1,
                            false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FavoritesPage(),
                                ),
                              );
                            },
                          ),
                          _buildSidebarItem(
                            Icons.shopping_cart_outlined,
                            'Cart',
                            -1,
                            false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CartPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // User Profile Section at Bottom
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    final user = authService.currentUser;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2e2d2f) : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF5F299E),
                            backgroundImage: _getAvatarImage(user),
                            child: (user?.avatar?.isNotEmpty != true)
                                ? Text(
                                    ImageUtils.getUserInitials(user?.name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                                Text(
                                  user?.role.name ?? 'Student',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Logout/Exit Icon
                          GestureDetector(
                            onTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldLogout == true) {
                                await authService.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginPageScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x0028282b) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<NavigationProvider>(
                          builder: (context, navigation, child) {
                            final titles = [
                              'Dashboard',
                              'All Courses',
                              'My Courses',
                              'Groups',
                              'Profile',
                            ];
                            return Text(
                              titles[navigation.currentIndex],
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF28282b),
                                letterSpacing: 1.1,
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF5F299E),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentNotificationsPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FavoritesPage(),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.favorite_border,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF5F299E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CartPage(),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F299E),
                                  ),
                                  if (_cartCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          _cartCount > 99
                                              ? '99+'
                                              : _cartCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Content Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2e2d2f)
                          : const Color(0xFFF6F4FB),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: _getCurrentTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Fixed App Bar that stays on top
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5F299E), Color(0xFF5F299E), Color(0xFF5F299E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  const Spacer(),
                  _buildNotificationIcon(),
                  const SizedBox(width: 12),
                  _buildFavoritesIcon(),
                  const SizedBox(width: 12),
                  _buildCartIcon(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Content Section with enhanced transition
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: _getCurrentTabContent(),
              ),
            ),
          ),
        ],
      ),
      // Enhanced Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5F299E), Color(0xFF7B3FB8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F299E).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 0),
                _buildNavItem(Icons.language_rounded, 1),
                _buildNavItem(Icons.class_, 2),
                _buildNavItem(Icons.groups, 3),
                _buildNavItem(Icons.person_rounded, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sidebar Menu Item
  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              onTap ??
              () {
                if (index >= 0) {
                  Provider.of<NavigationProvider>(
                    context,
                    listen: false,
                  ).setCurrentIndex(index);
                }
              },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF5F299E) : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF5F299E) : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
