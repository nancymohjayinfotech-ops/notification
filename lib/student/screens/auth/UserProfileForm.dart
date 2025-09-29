import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../services/token_service.dart';
import '../../services/auth_service.dart';
import '../categories/InterestBasedPage.dart';
import 'OtpVerificationPage.dart';

class UserProfileForm extends StatefulWidget {
  final String? authMethod; // 'otp' or 'google'
  final String? prefilledEmail; // For Google auth
  final String? prefilledPhone; // For OTP auth

  const UserProfileForm({
    super.key,
    this.authMethod,
    this.prefilledEmail,
    this.prefilledPhone,
  });

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  final _tokenService = TokenService();

  // Helper method to check if college is already set
  bool get _isCollegeSet {
    final isSet =
        _studentId != null &&
        _studentId!.isNotEmpty &&
        _collegeController.text.isNotEmpty;
    print(
      '_isCollegeSet: $isSet, _studentId: $_studentId, college: ${_collegeController.text}',
    ); // Debug log
    return isSet;
  }

  // Helper method to format date for display
  String _formatDateForDisplay(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      // If it's already in YYYY-MM-DD format, convert to DD/MM/YYYY for display
      if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to format date for API
  String _formatDateForAPI(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      // If it's in DD/MM/YYYY format, convert to YYYY-MM-DD for API
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to get subtitle text based on auth method
  String _getSubtitleText() {
    if (widget.authMethod == 'otp') {
      return 'Please provide your email address and college details to complete your profile';
    } else if (widget.authMethod == 'google') {
      return 'Please provide your phone number and college details to complete your profile';
    } else {
      return 'Please provide your college details to get your Student ID';
    }
  }

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _collegeController = TextEditingController();
  final _dobController = TextEditingController();
  final _otpController = TextEditingController();

  // Form state
  bool _isLoading = false;
  bool _isProfileLoaded = false;
  String? _errorMessage;
  String? _successMessage;
  File? _selectedImage;
  String? _currentAvatarUrl;
  String? _studentId;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();

    // Pre-fill fields based on authentication method
    if (widget.prefilledEmail != null) {
      _emailController.text = widget.prefilledEmail!;
    }
    if (widget.prefilledPhone != null) {
      _phoneController.text = widget.prefilledPhone!;
    }

    // If coming from Google auth, allow proceeding without JWT by using AuthService data
    if (widget.authMethod == 'google') {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;
        if (currentUser != null) {
          _nameController.text = currentUser.name ?? _nameController.text;
          _emailController.text = currentUser.email ?? _emailController.text;
          _phoneController.text =
              currentUser.phoneNumber ?? _phoneController.text;
          _currentAvatarUrl = currentUser.avatar;
          _userRole = currentUser.role.toString().split('.').last;
        }
      } catch (_) {}
      setState(() {
        _isProfileLoaded = true;
        _errorMessage = null;
      });
    } else {
      _loadUserProfileWithFallback();
    }
  }

