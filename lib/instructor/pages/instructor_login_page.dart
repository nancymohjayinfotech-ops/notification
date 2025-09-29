import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/auth_service.dart'; // Updated import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertest/student/screens/auth/FormCommonPageScreen.dart';

class InstructorLoginPage extends StatefulWidget {
  const InstructorLoginPage({super.key});

  @override
  State<InstructorLoginPage> createState() => _InstructorLoginPageState();
}

class _InstructorLoginPageState extends State<InstructorLoginPage>
    with TickerProviderStateMixin {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  bool isOtpSent = false;
  bool isLoading = false;
  String errorMessage = '';
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
    phoneController.dispose();
    otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fieldHeight = size.height * 0.065 > 60 ? 60.0 : size.height * 0.065;
    final isLargeScreen = size.width > 900;
    final isMediumScreen = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Instructor Sign In'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isLargeScreen) {
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/shape7.png"),
                          fit: BoxFit.cover,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black12],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school, size: 80, color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              "Welcome to MI-Skills",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Your teaching platform",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: _loginPage(context, size, fieldHeight),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: isMediumScreen ? 150 : 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/shape7.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black12],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: isMediumScreen
                        ? size.height * 0.03
                        : size.height * 0.02,
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _loginPage(context, size, fieldHeight),
                    ),
                  ),
                  SizedBox(
                    height: isMediumScreen
                        ? size.height * 0.03
                        : size.height * 0.02,
                  ),
                  Container(
                    height: isMediumScreen ? 100 : 80,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/shape6.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loginPage(BuildContext context, Size size, double fieldHeight) {
    final double boxPadding = size.width > 600 ? 32.0 : size.width * 0.06;
    final double maxBoxWidth = size.width > 1200
        ? 600.0
        : (size.width > 900 ? 500.0 : 400.0);

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: boxPadding),
        padding: EdgeInsets.all(boxPadding),
        constraints: BoxConstraints(maxWidth: maxBoxWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF5F299E),
            width: size.width > 600 ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
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
                  Text(
                    'Instructor Portal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: size.width > 600 ? 32 : 26,
                      color:
                          Theme.of(context).textTheme.titleLarge?.color ??
                          const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpSent
                        ? 'Enter OTP sent to your phone'
                        : 'Sign in with OTP to access your dashboard',
                    style: TextStyle(
                      fontSize: size.width > 600 ? 18 : 15,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.025),
            if (!isOtpSent)
              _buildEnhancedTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                height: fieldHeight,
              )
            else
              _buildEnhancedTextField(
                controller: otpController,
                label: "OTP Code",
                icon: Icons.lock_outline_rounded,
                keyboardType: TextInputType.number,
                height: fieldHeight,
              ),
            SizedBox(height: size.height * 0.02),
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: size.width > 600 ? 15 : 14,
                  ),
                ),
              ),
            Row(
              children: [
                Transform.scale(
                  scale: size.width > 600 ? 1.3 : 1.2,
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
                const SizedBox(width: 8),
                Text(
                  "Remember Phone Number",
                  style: TextStyle(
                    color: const Color(0xFF4A5568),
                    fontSize: size.width > 600 ? 16 : 15,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.width > 600 ? 32 : 24),
            Container(
              height: size.width > 600 ? fieldHeight + 12 : fieldHeight + 6,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF5F299E), Color(0xFF7236B5)],
                ),
                borderRadius: BorderRadius.circular(size.width > 600 ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5F299E).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    size.width > 600 ? 20 : 16,
                  ),
                  onTap: () {
                    if (isLoading) return;
                    isOtpSent ? _verifyOTP(context) : _sendOTP(context);
                  },
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOtpSent
                                    ? Icons.check_circle_outline
                                    : Icons.send,
                                color: Colors.white,
                                size: size.width > 600 ? 24 : 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isOtpSent ? "Verify OTP" : "Send OTP",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: size.width > 600 ? 20 : 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: size.width > 600 ? 24 : 16),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: size.width > 900 ? 12 : 8,
                horizontal: size.width > 600 ? 16 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Are you a student? ",
                    style: TextStyle(
                      fontSize: size.width > 600 ? 16 : 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sign in as Student',
                      style: TextStyle(
                        color: const Color(0xFF5F299E),
                        fontSize: size.width > 600 ? 16 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isOtpSent)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF5F299E)),
                  label: Text(
                    'Back to Phone Input',
                    style: TextStyle(
                      color: const Color(0xFF5F299E),
                      fontSize: size.width > 600 ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      isOtpSent = false;
                      otpController.clear();
                      errorMessage = '';
                    });
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOTP(BuildContext context) async {
    final phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your phone number';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await InstructorAuthService.sendOTP(phoneNumber);

      if (result['success'] == true) {
        debugPrint('OTP sent successfully. Check console for the OTP code.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP sent successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          isOtpSent = true;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to send OTP';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP(BuildContext context) async {
    final phoneNumber = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        errorMessage = 'Please enter the OTP sent to your phone';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('🔵 INSTRUCTOR LOGIN - Calling verifyOTP with phone: $phoneNumber, otp: $otp');
      final result = await InstructorAuthService.verifyOTP(phoneNumber, otp);
      print('🔵 INSTRUCTOR LOGIN - verifyOTP result: $result');

      // Verify tokens were saved after OTP verification
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('access_token');
      print('🔵 INSTRUCTOR LOGIN - Token after verifyOTP: ${savedToken?.substring(0, 20) ?? 'null'}...');

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP Verified!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Check if user has completed profile
        final userData = result['data']?['user'];
        final hasCompletedProfile = userData != null && 
            userData['name'] != null && 
            userData['name'].toString().isNotEmpty &&
            userData['role'] != null;
        
        if (hasCompletedProfile) {
          // User has completed profile, go to dashboard
          String instructorName = userData['name'] ?? 'Instructor';
          Navigator.pushReplacementNamed(
            context,
            '/instructordashboard',
            arguments: instructorName,
          );
        } else {
          // User needs to complete profile first
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FormCommonPageScreen(
                authMethod: 'otp',
                prefilledPhone: phoneNumber,
                userRole: 'instructor',
              ),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Invalid OTP';
          isLoading = false;
        });
      }
    } catch (e) {
      String errorMsg;

      if (e.toString().contains(
        "type 'Null' is not a subtype of type 'String'",
      )) {
        errorMsg = 'Server error. Please try again.';
      } else {
        errorMsg = 'Network error. Please check your connection.';
      }

      setState(() {
        errorMessage = errorMsg;
        isLoading = false;
      });
    }
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    double? height,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final responsiveHeight = screenSize.width > 900
        ? 70.0
        : (screenSize.width > 600 ? 64.0 : height ?? 56.0);
    final fontSize = screenSize.width > 600 ? 17.0 : 16.0;

    return Container(
      height: responsiveHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenSize.width > 600 ? 18 : 16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: screenSize.width > 600 ? 16.0 : 12.0,
            ),
            child: Icon(
              icon,
              color: Colors.grey[600],
              size: screenSize.width > 600 ? 26 : 24,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: screenSize.width > 600 ? 20 : 16,
            bottom: screenSize.width > 600 ? 20 : 16,
          ),
        ),
      ),
    );
  }
}
