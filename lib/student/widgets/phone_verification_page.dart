// widgets/phone_verification_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationPage({super.key, required this.phoneNumber});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  String? _errorMessage;
  bool _otpSent = false;
  int _timeRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOtp();

    // Set up focus node listeners
    for (int i = 0; i < _otpFocusNodes.length; i++) {
      _otpFocusNodes[i].addListener(() {
        if (!_otpFocusNodes[i].hasFocus && _otpControllers[i].text.isEmpty) {
          if (i > 0) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[i - 1]);
          }
        }
      });
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final otp = await AuthService().sendOtp(widget.phoneNumber);

    setState(() {
      _isLoading = false;
      _otpSent = otp != null;
    });

    if (otp != null) {
      _startTimer();
      // Optionally auto-fill OTP fields for dev/testing:
      for (int i = 0; i < otp.length && i < _otpControllers.length; i++) {
        _otpControllers[i].text = otp[i];
      }
    } else {
      setState(() {
        _errorMessage = 'Failed to send OTP';
      });
    }
  }

  void _startTimer() {
    _timeRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String otp = _getOtpFromControllers();
    final success = await AuthService().verifyOtp(otp);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to success screen or home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const VerificationSuccessPage(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid OTP code';
      });
    }
  }

  String _getOtpFromControllers() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _handleOtpInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      // Move to next field
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
    }

    // Auto-submit when all fields are filled
    if (_getOtpFromControllers().length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _resendOtp() async {
    if (_timeRemaining > 0) return;

    await _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the verification code',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Sent to ${widget.phoneNumber}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // OTP Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _handleOtpInput(value, index),
                  ),
                );
              }),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 30),

            if (_timeRemaining > 0)
              Center(
                child: Text(
                  'Resend code in $_timeRemaining seconds',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

            if (_timeRemaining == 0 && _otpSent)
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Resend code'),
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Verify', style: TextStyle(fontSize: 16)),
              ),
            ),

            const Spacer(),

            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate back to phone number entry
                  Navigator.of(context).pop();
                },
                child: const Text('Change phone number'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple success page for demonstration
class VerificationSuccessPage extends StatelessWidget {
  const VerificationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 20),
            Text('Phone number verified successfully!'),
          ],
        ),
      ),
    );
  }
}
