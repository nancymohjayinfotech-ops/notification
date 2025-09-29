import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/image_upload_service.dart';
import '../../../models/user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  User? _currentUser;
  File? _selectedImage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // First load cached user data
    _currentUser = authService.currentUser;

    // Then fetch fresh profile data from server
    try {
      await authService.loadCurrentUser();
      _currentUser = authService.currentUser;
    } catch (e) {
      debugPrint('Error loading fresh profile data: $e');
    }

    if (_currentUser != null) {
      setState(() {
        _nameController.text = _currentUser!.name;
        _emailController.text = _currentUser!.email;
        _phoneController.text = _currentUser!.phoneNumber ?? '';
        _bioController.text = _currentUser!.bio ?? '';
        _addressController.text = _currentUser!.address ?? '';
        _collegeController.text = _currentUser!.college ?? '';
        _avatarUrl = _currentUser!.avatar;
      });
    }
  }

  // Helper method to get the appropriate avatar image
  ImageProvider _getAvatarImage() {
    // Priority: Selected image > Current avatar > Default image
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      // Check if it's a base64 image
      if (_avatarUrl!.startsWith('data:image')) {
        try {
          final base64String = _avatarUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (e) {
          debugPrint('Error decoding base64 image: $e');
        }
      } else {
        // It's a network URL - add base URL if it's a relative path
        final completeUrl = _avatarUrl!.startsWith('http')
            ? _avatarUrl!
            : 'http://54.82.53.11:5001$_avatarUrl';
        return NetworkImage(completeUrl);
      }
    }

    // Default image
    return const AssetImage('assets/images/homescreen.png');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F299E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Image Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF5F299E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _getAvatarImage(),
                      ),
                      if (_isUploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _changeProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _isUploadingImage
                                  ? Colors.grey
                                  : const Color(0xFF5F299E),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Change Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      enabled: true,
                      isDark: isDark,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      isDark: isDark,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      enabled: false,
                      isDark: isDark,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      isDark: isDark,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _collegeController,
                      label: 'College',
                      icon: Icons.school_outlined,
                      enabled: false,
                      isDark: isDark,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      isDark: isDark,
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5F299E).withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isLoading ? null : _saveProfile,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    bool isDark = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.12)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled
                ? (isDark ? Colors.white70 : const Color(0xFF5F299E))
                : Colors.grey,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? const Color(0xFF5F299E) : Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled
              ? (isDark ? Colors.grey[850] : Colors.white)
              : (isDark ? Colors.grey[900] : Colors.grey[100]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  void _changeProfileImage() async {
    try {
      final imageUploadService = ImageUploadService();

      // Try direct gallery access first (bypass dialog for testing)
      final directImage = await imageUploadService.pickImageFromGallery();

      XFile? selectedXFile = directImage;

      // If direct access failed, try dialog (but dialog returns File, so skip for now)
      if (selectedXFile == null) {
        return;
      }

      setState(() {
        // For web, we can't use File(path) for display, so we'll handle it differently
        // _selectedImage = File(selectedXFile.path); // This causes errors on web
        _isUploadingImage = true;
      });

      final uploadedImageUrl = await imageUploadService
          .uploadProfileImageFromXFile(selectedXFile);

      if (uploadedImageUrl != null) {
        setState(() {
          _avatarUrl = uploadedImageUrl; // Store uploaded image URL
          _isUploadingImage = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture uploaded successfully!'),
              backgroundColor: const Color(0xFF5F299E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _selectedImage = null;
          _isUploadingImage = false;
        });

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _selectedImage = null;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);

        // Prepare profile data for update (phone number cannot be updated)
        final profileData = {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'address': _addressController.text.trim(),
        };

        // Include avatar if it was updated
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
          profileData['avatar'] = _avatarUrl!;
        }

        final success = await authService.updateProfile(profileData);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully!'),
                backgroundColor: const Color(0xFF5F299E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authService.errorMessage ?? 'Failed to update profile',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An error occurred. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
