import 'package:flutter/material.dart';
import '../../models/user_role.dart';

class RoleSelectionScreen extends StatefulWidget {
  final bool isSignUp;

  const RoleSelectionScreen({super.key, this.isSignUp = false});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  UserRole? _selectedRole;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define breakpoints for responsive design
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenHeight < 650;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        height: screenHeight,
        color: Colors.white,
        child: Stack(
          children: [
            // Fixed layout without scrolling
            Column(
              children: [
                // Main content with animation - centered
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildRoleSelectionContent(
                          context,
                          isSmallScreen,
                          isVerySmallScreen,
                          isDesktop,
                          isTablet,
                          screenWidth, // <-- Add this
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionContent(
    BuildContext context,
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isDesktop,
    bool isTablet,
    double screenWidth, // <-- Add this parameter
  ) {
    final contentWidth = isDesktop
        ? 500.0
        : isTablet
        ? 450.0
        : isSmallScreen
        ? screenWidth * 0.9
        : 400.0;

    return Container(
      width: contentWidth,
      margin: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 14),
      ),
      padding: EdgeInsets.all(
        isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 28),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with enhanced styling
          Center(
            child: Column(
              children: [
                Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: isVerySmallScreen
                        ? 18
                        : (isSmallScreen ? 19 : 20),
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.titleLarge?.color ??
                        const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(
                  height: isVerySmallScreen ? 3 : (isSmallScreen ? 3 : 4),
                ),
                Text(
                  'Choose how you want to use our platform',
                  style: TextStyle(
                    fontSize: isVerySmallScreen
                        ? 13
                        : (isSmallScreen ? 14 : 15),
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18)),

          // Role selection cards
          _buildRoleCard(
            role: UserRole.student,
            title: 'Student',
            icon: Icons.school,
            description: 'Access learning materials and courses',
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14)),

          _buildRoleCard(
            role: UserRole.instructor,
            title: 'Instructor',
            icon: Icons.person,
            description: 'Manage courses and teach students',
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14)),

          _buildRoleCard(
            role: UserRole.eventOrganizer,
            title: 'Event Organizer',
            icon: Icons.event,
            description: 'Create and manage events',
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14)),

          _buildRoleCard(
            role: UserRole.everyone,
            title: 'General User',
            icon: Icons.public,
            description: 'General app access',
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),

          SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28)),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: isVerySmallScreen ? 45 : (isSmallScreen ? 50 : 56),
            child: ElevatedButton(
              onPressed: _selectedRole == null
                  ? null
                  : () {
                      Navigator.pop(context, _selectedRole!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.isSignUp ? 'Continue to Sign Up' : 'Continue to Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isVerySmallScreen
                      ? 14
                      : (isSmallScreen ? 14.5 : 15),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required IconData icon,
    required String description,
    required bool isSmallScreen,
    required bool isVerySmallScreen,
  }) {
    final isSelected = _selectedRole == role;

    return Card(
      color: isSelected
          ? const Color(0xFF5F299E).withOpacity(0.1)
          : Colors.grey[50],
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? const Color(0xFF5F299E) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
          vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
        ),
        leading: Container(
          width: isVerySmallScreen ? 36 : (isSmallScreen ? 40 : 44),
          height: isVerySmallScreen ? 36 : (isSmallScreen ? 40 : 44),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5F299E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF5F299E),
            size: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 22),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 16),
            color: isSelected ? const Color(0xFF5F299E) : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
            color: isSelected
                ? const Color(0xFF5F299E).withOpacity(0.8)
                : Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: const Color(0xFF5F299E),
                size: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
      ),
    );
  }
}
