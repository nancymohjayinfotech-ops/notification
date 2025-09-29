import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/event_auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _resendEnabled = false;
  int _resendTimer = 30;
  late EventAuthService _authService;

  @override
  void initState() {
    super.initState();
    _initializeAuthService();
    _startResendTimer();
  }

  Future<void> _initializeAuthService() async {
    final prefs = await SharedPreferences.getInstance();
    final apiClient = ApiClient(prefs);
    _authService = EventAuthService(apiClient, prefs);
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendEnabled = false;
    _resendTimer = 30;
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startResendTimer();
          } else {
            _resendEnabled = true;
          }
        });
      }
    });
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      setState(() => _isLoading = true);
      
      try {
        final response = await _authService.verifyOtp(widget.phoneNumber, otp);
        
        if (response.success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to home on success
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 24.sp),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              SizedBox(height: 24.h),

              // Header
              Text(
                'Verify Phone',
                style: GoogleFonts.poppins(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              RichText(
                text: TextSpan(
                  text: 'Code sent to ', 
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  children: [
                    TextSpan(
                      text: '+91 ${widget.phoneNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45.w,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        // Auto-verify if all fields are filled
                        if (value.isNotEmpty &&
                            _otpControllers.every(
                                (controller) => controller.text.isNotEmpty)) {
                          _verifyOtp();
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(height: 32.h),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24.h),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive code? ',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: _resendEnabled
                        ? () {
                            // Resend OTP logic
                            _startResendTimer();
                            // TODO: Implement resend OTP
                          }
                        : null,
                    child: Text(
                      _resendEnabled
                          ? 'Resend Code'
                          : 'Resend in $_resendTimer',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _resendEnabled ? Colors.blue : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
