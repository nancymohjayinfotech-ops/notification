import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int currentIndex;
  final bool showBackButton;
  final bool showBottomNavigation;
  final bool showHeaderActions;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const AppLayout({
    super.key,
    required this.child,
    required this.title,
    this.currentIndex = 0,
    this.showBackButton = false,
    this.showBottomNavigation = true,
    this.showHeaderActions = true,
    this.actions,
    this.onBackPressed,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });

    // Navigation logic based on index
    switch (index) {
      case 0:
        if (_currentIndex != 0) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
        break;
      case 1:
        // Navigate to All Courses
        Navigator.pushReplacementNamed(context, '/dashboard');
        // You can add specific navigation logic here
        break;
      case 2:
        // Navigate to Courses
        break;
      case 3:
        // Navigate to Bookmarks/Favorites
        Navigator.pushNamed(context, '/favorites');
        break;
      case 4:
        // Navigate to Profile
        break;
    }
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCartIcon() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/cart');
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 20,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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

  Widget _buildFavoritesIcon() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/favorites');
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
            size: isSelected ? 28 : 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom Top Bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5F299E), Color(0xFF8B5CF6)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Back button or Menu
                    widget.showBackButton
                        ? GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (widget.onBackPressed != null) {
                                widget.onBackPressed!();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                    // Right side - Action icons
                    widget.showHeaderActions
                        ? Row(
                            children:
                                widget.actions ??
                                [
                                  _buildHeaderIcon(
                                    Icons.notifications_outlined,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFavoritesIcon(),
                                  const SizedBox(width: 12),
                                  _buildCartIcon(),
                                ],
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Expanded(child: widget.child),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: widget.showBottomNavigation
          ? Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5F299E),
                    Color(0xFF5F299E),
                    Color(0xFF5F299E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5F299E).withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_rounded, 0),
                      _buildNavItem(Icons.language_rounded, 1),
                      _buildNavItem(Icons.play_circle_fill, 2),
                      _buildNavItem(Icons.group_add_outlined, 3),
                      _buildNavItem(Icons.person_rounded, 4),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
