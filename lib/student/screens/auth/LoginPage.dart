import 'package:flutter/material.dart';
import 'package:fluttertest/student/models/user.dart';
import 'package:fluttertest/student/screens/auth/SignUpPage.dart';
import 'package:fluttertest/student/widgets/BoldText.dart';
import 'package:fluttertest/student/models/user_role.dart';
import 'package:fluttertest/student/screens/auth/PhoneLoginPage.dart';
import 'package:fluttertest/student/services/push_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool tracker = false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define breakpoints
    final isSmallPhone = screenWidth < 360;
    final isVerySmallPhone = screenHeight < 650;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveLayout(context, screenWidth, screenHeight, isSmallPhone, isVerySmallPhone, isMobile, isTablet, isDesktop),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, double screenWidth, double screenHeight,
      bool isSmallPhone, bool isVerySmallPhone, bool isMobile, bool isTablet, bool isDesktop) {

    if (isDesktop || isTablet) {
      // Desktop and Tablet Layout - Split screen with form on left, illustration on right
      return Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8E2F7),
              Color(0xFFF3F0FF),
              Color(0xFFE8E2F7),
            ],
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
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: isDesktop ? 40 : 30,
                  offset: const Offset(0, 20),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side - Login Form
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
                // Right side - Illustration
                Expanded(
                  flex: isDesktop ? 6 : 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7C3AED),
                          Color(0xFF5F299E),
                        ],
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
      // Mobile Layout
      return Container(
        height: screenHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            Column(
              children: [
                // Top decorative shape
                SizedBox(
                  height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
                  child: Stack(
                    children: [
                      Image.asset(
                        "assets/images/shape7.png",
                        width: double.infinity,
                        height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main login content
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildMobileLoginForm(context, isSmallPhone, isVerySmallPhone),
                      ),
                    ),
                  ),
                ),
                // Bottom decorative shape
                SizedBox(
                  height: isVerySmallPhone ? 60 : (isSmallPhone ? 80 : 120),
                  child: Image.asset(
                    "assets/images/shape6.png",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWebLoginForm(BuildContext context, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 380 : 340,
        maxHeight: isDesktop ? 520 : 460,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          Center(
            child: Column(
              children: [
                BoldText(
                  font: 'YourFontFamily',
                  text: 'Welcome MI SKILLS!',
                  size: isDesktop ? 24 : 22,
                  color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF2D3748),
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                Text(
                  'Sign in to continue your journey',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
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
          SizedBox(height: isDesktop ? 10 : 8),
          Row(
            children: [
              Transform.scale(
                scale: isDesktop ? 1.2 : 1.0,
                child: Checkbox(
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(
                    color: tracker
                        ? const Color(0xFF5F299E)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                  activeColor: const Color(0xFF5F299E),
                  value: tracker,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        tracker = value;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 4),
              BoldText(
                font: "YourFontFamily",
                text: "Remember Me",
                color: const Color(0xFF4A5568),
                size: isDesktop ? 14 : 13,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Add forgot password functionality
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: const Color(0xFF5F299E),
                    fontSize: isDesktop ? 13 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
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
                  color: const Color(0xFF5F299E).withOpacity(0.4),
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
          
          // Phone login button for web
          SizedBox(height: isDesktop ? 12 : 10),
          Container(
            height: isDesktop ? 52 : 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5F299E), width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _handlePhoneLogin(context),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone,
                        color: const Color(0xFF5F299E),
                        size: isDesktop ? 20 : 18,
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      BoldText(
                        font: "YourFontFamily",
                        text: "Sign In with Phone",
                        size: isDesktop ? 16 : 15,
                        color: const Color(0xFF5F299E),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: isDesktop ? 16 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: Colors.grey[600]
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Signuppage(
                        initialRole: UserRole.student, // or your desired default role
                        isSignUp: true,
                      ),
                    ),
                  );
                },
                child: BoldText(
                  font: 'YourFontFamily',
                  text: 'Sign Up',
                  size: isDesktop ? 14 : 13,
                  color: const Color(0xFF5F299E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLoginForm(BuildContext context, bool isSmallPhone, bool isVerySmallPhone) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 24)),
      padding: EdgeInsets.all(isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 28)),
      constraints: const BoxConstraints(maxWidth: 400),
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
          Center(
            child: Column(
              children: [
                BoldText(
                  font: 'YourFontFamily',
                  text: 'Welcome Back!',
                  size: isVerySmallPhone ? 20 : (isSmallPhone ? 22 : 26),
                  color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF2D3748),
                ),
                SizedBox(height: isVerySmallPhone ? 3 : (isSmallPhone ? 4 : 6)),
                Text(
                  'Sign in to continue your journey',
                  style: TextStyle(
                    fontSize: isVerySmallPhone ? 12 : (isSmallPhone ? 13 : 15),
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isVerySmallPhone ? 18 : (isSmallPhone ? 24 : 32)),
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
          SizedBox(height: isVerySmallPhone ? 6 : (isSmallPhone ? 8 : 12)),
          Row(
            children: [
              Transform.scale(
                scale: isVerySmallPhone ? 0.9 : (isSmallPhone ? 1.0 : 1.2),
                child: Checkbox(
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(
                    color: tracker
                        ? const Color(0xFF5F299E)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                  activeColor: const Color(0xFF5F299E),
                  value: tracker,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        tracker = value;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: isVerySmallPhone ? 3 : (isSmallPhone ? 4 : 8)),
              BoldText(
                font: "YourFontFamily",
                text: "Remember Me",
                color: const Color(0xFF4A5568),
                size: isVerySmallPhone ? 12 : (isSmallPhone ? 13 : 15),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Add forgot password functionality
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: const Color(0xFF5F299E),
                    fontSize: isVerySmallPhone ? 11 : (isSmallPhone ? 12 : 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 24)),
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
                  color: const Color(0xFF5F299E).withOpacity(0.4),
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
                    size: isVerySmallPhone ? 15 : (isSmallPhone ? 16 : 18),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          
          // Phone login button for mobile
          SizedBox(height: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 20)),
          Container(
            height: isVerySmallPhone ? 45 : (isSmallPhone ? 50 : 56),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5F299E), width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _handlePhoneLogin(context),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone,
                        color: const Color(0xFF5F299E),
                        size: isVerySmallPhone ? 18 : (isSmallPhone ? 20 : 22),
                      ),
                      SizedBox(width: isVerySmallPhone ? 6 : (isSmallPhone ? 8 : 10)),
                      BoldText(
                        font: "YourFontFamily",
                        text: "Sign In with Phone",
                        size: isVerySmallPhone ? 14 : (isSmallPhone ? 15 : 16),
                        color: const Color(0xFF5F299E),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  fontSize: isVerySmallPhone ? 12 : (isSmallPhone ? 13 : 15),
                  color: Colors.grey[600]
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Signuppage(
                        initialRole: UserRole.student, // or your desired default role
                        isSignUp: true,
                      ),
                    ),
                  );
                },
                child: BoldText(
                  font: 'YourFontFamily',
                  text: 'Sign Up',
                  size: isVerySmallPhone ? 12 : (isSmallPhone ? 13 : 15),
                  color: const Color(0xFF5F299E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    String email = emailController.text.trim();
    String password = passwordController.text;

   User? loggedInUser;

    for (var user in registeredUsers) {
      if (user.email == email && user.password == password) {
        loggedInUser  = user;
        break;
      }
    }

    if(loggedInUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("OTP Verified!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/interestpage',
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Invalid email or password"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        
      );
      
    }
  }

  void _handlePhoneLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhoneLoginPage()),
    );
  }

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
          Container(
            width: iconSize,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF5F299E).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(icon, color: const Color(0xFF5F299E), size: iconSizeIcon),
          ),
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

  Widget _buildIllustrationSection(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 30,
          left: 30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        Center(
          child: Stack(
            children: [
              Container(
                width: 420,
                height: 480,
                decoration: BoxDecoration(
                  color: const Color(0xFFB19CD9).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      cacheWidth: 840,
                      cacheHeight: 960,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/login-web image.png',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          cacheWidth: 840,
                          cacheHeight: 960,
                          errorBuilder: (context, error2, stackTrace2) {
                            return Container(
                              width: 420,
                              height: 480,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB19CD9).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 240,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 140,
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
                                      fontSize: 20,
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
              Positioned(
                bottom: 80,
                left: 40,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 35,
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
}