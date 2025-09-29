import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/user_model.dart';
import '../../core/api/api_client.dart';
import '../../core/services/event_auth_service.dart';
import '../../event_management/event_management_page.dart';
// import '../../reporting_analytics/reporting_analytics_page.dart';

class EventOrganizerProfilePage extends StatefulWidget {
  const EventOrganizerProfilePage({super.key});

  @override
  State<EventOrganizerProfilePage> createState() =>
      _EventOrganizerProfilePageState();
}

class _EventOrganizerProfilePageState extends State<EventOrganizerProfilePage> {
  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _imageUrl;
  String? _errorMessage;

  // Direct API services
  EventAuthService? _authService;

  // User data
  User? _user;

  // Form key for validation (reserved for future inline validations)
  // final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _addressController = TextEditingController();

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      _authService = EventAuthService(apiClient, prefs);
      await _loadUserProfile();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      if (_authService == null) {
        throw Exception('Auth service not initialized');
      }
      final user = await _authService!.getUserProfile();
      setState(() {
        _user = user;
        if (!_isEditing) {
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber;
          _bioController.text = user.bio;
          _addressController.text = user.address;
        }
        _imageUrl = user.avatar;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
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
    // _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_errorMessage != null)
                    _buildErrorWidget(isDark)
                  else
                    _buildProfileCard(context, isDark),
                  const SizedBox(height: 20),
                  _buildMenuOptions(context, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: GoogleFonts.poppins(
              color: Colors.red[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.grey[400] : Colors.grey[600], 
              fontSize: 14
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF6C63FF),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the collapse ratio
            final double collapseRatio =
                (200.0 - constraints.maxHeight) / (200.0 - kToolbarHeight);

            // Only show title when collapsed (scrolled)
            return AnimatedOpacity(
              opacity: collapseRatio > 0.5 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Profile',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: isDark 
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6C63FF), Color(0xFF4A3FDB)],
                    ),
              ),
            ),
            // Profile info
            if (_user != null) _buildProfileHeader(_user!, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        backgroundImage: _imageUrl != null
                            ? NetworkImage(_imageUrl!)
                            : (user.avatar != null
                                  ? NetworkImage(user.avatar!)
                                  : null),
                        child: (_imageUrl == null && user.avatar == null)
                            ? Icon(
                                Icons.person,
                                size: 45,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
                              width: 2
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Event Organizer',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isDark) {
    if (_user == null) return const SizedBox.shrink();
    final user = _user!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: const Color(0xFF6C63FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Profile Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2D3748),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (!_isEditing)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _nameController.text = user.name;
                      _phoneController.text = user.phoneNumber;
                      _bioController.text = user.bio;
                      _addressController.text = user.address;
                      // _collegeController.text = user.college ?? '';
                    });
                  },
                  icon: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isEditing) ...[
            _buildProfileField(
              Icons.person,
              'Name',
              user.name,
              _nameController,
              isDark: isDark,
            ),
            if (user.phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildProfileField(
                Icons.phone_outlined,
                'Phone',
                user.phoneNumber,
                _phoneController,
                isDark: isDark,
              ),
            ],
          ] else ...[
            _buildProfileField(
              Icons.person,
              'Name',
              user.name,
              _nameController,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              Icons.info_outline,
              'Bio',
              user.bio,
              _bioController,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              Icons.phone_outlined,
              'Phone',
              user.phoneNumber,
              _phoneController,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              Icons.location_on_outlined,
              'Address',
              user.address,
              _addressController,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 16),
          // _buildProfileField(Icons.school_outlined, 'College', user.college ?? '', _collegeController, isDark: isDark),
          if (_isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
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
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  Widget _buildProfileField(
    IconData icon,
    String label,
    String value,
    TextEditingController controller, {
    bool isReadOnly = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditing 
            ? (isDark ? Colors.grey[900] : Colors.grey[50])
            : (isDark ? Colors.grey[900] : Colors.grey[25]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? const Color(0xFF6C63FF).withOpacity(0.3)
              : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isEditing)
                  TextFormField(
                    controller: controller,
                    enabled: !isReadOnly,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isReadOnly
                          ? Colors.grey[500]
                          : (isDark ? Colors.white : const Color(0xFF2D3748)),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: _getHintText(label),
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                else
                  Text(
                    value.isEmpty ? 'Not provided' : value,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value.isEmpty
                          ? Colors.grey[400]
                          : (isDark ? Colors.white : const Color(0xFF2D3748)),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: label == 'Bio' ? 3 : 1,
                  ),
              ],
            ),
          ),
          if (!_isEditing)
            Icon(
              Icons.edit_outlined, 
              size: 18, 
              color: isDark ? Colors.grey[500] : Colors.grey[400]
            ),
        ],
      ),
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Name':
        return 'Enter your full name';
      case 'Bio':
        return 'Tell us about yourself';
      case 'Phone':
        return 'Enter your phone number';
      case 'Address':
        return 'Enter your address';
      default:
        return 'Enter $label';
    }
  }

  Widget _buildMenuOptions(BuildContext context, bool isDark) {
    final menuItems = [
      {
        'icon': Icons.event_note,
        'title': 'Event Management',
        'subtitle': 'Create, edit and manage your events',
        'color': Colors.blue,
        'onTap': () => _navigateToEventManagement(context),
      },
      // {
      //   'icon': Icons.notifications,
      //   'title': 'Add Notification',
      //   'subtitle': 'Create and manage notifications',
      //   'color': Colors.red,
      //   'onTap': () => _navigateToNotificationManagement(context),
      // },
      // {
      //   'icon': Icons.analytics,
      //   'title': 'Reporting & Analytics',
      //   'subtitle': 'View and export event reports',
      //   'color': Colors.purple,
      //   'onTap': () => _navigateToReportingAnalytics(context),
      // },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'subtitle': 'Sign out from your account',
        'color': Colors.red,
        'onTap': () => _showLogoutDialog(context, isDark),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizer Tools',
          style: GoogleFonts.poppins(
            fontSize: 18, 
            fontWeight: FontWeight.w600, 
            color: isDark ? Colors.white : const Color(0xFF2D3748)
          ),
        ),
        const SizedBox(height: 15),
        ...menuItems.map(
          (item) => _buildMenuItem(
            context,
            item['icon'] as IconData,
            item['title'] as String,
            item['subtitle'] as String,
            item['color'] as Color,
            item['onTap'] as VoidCallback,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios, 
                size: 16, 
                color: isDark ? Colors.grey[500] : Colors.grey[400]
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEventManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventManagementPage()),
    );
  }

  // void _navigateToNotificationManagement(BuildContext context) {}

  // void _navigateToReportingAnalytics(BuildContext context) {}

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;
      final Uint8List imageBytes = await image.readAsBytes();

      if (_authService == null) {
        throw Exception('Auth service not initialized');
      }

      final uploadedUrl = await _authService!.uploadProfileImageBytes(
        imageBytes,
        image.name,
      );

      // Persist avatar via profile update
      final updated = await _authService!.updateUserProfile(
        avatar: uploadedUrl,
      );

      setState(() {
        _imageUrl = uploadedUrl;
        _user = updated;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Legacy placeholders kept for potential platform-specific extensions
  // Future<void> _pickImageMobile() async {}

  // Future<void> _pickImageWeb() async {}

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_authService == null) {
        throw Exception('Auth service not initialized');
      }

      await _authService!.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Fetch the latest user profile from the API after update
      await _loadUserProfile();

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    if (_user != null) {
      _nameController.text = _user!.name;
      _phoneController.text = _user!.phoneNumber;
      _bioController.text = _user!.bio;
      _addressController.text = _user!.address;
    }

    setState(() {
      _isEditing = false;
    });
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
          content: Text(
            'Are you sure you want to logout? You will need to sign in again.',
            style: GoogleFonts.poppins(
              fontSize: 14, 
              color: isDark ? Colors.grey[400] : Colors.grey[600]
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Clear user profile data
      if (_authService != null) {
        await _authService!.logout();
      }

      // Clear ALL stored data including access tokens, refresh tokens, user data, and any cached session data
      final prefs = await SharedPreferences.getInstance();
      await prefs
          .clear(); // This ensures complete cleanup - no token reuse possible

      // Additional cleanup to ensure no authentication state remains
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
      await prefs.remove('phone_number'); // Clear any cached phone number
      await prefs.remove('user_role'); // Clear any cached role
      await prefs.remove('login_timestamp'); // Clear any login session data

      // Navigate to login screen and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false, // Remove all previous routes - forces fresh login
        );
      }
    } catch (e) {
      // Handle logout error
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
