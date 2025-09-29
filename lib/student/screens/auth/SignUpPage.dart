import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_role.dart';
import 'role_selection_screen.dart';

class Signuppage extends StatefulWidget {
  final UserRole initialRole;
  final bool isSignUp;

  const Signuppage({
    super.key,
    required this.initialRole,
    required this.isSignUp,
  });

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  final bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.everyone;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // ❌ REMOVE the auth state listener setup
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final authService = Provider.of<AuthService>(context, listen: false);
    //   authService.addListener(_authListener);
    // });
  }

  // ❌ REMOVE the _authListener method
  // void _authListener() {
  //   final authService = Provider.of<AuthService>(context, listen: false);
  //   final user = authService.currentUser;
  //   if (user != null && !authService.needsPhoneVerification) {
  //     _navigateToHome(user.role);
  //   }
  // }

  @override
  void dispose() {
    // ❌ REMOVE the auth state listener cleanup
    // final authService = Provider.of<AuthService>(context, listen: false);
    // authService.removeListener(_authListener);

    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToHome(UserRole role) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final home = authService.getHomeScreenForRole(role);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
          (route) => false,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Only allow Google or phone sign up
        _showSnackBar(
          "Please use Google sign up or phone OTP to create an account.",
          isError: true,
        );
      } catch (e) {
        _showSnackBar('An error occurred. Please try again.', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      bool success = await authService.signInWithGoogle(
        role: _selectedRole.value,
      );

      if (!success) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          authService.errorMessage ?? 'Google sign-in cancelled or failed',
          isError: true,
        );
        return;
      }

      final user = authService.currentUser;
      final needsPhone =
          user == null || user.phoneNumber == null || user.phoneNumber!.isEmpty;

      // if (needsPhone) {
      //   final phoneNumber = await Navigator.of(context).push<String>(
      //     MaterialPageRoute(
      //       builder: (context) => PhoneLoginPage(
      //         selectedRole: _selectedRole.value, // Pass the role
      //       ),
      //     ),
      //   );

      //   if (phoneNumber == null || phoneNumber.isEmpty) {
      //     setState(() {
      //       _isLoading = false;
      //     });
      //     _showSnackBar('Phone number is required', isError: true);
      //     return;
      //   }

      //   final otp = await authService.sendOtp(phoneNumber);

      //   if (otp == null) {
      //     setState(() {
      //       _isLoading = false;
      //     });
      //     _showSnackBar('Failed to send OTP', isError: true);
      //     return;
      //   }

      //   await TokenService().saveTokens(
      //     accessToken:
      //     'google_access_token_${DateTime.now().millisecondsSinceEpoch}',
      //     refreshToken:
      //     'google_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      //     expiresInSeconds: 3600,
      //     phoneNumber: phoneNumber,
      //   );

      //   final verified = await Navigator.of(context).push<bool>(
      //     MaterialPageRoute(
      //       builder: (context) => OtpVerificationPage(
      //         phoneNumber: phoneNumber,
      //         autoFillOtp: otp, // <-- Pass the OTP here!
      //       ),
      //     ),
      //   );

      //   if (verified == true) {
      //     _navigateToHome(_selectedRole);
      //   } else {
      //     _showSnackBar('Phone verification failed', isError: true);
      //   }
      // } else {
      //   await TokenService().saveTokens(
      //     accessToken:
      //     'google_access_token_${DateTime.now().millisecondsSinceEpoch}',
      //     refreshToken:
      //     'google_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      //     expiresInSeconds: 3600,
      //     phoneNumber: user.phoneNumber!,
      //   );

      //   _navigateToHome(_selectedRole);
      // }
    } catch (e) {
      // Enhanced error handling to prevent crashes
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('PlatformException')) {
        if (e.toString().contains('ApiException: 10')) {
          errorMessage = 'Google Sign-In configuration error. Please contact support.';
        } else if (e.toString().contains('sign_in_canceled')) {
          errorMessage = 'Sign-in was cancelled';
        } else {
          errorMessage = 'Authentication failed. Please try again.';
        }
      } else if (e.toString().contains('403')) {
        errorMessage = 'Service temporarily unavailable. Please try again later.';
      }

      debugPrint('SignUpPage Google Sign-In error: $e');
      _showSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectRole() async {
    final selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => RoleSelectionScreen(isSignUp: widget.isSignUp),
    );

    if (selectedRole != null) {
      setState(() {
        _selectedRole = selectedRole;
      });
    }
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
                // Main auth content with animation - centered
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildAuthForm(
                          context,
                          isSmallScreen,
                          isVerySmallScreen,
                          isDesktop,
                          isTablet,
                          screenWidth, // Pass screenWidth here
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

  Widget _buildAuthForm(
      BuildContext context,
      bool isSmallScreen,
      bool isVerySmallScreen,
      bool isDesktop,
      bool isTablet,
      double screenWidth, // Add this parameter
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text
            Center(
              child: Column(
                children: [
                  Text(
                    'Choose Your Role',
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
                    'Select your role and sign in with Google or Phone',
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
            SizedBox(
              height: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
            ),

            // Role selection (KEPT)
            _buildRoleSelector(isSmallScreen, isVerySmallScreen),
            SizedBox(
              height: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
            ),

            // Commented out: All other form fields (name, email, phone, passwords)
            /*
            // Form fields are commented out
            */

            // OR divider (KEPT for Google button)
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen
                        ? 12
                        : (isSmallScreen ? 14 : 16),
                  ),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isVerySmallScreen
                          ? 14
                          : (isSmallScreen ? 15 : 16),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),

            SizedBox(
              height: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
            ),

            // Google sign-in button (KEPT)
            _buildSocialButton(
              'Sign in with Google',
              Colors.blue[400]!,
              Icons.g_mobiledata_outlined,
              _signInWithGoogle,
              isSmallScreen,
              isVerySmallScreen,
            ),

            SizedBox(
              height: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
            ),

            // Phone sign-in button
            // _buildPhoneButton(
            //   'Sign in with Phone',
            //   const Color(0xFF5F299E),
            //   Icons.phone,
            //   _handlePhoneLogin,
            //   isSmallScreen,
            //   isVerySmallScreen,
            // ),

            // Commented out: Facebook and Apple buttons
            /*
            // Other social buttons are commented out
            */

            // Commented out: Toggle section
            /*
            // Toggle between login/signup is commented out
            */
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      height: isVerySmallScreen ? 45 : (isSmallScreen ? 47 : 50),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: _selectRole,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: isVerySmallScreen ? 45 : (isSmallScreen ? 47 : 50),
              height: isVerySmallScreen ? 45 : (isSmallScreen ? 47 : 50),
              decoration: BoxDecoration(
                color: const Color(0xFF5F299E).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(
                _getRoleIcon(_selectedRole),
                color: const Color(0xFF5F299E),
                size: isVerySmallScreen ? 18 : (isSmallScreen ? 19 : 20),
              ),
            ),
            // Role text
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen
                      ? 12
                      : (isSmallScreen ? 13 : 14),
                ),
                child: Text(
                  _getRoleTitle(_selectedRole),
                  style: TextStyle(
                    fontSize: isVerySmallScreen
                        ? 13
                        : (isSmallScreen ? 13.5 : 14),
                    color: const Color(0xFF2D3748),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Dropdown icon
            Padding(
              padding: EdgeInsets.only(
                right: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
              ),
              child: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white70,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Social login button widget
  Widget _buildSocialButton(
      String text,
      Color color,
      IconData icon,
      VoidCallback onTap,
      bool isSmallScreen,
      bool isVerySmallScreen,
      ) {
    return Container(
      height: isVerySmallScreen ? 42 : (isSmallScreen ? 46 : 50),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isVerySmallScreen ? 18 : (isSmallScreen ? 19 : 20),
              ),
              SizedBox(width: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10)),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced text field widget with proper alignment
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool isSmallScreen = false,
    bool isVerySmallScreen = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: isVerySmallScreen ? 45 : (isSmallScreen ? 47 : 50),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Icon container with proper alignment
          Container(
            width: isVerySmallScreen ? 45 : (isSmallScreen ? 47 : 50),
            height: isVerySmallScreen ? 45 : (isSmallScreen ? 47 : 50),
            decoration: BoxDecoration(
              color: const Color(0xFF5F299E).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5F299E),
              size: isVerySmallScreen ? 18 : (isSmallScreen ? 19 : 20),
            ),
          ),
          // Text field with proper alignment
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(
                fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 13.5 : 14),
                color: const Color(0xFF2D3748),
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: isVerySmallScreen
                      ? 13
                      : (isSmallScreen ? 13.5 : 14),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen
                      ? 12
                      : (isSmallScreen ? 13 : 14),
                  vertical: isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 16),
                ),
                isDense: true,
                errorStyle: TextStyle(
                  fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _handlePhoneLogin() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => PhoneLoginPage(
  //         selectedRole: _selectedRole.value,
  //       ),
  //     ),
  //   );
  // }

  // Phone login button widget
  Widget _buildPhoneButton(
      String text,
      Color color,
      IconData icon,
      VoidCallback onTap,
      bool isSmallScreen,
      bool isVerySmallScreen,
      ) {
    return Container(
      height: isVerySmallScreen ? 42 : (isSmallScreen ? 46 : 50),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: isVerySmallScreen ? 18 : (isSmallScreen ? 19 : 20),
              ),
              SizedBox(width: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10)),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.instructor:
        return 'Instructor';
      case UserRole.eventOrganizer:
        return 'Event Organizer';
      case UserRole.everyone:
        return 'General User';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school;
      case UserRole.instructor:
        return Icons.person;
      case UserRole.eventOrganizer:
        return Icons.event;
      case UserRole.everyone:
        return Icons.public;
    }
  }
}
