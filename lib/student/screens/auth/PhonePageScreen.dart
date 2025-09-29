import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import 'LoginPageScreen.dart';
import 'package:flutter/services.dart';

class PhonePageScreeen extends StatefulWidget {
  final String selectedRole; // Added parameter

  const PhonePageScreeen({
    super.key,
    this.selectedRole = 'student', // Default fallback
  });

  @override
  State<PhonePageScreeen> createState() => _PhonePageScreeenState();
}

class _PhonePageScreeenState extends State<PhonePageScreeen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  void _sendOtp(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    try {
      // Show loading state
      setState(() {
        // You can add a loading state here if needed
      });

      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiConfig.signup,
        data: {
          'phoneNumber': phoneNumber,
          'role': widget.selectedRole.toLowerCase(),
        },
      );

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          // Show success message from API
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Registration successful! Please login to continue.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to LoginPageScreen after successful registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPageScreen(),
            ),
          );
        } else {
          // Show error message from API
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message for exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthService>(
            builder: (context, authService, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'Enter your phone number',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'We\'ll send you a verification code to confirm your number',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),

                    // Phone number input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: const Icon(Icons.phone),
                        // prefixText: '+1 ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF5F299E),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _sendOtp(authService),
                    ),
                    const SizedBox(height: 16),

                    // Error message
                    if (authService.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authService.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // // Role selector
                    // Text(
                    //   'Select your role',
                    //   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    // ),
                    // const SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _buildRoleChip('student', Icons.school),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Expanded(
                    //       child: _buildRoleChip(
                    //         'instructor',
                    //         Icons.person_outline,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Expanded(
                    //       child: _buildRoleChip(
                    //         'admin',
                    //         Icons.admin_panel_settings,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),

                    // Send OTP button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () => _sendOtp(authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F299E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Debug: Test Buttons
                    // Column(
                    //   children: [
                    //     Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //       children: [
                    //         TextButton(
                    //           onPressed: () {
                    //             Navigator.pushNamed(
                    //               context,
                    //               '/connectivity-test',
                    //             );
                    //           },
                    //           child: Text(
                    //             'Test Connection',
                    //             style: TextStyle(
                    //               fontSize: 10,
                    //               color: Colors.grey[600],
                    //               decoration: TextDecoration.underline,
                    //             ),
                    //           ),
                    //         ),
                    //         TextButton(
                    //           onPressed: () {
                    //             Navigator.pushNamed(
                    //               context,
                    //               '/courses-api-test',
                    //             );
                    //           },
                    //           child: Text(
                    //             'Test Courses',
                    //             style: TextStyle(
                    //               fontSize: 10,
                    //               color: Colors.grey[600],
                    //               decoration: TextDecoration.underline,
                    //             ),
                    //           ),
                    //         ),
                    //         TextButton(
                    //           onPressed: () {
                    //             Navigator.pushNamed(
                    //               context,
                    //               '/offers-api-test',
                    //             );
                    //           },
                    //           child: Text(
                    //             'Test Offers',
                    //             style: TextStyle(
                    //               fontSize: 10,
                    //               color: Colors.grey[600],
                    //               decoration: TextDecoration.underline,
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 8),

                    // Terms and privacy
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