  Future<void> _verifyPhoneForGoogle() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(phone.replaceAll(' ', ''))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 1) Try lightweight signup (idempotent UX): ignore errors, proceed to OTP
      try {
        final signupResp = await _apiClient.post(
          ApiConfig.signup,
          data: {'phoneNumber': phone, 'role': 'student'},
        );
        if (signupResp.isSuccess == true) {
          final msg =
              (signupResp.data as Map<String, dynamic>?)?['message'] as String?;
          if (msg != null && msg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.blueGrey),
            );
          }
        }
      } catch (_) {
        // Intentionally ignore signup errors; user might already exist
      }

      // 2) Send OTP (same as PhoneLoginPage)
      final response = await _apiClient.post(
        ApiConfig.sendOtp,
        data: {'phoneNumber': phone},
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final otp = responseData['data']?['otp']?.toString();
        if (otp != null && otp.length == 6) {
          _otpController.text = otp;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtpInline() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _apiClient.post(
        ApiConfig.verifyOtp,
        data: {'phoneNumber': phone, 'otp': otp},
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] ?? {};
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await _tokenService.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            phoneNumber: phone,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Phone verified successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserProfileWithFallback() async {
    print('🔄 Starting profile load with fallback...');

    try {
      // First try to load from API
      await _loadUserProfile();

      // If profile loading failed and fields are empty, try to get data from AuthService
      if (_nameController.text.isEmpty && _emailController.text.isEmpty) {
        print('📱 Profile API failed, trying AuthService fallback...');
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser != null) {
          print('✅ Fallback: Loading user data from AuthService');
          print(
            'User data: name=${currentUser.name}, email=${currentUser.email}',
          );
          setState(() {
            _nameController.text = currentUser.name ?? '';
            _emailController.text = currentUser.email ?? '';
            _phoneController.text = currentUser.phoneNumber ?? '';
            _currentAvatarUrl = currentUser.avatar;
            _userRole = currentUser.role.toString().split('.').last;
            _isProfileLoaded = true;
            _errorMessage = null; // Clear any previous errors
          });
        } else {
          print('❌ No current user found in AuthService');
          setState(() {
            _errorMessage =
                null; // Don't show error, just proceed with empty form
            _isProfileLoaded = true;
          });
        }
      } else {
        print('✅ Profile loaded successfully from API');
      }
    } catch (e) {
      print('❌ Error in _loadUserProfileWithFallback: $e');
      setState(() {
        _errorMessage = null; // Don't show error, just proceed with empty form
        _isProfileLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _collegeController.dispose();
    _dobController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!_tokenService.hasValidToken) {
      setState(() {
        _errorMessage = 'Please login to access your profile';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('Loading profile from: ${ApiConfig.profile}'); // Debug log
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.profile,
      );

      print('Profile API Response: ${response.data}'); // Debug log

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // Handle different response structures
        Map<String, dynamic>? userData;

        if (data['success'] == true && data['data'] != null) {
          // Phone login structure: {success: true, data: {user: {...}}}
          userData = data['data']['user'];
        } else if (data['user'] != null) {
          // Alternative structure: {user: {...}}
          userData = data['user'];
        } else if (data.containsKey('name') || data.containsKey('email')) {
          // Direct user data structure
          userData = data;
        }

        if (userData != null) {
          // Debug: Print user data to see what fields are available
          print('User data loaded: $userData');

          setState(() {
            _nameController.text = userData!['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _phoneController.text =
                userData['phoneNumber'] ?? userData['phone'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _stateController.text = userData['state'] ?? '';
            _cityController.text = userData['city'] ?? '';
            _collegeController.text = userData['college'] ?? '';
            _dobController.text = _formatDateForDisplay(userData['dob']);
            _currentAvatarUrl = userData['avatar'];
            _studentId = userData['studentId'];
            _userRole = userData['role'] ?? 'student';
            _isProfileLoaded = true;
          });
        } else {
          // No user data found - this might be a new Google user
          print('No user data found in API response, treating as new user');
          setState(() {
            _isProfileLoaded = true;
            // Leave fields empty for new user to fill
          });
        }
      } else {
        // API call failed - might be a new Google user or network issue
        print('Profile API failed: ${response.error?.message}');

        // For Google users, we can still proceed with empty form
        setState(() {
          _isProfileLoaded = true;
          // Show a message that this is a new profile
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Don't show error for new Google users, just proceed with empty form
      setState(() {
        _isProfileLoaded = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      // Prepare update data based on auth method
      final updateData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'address': _addressController.text.trim(),
      };

      // Add conditional fields based on auth method
      if (widget.authMethod == 'otp') {
        updateData['email'] = _emailController.text.trim();
      } else if (widget.authMethod == 'google') {
        updateData['phone'] = _phoneController.text.trim();
      } else {
        // Default case - include both
        updateData['email'] = _emailController.text.trim();
        updateData['phone'] = _phoneController.text.trim();
      }

      // Update profile
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiConfig.updateProfile,
        data: updateData,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true) {
          setState(() {
            _successMessage = 'Profile updated successfully!';
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to update profile';
          });
        }
      } else {
        setState(() {
          _errorMessage = response.error?.message ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setCollege() async {
    // Validate conditional fields first
    if (widget.authMethod == 'otp' && _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.authMethod == 'google' && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate required fields for set-college API
    if (_stateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your state'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your city'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_collegeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter college name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your date of birth'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final requestData = {
        'state': _stateController.text.trim(),
        'city': _cityController.text.trim(),
        'college': _collegeController.text.trim(),
        'dob': _formatDateForAPI(_dobController.text.trim()),
      };

      // Add conditional fields based on auth method
      if (widget.authMethod == 'otp') {
        requestData['email'] = _emailController.text.trim();
      } else if (widget.authMethod == 'google') {
        // Always include phone
        requestData['phone'] = _phoneController.text.trim();
        // Also include email from Google profile if available
        String emailToUse = _emailController.text.trim();
        if (emailToUse.isEmpty) {
          // try widget.prefilledEmail then AuthService
          if (widget.prefilledEmail != null &&
              widget.prefilledEmail!.isNotEmpty) {
            emailToUse = widget.prefilledEmail!;
          } else {
            try {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              emailToUse = authService.currentUser?.email ?? '';
            } catch (_) {}
          }
        }
        if (emailToUse.isNotEmpty) {
          requestData['email'] = emailToUse;
        }
      } else {
        // Default case - include both if available
        if (_emailController.text.trim().isNotEmpty) {
          requestData['email'] = _emailController.text.trim();
        }
        if (_phoneController.text.trim().isNotEmpty) {
          requestData['phone'] = _phoneController.text.trim();
        }
      }

      print('Set College API Request Data: $requestData'); // Debug log
      print('Set College API URL: ${ApiConfig.setCollege}'); // Debug log

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.setCollege,
        data: requestData,
      );

      print('Set College API Response: ${response.data}'); // Debug log

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true) {
          final studentId = data['studentId'];

          setState(() {
            _successMessage = 'College set successfully!';
            _studentId = studentId;
            print('Student ID set to: $_studentId'); // Debug log
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'College set successfully! Student ID: $studentId. Redirecting to dashboard...',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Redirect to dashboard after successful college setup
          print('Scheduling redirect to dashboard in 1 second...'); // Debug log
          Future.delayed(Duration(seconds: 1), () {
            print('Executing redirect to dashboard...'); // Debug log
            if (mounted) {
              try {
                // Try named route first
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/interestpage',
                  (route) => false, // Remove all previous routes
                );
                print('Named route navigation executed'); // Debug log
              } catch (e) {
                print(
                  'Named route failed, trying direct navigation: $e',
                ); // Debug log
                // Fallback to direct navigation
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => InterestBasedPage()),
                  (route) => false, // Remove all previous routes
                );
                print('Direct navigation executed'); // Debug log
              }
            } else {
              print('Widget not mounted, cannot navigate'); // Debug log
            }
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to set college';
          });
        }
      } else {
        print('Set College API Error: ${response.error?.message}'); // Debug log
        setState(() {
          _errorMessage = response.error?.message ?? 'Failed to set college';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error setting college: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Set College Information',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_isProfileLoaded && !_isCollegeSet)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadUserProfile,
              tooltip: 'Refresh profile',
            ),
        ],
      ),
      body: _isLoading && !_isProfileLoaded
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildProfileForm(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F299E)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Error loading profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5F299E),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 768;

        if (isWeb) {
          return _buildWebLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5F299E), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Avatar Section
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentAvatarUrl != null
                                  ? NetworkImage(_currentAvatarUrl!)
                                        as ImageProvider
                                  : null),
                        child:
                            _selectedImage == null && _currentAvatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF5F299E),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: Color(0xFF5F299E),
                            ),
                            onPressed: _pickImage,
                            tooltip: 'Change profile picture',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Set College Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getSubtitleText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Conditional Input Fields Section
            if (widget.authMethod == 'otp') ...<Widget>[
              _buildSectionHeader('Email Information', Icons.email),
              SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
            ] else if (widget.authMethod == 'google') ...<Widget>[
              _buildSectionHeader('Phone Information', Icons.phone),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(
                          r'^[+]?[0-9]{10,15}$',
                        ).hasMatch(value.trim().replaceAll(' ', ''))) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhoneForGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5F299E),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text('Verify'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _otpController,
                label: 'OTP',
                hint: 'Enter 6-digit OTP',
                icon: Icons.sms_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the OTP';
                  }
                  if (value.trim().length != 6) {
                    return 'OTP must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _verifyOtpInline,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF5F299E)),
                    foregroundColor: Color(0xFF5F299E),
                  ),
                  child: Text('Submit OTP'),
                ),
              ),
              SizedBox(height: 24),
            ],

            // College Information Section
            _buildSectionHeader('College Information', Icons.school),
            SizedBox(height: 16),

            // Show message if college is already set
            if (_isCollegeSet)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'College information is already set and cannot be modified',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isCollegeSet) SizedBox(height: 16),

            // State Field
            _buildTextField(
              controller: _stateController,
              label: 'State',
              hint: 'Enter your state',
              icon: Icons.location_city_outlined,
              readOnly: _isCollegeSet,
            ),
            SizedBox(height: 16),

            // City Field
            _buildTextField(
              controller: _cityController,
              label: 'City',
              hint: 'Enter your city',
              icon: Icons.location_city_outlined,
              readOnly: _isCollegeSet,
            ),
            SizedBox(height: 16),

            // College Field
            _buildTextField(
              controller: _collegeController,
              label: 'College/University',
              hint: 'Enter your college name',
              icon: Icons.school_outlined,
              readOnly: _isCollegeSet,
            ),
            SizedBox(height: 16),

            // Date of Birth Field
            _buildTextField(
              controller: _dobController,
              label: 'Date of Birth',
              hint: 'Enter your date of birth',
              icon: Icons.calendar_today_outlined,
              readOnly: _isCollegeSet,
              onTap: !_isCollegeSet
                  ? () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(
                          Duration(days: 6570),
                        ),
                        firstDate: DateTime.now().subtract(
                          Duration(days: 36500),
                        ),
                        lastDate: DateTime.now().subtract(Duration(days: 6570)),
                      );
                      if (date != null) {
                        _dobController.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }
                    }
                  : null,
            ),
            SizedBox(height: 24),

            // Set College Button
            if (!_isCollegeSet)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setCollege,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5F299E),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
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
                          'Set College & Get Student ID',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

            // Student ID Display
            if (_isCollegeSet)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge, color: Colors.green[600]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student ID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            _studentId!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left side - Full height banner
        Expanded(
          flex: 2,
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5F299E), Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentAvatarUrl != null
                                  ? NetworkImage(_currentAvatarUrl!)
                                        as ImageProvider
                                  : null),
                        child:
                            _selectedImage == null && _currentAvatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF5F299E),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: Color(0xFF5F299E),
                            ),
                            onPressed: _pickImage,
                            tooltip: 'Change profile picture',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Set College Information',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _getSubtitleText(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 32),
                if (_isCollegeSet)
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'College Set Successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Student ID: $_studentId',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Right side - Centered form
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Conditional Input Fields Section
                      if (widget.authMethod == 'otp') ...<Widget>[
                        _buildSectionHeader('Email Information', Icons.email),
                        SizedBox(height: 24),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32),
                      ] else if (widget.authMethod == 'google') ...<Widget>[
                        _buildSectionHeader('Phone Information', Icons.phone),
                        SizedBox(height: 24),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!RegExp(
                              r'^[+]?[0-9]{10,15}$',
                            ).hasMatch(value.trim().replaceAll(' ', ''))) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32),
                      ],

                      _buildSectionHeader('College Information', Icons.school),
                      SizedBox(height: 32),

                      // Show message if college is already set
                      if (_isCollegeSet)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'College information is already set and cannot be modified',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isCollegeSet) SizedBox(height: 24),

                      // Vertical layout for form fields - one below other
                      _buildTextField(
                        controller: _stateController,
                        label: 'State',
                        hint: 'Enter your state',
                        icon: Icons.location_city_outlined,
                        readOnly: _isCollegeSet,
                      ),
                      SizedBox(height: 20),

                      _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'Enter your city',
                        icon: Icons.location_city_outlined,
                        readOnly: _isCollegeSet,
                      ),
                      SizedBox(height: 20),

                      _buildTextField(
                        controller: _collegeController,
                        label: 'College/University',
                        hint: 'Enter your college name',
                        icon: Icons.school_outlined,
                        readOnly: _isCollegeSet,
                      ),
                      SizedBox(height: 20),

                      _buildTextField(
                        controller: _dobController,
                        label: 'Date of Birth',
                        hint: 'Enter your date of birth',
                        icon: Icons.calendar_today_outlined,
                        readOnly: _isCollegeSet,
                        onTap: !_isCollegeSet
                            ? () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().subtract(
                                    Duration(days: 6570),
                                  ),
                                  firstDate: DateTime.now().subtract(
                                    Duration(days: 36500),
                                  ),
                                  lastDate: DateTime.now().subtract(
                                    Duration(days: 6570),
                                  ),
                                );
                                if (date != null) {
                                  _dobController.text =
                                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                }
                              }
                            : null,
                      ),
                      SizedBox(height: 32),

                      // Set College Button
                      if (!_isCollegeSet)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _setCollege,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5F299E),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Set College & Get Student ID',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF5F299E), size: 24),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5F299E),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: readOnly && controller.text.isNotEmpty ? 'Already set' : hint,
        prefixIcon: Icon(
          icon,
          color: readOnly ? Colors.grey : Color(0xFF5F299E),
        ),
        suffixIcon: readOnly
            ? Icon(Icons.lock, color: Colors.grey, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF5F299E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}
