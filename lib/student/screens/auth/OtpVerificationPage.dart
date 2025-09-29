import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertest/student/screens/Home/Dashboard.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../services/token_service.dart';
import 'FormCommonPageScreen.dart';
import '../auth/UserProfileForm.dart';
import '../categories/InterestBasedPage.dart';
import '../../../instructor/pages/instructor_dashboard.dart';
import '../../../event/main_event.dart' as event_app;
import 'package:fluttertest/instructor/services/auth_service.dart';

import 'package:fluttertest/instructor/widgets/instructor_wrapper.dart';

import 'package:fluttertest/event/src/core/services/event_auth_service.dart';

import 'package:fluttertest/event/src/core/api/api_client.dart' as event_api;

import '../../models/user_role.dart';

import 'package:fluttertest/event/src/features/presentation/home_page.dart'
    as event_home;

import 'package:fluttertest/event/main_event.dart' show MainPage;

import "../../services/token_service.dart";

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String? autoFillOtp;

  const OtpVerificationPage({
    required this.phoneNumber,
    this.autoFillOtp,
    super.key,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final TokenService _tokenService = TokenService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all digits are entered
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter complete OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiConfig.verifyOtp,
        data: {'phoneNumber': widget.phoneNumber, 'otp': _otpCode},
      );

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Show success message with response data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'OTP verified successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Print response for debugging
          print('OTP Verification Success Response:');
          print(
            "$responseData jhhhhhhhvdkhgdjkchdsgvcjkdshgcdhgvdejhfgedujfyhgeujhedgfkuduhgvhgvedujhfved",
          );

          // Save tokens from API response
          await _saveTokensFromResponse(responseData);

          // Store verification status from profileStatus
          final profileStatus =
              responseData['profileStatus'] as Map<String, dynamic>?;
          final isVerified = profileStatus?['isVerified'] ?? false;
          final tokenService = TokenService();
          await tokenService.setVerificationStatus(isVerified);

          // Navigate based on role and profile completion status
          _navigateBasedOnRoleAndProfile(responseData, authMethod: 'otp');
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Invalid OTP';
          });
        }
      } else {
        setState(() {
          _errorMessage = response.error?.message ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTokensFromResponse(
    Map<String, dynamic> responseData,
  ) async {
    try {
      final data = responseData['data'] ?? {};
      final userData = data['user'] ?? responseData['user'] ?? {};
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final role = userData['role']?.toString().toLowerCase() ?? '';

      if (accessToken != null && accessToken.isNotEmpty) {
        print('💾 Saving tokens for role: $role');
        print('💾 Access Token: ${accessToken.substring(0, 20)}...');

        if (role == 'instructor' || role == 'event') {
          // Save tokens using SharedPreferences for instructors and event organizers
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken ?? '');
          await prefs.setString('user_role', role);
          await prefs.setString('user_phone', widget.phoneNumber);
          await prefs.setString('user_id', userData['_id'] ?? '');
          print('✅ ${role.toUpperCase()} tokens saved to SharedPreferences');
        } else {
          // Save tokens using TokenService for students
          await _tokenService.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            phoneNumber: widget.phoneNumber,
          );
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('user_id', userData['_id'] ?? '');
          print('✅ Student tokens saved to TokenService');
        }
      } else {
        print('❌ No access token found in response');
      }
    } catch (e) {
      print('❌ Error saving tokens: $e');
    }
  }

  void _navigateBasedOnRoleAndProfile(
    Map<String, dynamic> responseData, {
    String? authMethod,
  }) {
    // Extract user data from response
    final data = responseData['data'] ?? {};
    final userData = data['user'] ?? responseData['user'] ?? {};
    final profileStatus = data['profileStatus'] ?? {};

    final String role = (userData['role'] ?? '').toString().toLowerCase();
    final bool isProfileComplete = profileStatus['isProfileComplete'] ?? false;
    final bool isVerified = profileStatus['isVerified'] ?? false;

    print(
      'Navigation Logic - Role: $role, IsProfileComplete: $isProfileComplete, IsVerified: $isVerified',
    );

    // Navigate based on role and profile completion status
    if (role == 'student') {
      if (!isProfileComplete) {
        // Student with incomplete profile -> UserProfileForm -> InterestBasedPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileForm(
              authMethod: authMethod,
              prefilledPhone: widget.phoneNumber,
              prefilledEmail: authMethod == 'google'
                  ? userData['email']
                  : null, // For Google auth, pass the email from Google Sign-In
            ),
          ),
        );
      } else {
        // Student with complete profile -> Student Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      }
    } else if (role == 'instructor') {
      if (!isProfileComplete) {
        // Instructor with incomplete profile -> FormCommonPageScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FormCommonPageScreen(
              authMethod: authMethod,
              prefilledPhone: widget.phoneNumber,
              userRole: 'instructor',
            ),
          ),
        );
      } else {
        // Instructor with complete profile -> Instructor Dashboard
        // Pass verification status to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InstructorDashboard(
              instructorName: userData['name'] ?? 'Instructor',
              initialVerificationStatus: isVerified,
            ),
          ),
        );
      }
    } else if (role == 'event') {
      if (!isProfileComplete) {
        // Event organizer with incomplete profile -> FormCommonPageScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FormCommonPageScreen(
              authMethod: authMethod,
              prefilledPhone: widget.phoneNumber,
              userRole: 'event_organizer',
            ),
          ),
        );
      } else {
        // Event organizer with complete profile -> Event MainPage
        // Pass verification status to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => event_app.MainPage(
              organizerName: userData['name'] ?? 'Event Organizer',
              initialVerificationStatus: isVerified,
            ),
          ),
        );
      }
    } else {
      // Default case for other roles or unknown roles
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InterestBasedPage()),
      );
    }
  }

  Future<void> _resendOtp() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiConfig.sendOtp,
        data: {'phoneNumber': widget.phoneNumber},
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-fill OTP if provided
    if (widget.autoFillOtp != null && widget.autoFillOtp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = widget.autoFillOtp![i];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyOtp();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Title
              Text(
                'Verify Phone Number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2D2D2D)
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _onOtpChanged(index, value),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withAlpha(isDark ? 120 : 76),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              const SizedBox(height: 10),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: isDark
                        ? Colors.grey[700] 
                        : Colors.grey[300],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Help Text
              Center(
                child: Text(
                  'Didn\'t receive the code? Check your SMS or try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
