import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/auth/PhoneLoginPage.dart';
import 'package:fluttertest/student/screens/auth/PhonePageScreen.dart';
import '../../widgets/BoldText.dart';
import 'package:fluttertest/student/screens/auth/UserProfileForm.dart';
import 'package:fluttertest/student/services/auth_service.dart';
import '../../../admin/services/api_service.dart';
import '../../../admin/app.dart';

class LoginPageScreen extends StatefulWidget {
  const LoginPageScreen({super.key});

  @override
  State<LoginPageScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController(); // For signup
  bool tracker = false;
  int selectedTabIndex = 1; // 0 for Signup, 1 for Login (default to Login)
  String selectedRole = 'Student'; // Track selected role for signup
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Navigate to phone page with selected role
  void _navigateToPhonePageWithRole(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PhonePageScreeen(selectedRole: selectedRole.toLowerCase()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define breakpoints
    final isSmallPhone = screenWidth < 360;
    final isVerySmallPhone =
        screenHeight < 650; // For very small height screens
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _buildResponsiveLayout(
          context,
          screenWidth,
          screenHeight,
          isSmallPhone,
          isVerySmallPhone,
          isMobile,
          isTablet,
          isDesktop,
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    bool isSmallPhone,
    bool isVerySmallPhone,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    if (isDesktop || isTablet) {
      // Desktop and Tablet Layout - Split screen with form on left, illustration on right
      return Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8E2F7), Color(0xFFF3F0FF), Color(0xFFE8E2F7)],
          ),
        ),
        child: Center(
          child: Container(
            width: screenWidth * (isDesktop ? 0.9 : 0.95),
            height: screenHeight * (isDesktop ? 0.85 : 0.9),
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1200 : 900,
              maxHeight: isDesktop ? 700 : 650,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isDesktop ? 32 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: isDesktop ? 40 : 30,
                  offset: const Offset(0, 20),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side - Login Form with improved spacing
                Expanded(
                  flex: isDesktop ? 5 : 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 60 : 40,
                      vertical: isDesktop ? 40 : 30,
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildWebLoginForm(context, isDesktop),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right side - Illustration with improved proportions
                Expanded(
                  flex: isDesktop ? 6 : 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7C3AED), Color(0xFF5F299E)],
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(isDesktop ? 32 : 24),
                        bottomRight: Radius.circular(isDesktop ? 32 : 24),
                      ),
                    ),
                    child: _buildIllustrationSection(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile Layout - Centered box with background images behind
      return Stack(
        children: [
          // Background images positioned behind the content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
              child: Image.asset(
                "assets/images/shape7.png",
                width: double.infinity,
                height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: isVerySmallPhone ? 60 : (isSmallPhone ? 80 : 120),
              child: Image.asset(
                "assets/images/shape6.png",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Centered login form
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 24),
                  vertical: isVerySmallPhone ? 20 : (isSmallPhone ? 30 : 40),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildMobileLoginForm(
                      context,
                      isSmallPhone,
                      isVerySmallPhone,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildWebLoginForm(BuildContext context, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 380 : 340,
        maxHeight: isDesktop ? 580 : 520,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text with enhanced styling
          Center(
            child: Column(
              children: [
                BoldText(
                  font: 'YourFontFamily',
                  text: 'Welcome MI SKILLS!',
                  size: isDesktop ? 24 : 22,
                  color:
                      Theme.of(context).textTheme.titleLarge?.color ??
                      const Color(0xFF2D3748),
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                Text(
                  selectedTabIndex == 1
                      ? 'Sign in to continue your journey'
                      : 'Create your account to get started',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Tab selector
          _buildTabSelector(isDesktop: isDesktop),

          // Show different content based on selected tab
          if (selectedTabIndex == 1) ...[
            // Login form fields
            _buildEnhancedTextField(
              controller: emailController,
              label: "Email Address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isSmallPhone: false,
              isVerySmallPhone: false,
            ),
            SizedBox(height: isDesktop ? 12 : 10),

            _buildEnhancedTextField(
              controller: passwordController,
              label: "Password",
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              isSmallPhone: false,
              isVerySmallPhone: false,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
          ] else ...[
            // Signup form content
            _buildSignupContent(isDesktop),
          ],

          // Login button and social icons (only for login tab)
          if (selectedTabIndex == 1) ...[
            SizedBox(height: isDesktop ? 12 : 10),
            Container(
              height: isDesktop ? 52 : 50,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5F299E).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleLogin(context),
                  child: Center(
                    child: BoldText(
                      font: "YourFontFamily",
                      text: "Sign In",
                      size: isDesktop ? 16 : 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: isDesktop ? 16 : 12),

            // Social login icons for login tab
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Google sign-in icon
                Container(
                  height: isDesktop ? 56 : 52,
                  width: isDesktop ? 56 : 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF5F299E).withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5F299E).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleGoogleLogin(context),
                      child: Center(
                        child: Image.asset(
                          'assets/images/google_logo.png',
                          width: isDesktop ? 28 : 24,
                          height: isDesktop ? 28 : 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Phone sign-in icon
                Container(
                  height: isDesktop ? 56 : 52,
                  width: isDesktop ? 56 : 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF43A047),
                        Color(0xFF66BB6A),
                      ], // Green gradient
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF43A047).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhoneLoginPage(),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: isDesktop ? 28 : 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLoginForm(
    BuildContext context,
    bool isSmallPhone,
    bool isVerySmallPhone,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 24),
      ),
      padding: EdgeInsets.all(isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 28)),
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text with enhanced styling
            Center(
              child: Column(
                children: [
                  BoldText(
                    font: 'YourFontFamily',
                    text: 'Welcome Back!',
                    size: isVerySmallPhone ? 20 : (isSmallPhone ? 22 : 26),
                    color:
                        Theme.of(context).textTheme.titleLarge?.color ??
                            const Color(0xFF2D3748),
                  ),
                  SizedBox(height: isVerySmallPhone ? 3 : (isSmallPhone ? 4 : 6)),
                  Text(
                    selectedTabIndex == 1
                        ? 'Sign in to continue your journey'
                        : 'Create your account to get started',
                    style: TextStyle(
                      fontSize: isVerySmallPhone ? 12 : (isSmallPhone ? 13 : 15),
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isVerySmallPhone ? 18 : (isSmallPhone ? 24 : 32)),

            // Tab selector
            _buildTabSelector(isDesktop: false),
            SizedBox(height: isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 24)),

            // Show different content based on selected tab
            if (selectedTabIndex == 1) ...[
              // Login form fields
              _buildEnhancedTextField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isSmallPhone: isSmallPhone,
                isVerySmallPhone: isVerySmallPhone,
              ),
              SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

              _buildEnhancedTextField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                isSmallPhone: isSmallPhone,
                isVerySmallPhone: isVerySmallPhone,
              ),
              SizedBox(height: isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 24)),
            ] else ...[
              // Signup form content
              _buildSignupContent(false),
            ],

            // Show social login icons only for login tab
            if (selectedTabIndex == 1) ...[
              // Social login icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Google sign-in icon
                  Container(
                    width: isVerySmallPhone ? 60 : (isSmallPhone ? 65 : 70),
                    height: isVerySmallPhone ? 60 : (isSmallPhone ? 65 : 70),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _handleGoogleLogin(context),
                        child: Center(
                          child: Container(
                            width: isVerySmallPhone
                                ? 28
                                : (isSmallPhone ? 32 : 36),
                            height: isVerySmallPhone
                                ? 28
                                : (isSmallPhone ? 32 : 36),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/google_logo.png',
                                width: isVerySmallPhone
                                    ? 20
                                    : (isSmallPhone ? 24 : 28),
                                height: isVerySmallPhone
                                    ? 20
                                    : (isSmallPhone ? 24 : 28),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Phone sign-in icon
                  Container(
                    width: isVerySmallPhone ? 60 : (isSmallPhone ? 65 : 70),
                    height: isVerySmallPhone ? 60 : (isSmallPhone ? 65 : 70),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF43A047),
                          Color(0xFF66BB6A),
                        ], // Green gradient
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF43A047).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneLoginPage(),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: isVerySmallPhone
                                ? 28
                                : (isSmallPhone ? 32 : 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 20)),

              // Login button (only for login tab)
              Container(
                height: isVerySmallPhone ? 45 : (isSmallPhone ? 50 : 56),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5F299E).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleLogin(context),
                    child: Center(
                      child: BoldText(
                        font: "YourFontFamily",
                        text: "Sign In",
                        size: isVerySmallPhone ? 14 : (isSmallPhone ? 15 : 18),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Handle Google login
  Future<void> _handleGoogleLogin(BuildContext context) async {
    try {
      setState(() {
        tracker = true;
      });

      // Import AuthService and call Google Sign-In
      final authService = AuthService();
      final success = await authService.signInWithGoogle(role: 'student');

      setState(() {
        tracker = false;
      });

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Google Sign-In successful! Please verify your phone number.",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Go directly to UserProfileForm. For Google auth it shows phone field.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileForm(
              authMethod: 'google',
              prefilledEmail: authService.currentUser?.email,
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage ?? "Google Sign-In failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        tracker = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In error: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Handle login logic with admin API
  Future<void> _handleLogin(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter both email and password"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show loading state
    setState(() {
      tracker = true;
    });

    try {
      // Call admin login API
      final result = await ApiService.adminLogin(
        email: email,
        password: password,
      );

      setState(() {
        tracker = false;
      });

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Login Successful - Redirecting to Admin Dashboard",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate to admin dashboard
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminApp()),
            );
          }
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Invalid email or password"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        tracker = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed: ${e.toString()}"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Illustration section for desktop
  Widget _buildIllustrationSection(BuildContext context) {
    return Stack(
      children: [
        // Background decorative elements with improved positioning
        Positioned(
          top: 30,
          left: 30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          right: 40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),

        // Main illustration content with improved size and quality
        Center(
          child: Stack(
            children: [
              // Larger clean rounded container with high-quality image
              Container(
                width: 420, // Increased from 350
                height: 480, // Increased from 400
                decoration: BoxDecoration(
                  color: const Color(0xFFB19CD9).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(
                    40,
                  ), // Slightly larger radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox(
                    width: 420,
                    height: 480,
                    child: Image.asset(
                      'assets/images/login_web_image.png',
                      fit: BoxFit.cover, // Use cover for better quality
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      cacheWidth:
                          840, // Cache at 2x resolution for crisp display
                      cacheHeight:
                          960, // Cache at 2x resolution for crisp display
                      errorBuilder: (context, error, stackTrace) {
                        // Try alternative image name
                        return Image.asset(
                          'assets/images/login-web image.png',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          cacheWidth:
                              840, // Cache at 2x resolution for crisp display
                          cacheHeight:
                              960, // Cache at 2x resolution for crisp display
                          errorBuilder: (context, error2, stackTrace2) {
                            // Clean fallback placeholder with larger size
                            return Container(
                              width: 420,
                              height: 480,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFB19CD9,
                                ).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 240, // Increased proportionally
                                    height: 300, // Increased proportionally
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 140, // Increased icon size
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  const Text(
                                    'Professional Woman\nwith Tablet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20, // Slightly larger text
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Lightning bolt icon with improved positioning and size
              Positioned(
                bottom: 80, // Adjusted for larger container
                left: 40, // Adjusted for larger container
                child: Container(
                  width: 65, // Slightly larger
                  height: 65, // Slightly larger
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 35, // Slightly larger icon
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced text field widget with proper alignment
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool isSmallPhone = false,
    bool isVerySmallPhone = false,
  }) {
    final height = isVerySmallPhone ? 45.0 : (isSmallPhone ? 50.0 : 56.0);
    final iconSize = isVerySmallPhone ? 40.0 : (isSmallPhone ? 45.0 : 50.0);
    final fontSize = isVerySmallPhone ? 13.0 : (isSmallPhone ? 14.0 : 16.0);
    final iconSizeIcon = isVerySmallPhone ? 18.0 : (isSmallPhone ? 20.0 : 22.0);
    final padding = isVerySmallPhone ? 12.0 : (isSmallPhone ? 14.0 : 16.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Icon container with proper alignment
          Container(
            width: iconSize,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF5F299E).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5F299E),
              size: iconSizeIcon,
            ),
          ),
          // Text field with proper alignment
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF2D3748),
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: padding,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build tab selector widget
  Widget _buildTabSelector({bool isDesktop = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTabIndex = 0;
                });
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: selectedTabIndex == 0
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Signup',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 15,
                      fontWeight: selectedTabIndex == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selectedTabIndex == 0
                          ? const Color(0xFF5F299E)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTabIndex = 1;
                });
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: selectedTabIndex == 1
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 15,
                      fontWeight: selectedTabIndex == 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selectedTabIndex == 1
                          ? const Color(0xFF5F299E)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build signup content with role selection
  Widget _buildSignupContent(bool isDesktop) {
    return Column(
      children: [
        // Role selection title
        Text(
          'Choose Your Role',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: isDesktop ? 8 : 6),

        Text(
          'Select your role to get started',
          style: TextStyle(
            fontSize: isDesktop ? 14 : 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // Role selection dropdown
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: isDesktop ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFF5F299E),
              ),
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
              items: ['Student', 'Instructor', 'Event'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedRole = newValue;
                  });
                }
              },
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 20 : 16),

        // Social login icons row (unified design with login tab)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Google sign-in icon
            Container(
              height: isDesktop ? 56 : 52,
              width: isDesktop ? 56 : 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5F299E).withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5F299E).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleGoogleLogin(context),
                  child: Center(
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      width: isDesktop ? 28 : 24,
                      height: isDesktop ? 28 : 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Phone sign-in icon
            Container(
              height: isDesktop ? 56 : 52,
              width: isDesktop ? 56 : 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF43A047),
                        Color(0xFF66BB6A),
                      ], // Green gradient
                    ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43A047).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToPhonePageWithRole(context),
                  child: Center(
                    child: Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: isDesktop ? 28 : 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}