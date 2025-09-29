import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertest/student/widgets/BoldText.dart';
import 'package:fluttertest/instructor/services/auth_service.dart'
    as instructor_auth;
import 'package:fluttertest/instructor/pages/instructor_dashboard.dart';
import 'package:fluttertest/event/main_event.dart' as event_app;
import 'package:fluttertest/event/src/core/api/api_client.dart' as event_api;
import 'package:fluttertest/student/screens/auth/PhoneLoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormCommonPageScreen extends StatefulWidget {
  final String? authMethod; // 'otp' or 'google'
  final String? prefilledEmail; // For Google auth
  final String? prefilledPhone; // For OTP auth
  final String
  userRole; // 'instructor' or 'event_organizer' - passed dynamically

  const FormCommonPageScreen({
    super.key,
    this.authMethod,
    this.prefilledEmail,
    this.prefilledPhone,
    required this.userRole, // Must be provided dynamically
  });

  @override
  State<FormCommonPageScreen> createState() => _FormCommonPageScreenState();
}

class _FormCommonPageScreenState extends State<FormCommonPageScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final skillsController = TextEditingController();
  final specializationsController = TextEditingController();

  List<String> skillsList = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Pre-fill fields based on authentication method
    if (widget.prefilledEmail != null) {
      emailController.text = widget.prefilledEmail!;
    }
    if (widget.prefilledPhone != null) {
      phoneController.text = widget.prefilledPhone!;
    }

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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    dobController.dispose();
    addressController.dispose();
    stateController.dispose();
    cityController.dispose();
    skillsController.dispose();
    specializationsController.dispose();
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
      resizeToAvoidBottomInset:
          true, // This ensures the screen resizes when keyboard appears
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: BoldText(
          font: 'YourFontFamily',
          text: 'Profile Information',
          size: 18,
          color: const Color(0xFF2D3748),
        ),
        centerTitle: true,
      ),
      body: _buildResponsiveLayout(
        context,
        screenWidth,
        screenHeight,
        isSmallPhone,
        isVerySmallPhone,
        isMobile,
        isTablet,
        isDesktop,
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
      // Desktop and Tablet Layout
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
            width: screenWidth * (isDesktop ? 0.6 : 0.8),
            height: screenHeight * (isDesktop ? 0.85 : 0.9),
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : 500,
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
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 60 : 40,
                vertical: isDesktop ? 40 : 30,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildForm(context, isDesktop: isDesktop),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile Layout - Now Scrollable
      return Container(
        height: screenHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: isVerySmallPhone ? 10 : (isSmallPhone ? 15 : 20),
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 0,
            right: 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight - MediaQuery.of(context).viewInsets.bottom - 100,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Top decorative shape - COMMENTED OUT
                  // SizedBox(
                  //   height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
                  //   child: Stack(
                  //     children: [
                  //       Image.asset(
                  //         "assets/images/shape7.png",
                  //         width: double.infinity,
                  //         height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
                  //         fit: BoxFit.cover,
                  //         errorBuilder: (context, error, stackTrace) {
                  //           return Container(
                  //             width: double.infinity,
                  //             height: isVerySmallPhone ? 100 : (isSmallPhone ? 120 : 180),
                  //             decoration: const BoxDecoration(
                  //               gradient: LinearGradient(
                  //                 begin: Alignment.topLeft,
                  //                 end: Alignment.bottomRight,
                  //                 colors: [Color(0xFF7C3AED), Color(0xFF5F299E)],
                  //               ),
                  //             ),
                  //           );
                  //         },
                  //       ),
                  //       Container(
                  //         decoration: BoxDecoration(
                  //           gradient: LinearGradient(
                  //             begin: Alignment.topCenter,
                  //             end: Alignment.bottomCenter,
                  //             colors: [
                  //               Colors.transparent,
                  //               Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // Main form content
                  Flexible(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildForm(
                            context,
                            isSmallPhone: isSmallPhone,
                            isVerySmallPhone: isVerySmallPhone,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom decorative shape - COMMENTED OUT
                  // SizedBox(
                  //   height: isVerySmallPhone ? 60 : (isSmallPhone ? 80 : 120),
                  //   child: Image.asset(
                  //     "assets/images/shape6.png",
                  //     width: double.infinity,
                  //     fit: BoxFit.cover,
                  //     errorBuilder: (context, error, stackTrace) {
                  //       return Container(
                  //         width: double.infinity,
                  //         height: isVerySmallPhone ? 60 : (isSmallPhone ? 80 : 120),
                  //         decoration: const BoxDecoration(
                  //           gradient: LinearGradient(
                  //             begin: Alignment.topLeft,
                  //             end: Alignment.bottomRight,
                  //             colors: [Color(0xFF5F299E), Color(0xFF7C3AED)],
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildForm(
    BuildContext context, {
    bool isDesktop = false,
    bool isSmallPhone = false,
    bool isVerySmallPhone = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isVerySmallPhone ? 12 : (isSmallPhone ? 16 : 24),
      ),
      padding: EdgeInsets.all(isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 28)),
      constraints: const BoxConstraints(maxWidth: 400),
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
                  BoldText(
                    font: 'YourFontFamily',
                    text: 'Complete Your Profile',
                    size: isVerySmallPhone
                        ? 20
                        : (isSmallPhone ? 22 : (isDesktop ? 24 : 26)),
                    color:
                        Theme.of(context).textTheme.titleLarge?.color ??
                        const Color(0xFF2D3748),
                  ),
                  SizedBox(
                    height: isVerySmallPhone ? 3 : (isSmallPhone ? 4 : 6),
                  ),
                  Text(
                    _getSubtitleText(),
                    style: TextStyle(
                      fontSize: isVerySmallPhone
                          ? 12
                          : (isSmallPhone ? 13 : (isDesktop ? 14 : 15)),
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

            // Name field
            _buildEnhancedTextField(
              controller: nameController,
              label: "Full Name",
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // Conditional field based on auth method
            if (widget.authMethod == 'otp') ...[
              // For OTP login: ask for email (phone already provided)
              _buildEnhancedTextField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isSmallPhone: isSmallPhone,
                isVerySmallPhone: isVerySmallPhone,
                isDesktop: isDesktop,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ] else if (widget.authMethod == 'google') ...[
              // For Google auth: ask for phone (email already provided)
              _buildEnhancedTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isSmallPhone: isSmallPhone,
                isVerySmallPhone: isVerySmallPhone,
                isDesktop: isDesktop,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(
                    r'^[\+]?[1-9][\d]{0,15}$',
                  ).hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ] else ...[
              // Default: show both fields
              _buildEnhancedTextField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isSmallPhone: isSmallPhone,
                isVerySmallPhone: isVerySmallPhone,
                isDesktop: isDesktop,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),
              _buildEnhancedTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isSmallPhone: isSmallPhone,
                isVerySmallPhone: isVerySmallPhone,
                isDesktop: isDesktop,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(
                    r'^[\+]?[1-9][\d]{0,15}$',
                  ).hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // Bio field
            _buildEnhancedTextField(
              controller: bioController,
              label: "Bio (Optional)",
              icon: Icons.description_outlined,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // Date of Birth field
            _buildDateField(
              dobController,
              "Date of Birth",
              Icons.calendar_today_outlined,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your date of birth';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // Address field
            _buildEnhancedTextField(
              controller: addressController,
              label: "Address",
              icon: Icons.location_on_outlined,
              keyboardType: TextInputType.streetAddress,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // State field
            _buildEnhancedTextField(
              controller: stateController,
              label: "State",
              icon: Icons.map_outlined,
              keyboardType: TextInputType.text,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your state';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // City field
            _buildEnhancedTextField(
              controller: cityController,
              label: "City",
              icon: Icons.location_city_outlined,
              keyboardType: TextInputType.text,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // Skills field
            _buildSkillsField(
              controller: skillsController,
              label: "Skills (comma separated)",
              icon: Icons.star_outline,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter at least one skill';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 8 : (isSmallPhone ? 12 : 16)),

            // Specializations field
            _buildEnhancedTextField(
              controller: specializationsController,
              label: "Specializations",
              icon: Icons.school_outlined,
              keyboardType: TextInputType.text,
              isSmallPhone: isSmallPhone,
              isVerySmallPhone: isVerySmallPhone,
              isDesktop: isDesktop,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your specializations';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmallPhone ? 16 : (isSmallPhone ? 20 : 24)),

            // Submit button
            Container(
              height: isVerySmallPhone
                  ? 35
                  : (isSmallPhone ? 38 : (isDesktop ? 40 : 42)),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF5F299E), Color(0xFF7C3AED)],
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
                  onTap: _isLoading ? null : () => _handleSubmit(context),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : BoldText(
                            font: "YourFontFamily",
                            text: "Submit",
                            size: isVerySmallPhone
                                ? 15
                                : (isSmallPhone ? 16 : (isDesktop ? 16 : 18)),
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isSmallPhone = false,
    bool isVerySmallPhone = false,
    bool isDesktop = false,
    String? Function(String?)? validator,
  }) {
    final height = maxLines > 1
        ? null
        : isVerySmallPhone
        ? 35.0
        : (isSmallPhone ? 38.0 : (isDesktop ? 40.0 : 42.0));
    final iconSize = isVerySmallPhone
        ? 30.0
        : (isSmallPhone ? 32.0 : (isDesktop ? 35.0 : 38.0));
    final fontSize = isVerySmallPhone
        ? 13.0
        : (isSmallPhone ? 14.0 : (isDesktop ? 14.0 : 16.0));
    final iconSizeIcon = isVerySmallPhone
        ? 18.0
        : (isSmallPhone ? 20.0 : (isDesktop ? 20.0 : 22.0));
    final padding = isVerySmallPhone
        ? 12.0
        : (isSmallPhone ? 14.0 : (isDesktop ? 16.0 : 16.0));

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: iconSize,
            height: maxLines > 1 ? iconSize : height,
            decoration: BoxDecoration(
              color: const Color(0xFF5F299E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                bottomLeft: const Radius.circular(12),
                topRight: maxLines > 1
                    ? const Radius.circular(12)
                    : Radius.zero,
                bottomRight: maxLines > 1 ? Radius.zero : Radius.zero,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5F299E),
              size: iconSizeIcon,
            ),
          ),
          // Text field
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: validator,
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
                  vertical: maxLines > 1 ? padding : padding,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitleText() {
    switch (widget.authMethod) {
      case 'otp':
        return 'Please provide your email address to complete your profile';
      case 'google':
        return 'Please provide your phone number to complete your profile';
      default:
        return 'Please complete your profile information';
    }
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isSmallPhone = false,
    bool isVerySmallPhone = false,
    bool isDesktop = false,
    String? Function(String?)? validator,
  }) {
    final height = isVerySmallPhone
        ? 35.0
        : (isSmallPhone ? 38.0 : (isDesktop ? 40.0 : 42.0));
    final iconSize = isVerySmallPhone
        ? 30.0
        : (isSmallPhone ? 32.0 : (isDesktop ? 35.0 : 38.0));
    final fontSize = isVerySmallPhone
        ? 13.0
        : (isSmallPhone ? 14.0 : (isDesktop ? 14.0 : 16.0));
    final iconSizeIcon = isVerySmallPhone
        ? 18.0
        : (isSmallPhone ? 20.0 : (isDesktop ? 20.0 : 22.0));
    final padding = isVerySmallPhone
        ? 12.0
        : (isSmallPhone ? 14.0 : (isDesktop ? 16.0 : 16.0));

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
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
          // Text field
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  controller.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                }
              },
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

  Widget _buildSkillsField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isSmallPhone = false,
    bool isVerySmallPhone = false,
    bool isDesktop = false,
    String? Function(String?)? validator,
  }) {
    final height = isVerySmallPhone
        ? 45.0
        : (isSmallPhone ? 50.0 : (isDesktop ? 52.0 : 56.0));
    final iconSize = isVerySmallPhone
        ? 40.0
        : (isSmallPhone ? 45.0 : (isDesktop ? 50.0 : 50.0));
    final fontSize = isVerySmallPhone
        ? 13.0
        : (isSmallPhone ? 14.0 : (isDesktop ? 14.0 : 16.0));
    final iconSizeIcon = isVerySmallPhone
        ? 18.0
        : (isSmallPhone ? 20.0 : (isDesktop ? 20.0 : 22.0));
    final padding = isVerySmallPhone
        ? 12.0
        : (isSmallPhone ? 14.0 : (isDesktop ? 16.0 : 16.0));

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
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
          // Text field
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
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

  Future<void> _handleSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Parse skills from comma-separated string
        skillsList = skillsController.text
            .trim()
            .split(',')
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList();

        // Prepare the data based on authentication method
        final Map<String, dynamic> profileData = {
          'name': nameController.text.trim(),
          'bio': bioController.text.trim(),
          'dob': dobController.text.trim(),
          'address': addressController.text.trim(),
          'state': stateController.text.trim(),
          'city': cityController.text.trim(),
          'skills': skillsList,
          'specializations': specializationsController.text.trim(),
        };

        // Add email or phone based on auth method
        if (widget.authMethod == 'otp') {
          profileData['email'] = emailController.text.trim();
          profileData['phoneNumber'] = widget.prefilledPhone ?? '';
        } else if (widget.authMethod == 'google') {
          profileData['phoneNumber'] = phoneController.text.trim();
          profileData['email'] = widget.prefilledEmail ?? '';
        } else {
          // Default: include both
          profileData['email'] = emailController.text.trim();
          profileData['phoneNumber'] = phoneController.text.trim();
        }

        // Add role to profile data
        profileData['role'] = widget.userRole;

        // Make API call based on user role
        http.Response response;

        if (widget.userRole == 'instructor') {
          // Use instructor auth service for instructors
          final accessToken =
              await instructor_auth.InstructorAuthService.getValidAccessToken();

          if (accessToken == null || accessToken.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please login first to complete your profile"),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            return;
          }

          response =
              await instructor_auth.InstructorAuthService.authenticatedRequest(
                method: 'PATCH',
                url: 'http://54.82.53.11:5001/api/user/profile/role',
                body: jsonEncode(profileData),
              );
        } else if (widget.userRole == 'event_organizer') {
          // Use event API client for event organizers
          final prefs = await SharedPreferences.getInstance();
          final eventApiClient = event_api.ApiClient(prefs);

          final accessToken = await eventApiClient.getAccessToken();

          if (accessToken == null || accessToken.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please login first to complete your profile"),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            return;
          }

          response = await eventApiClient.patch(
            '/user/profile/role',
            body: jsonEncode(profileData),
          );
        } else {
          // For students, navigate to OTP verification instead of making API call
          // This is for Google Sign-In flow where we need phone verification
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PhoneLoginPage()),
          );
          return;
        }

        // Parse response
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          throw Exception('Invalid response format');
        }

        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            responseData['success'] == true) {
          // Success - show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile information submitted successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate to appropriate dashboard based on user role
          if (widget.userRole == 'instructor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    InstructorDashboard(instructorName: 'Instructor'),
              ),
            );
          } else if (widget.userRole == 'event_organizer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => event_app.MainPage(
                  organizerName: 'Event Organizer',
                  initialVerificationStatus:
                      false, // New profile, not verified yet
                ),
              ),
            );
          }
        } else {
          // API returned error
          final errorMessage =
              responseData['message'] ?? 'Failed to submit profile information';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        // Handle network or other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
