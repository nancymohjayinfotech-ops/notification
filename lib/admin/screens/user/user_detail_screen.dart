import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(user['name'] ?? 'Student Details'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Card
            _buildProfileCard(context),
            const SizedBox(height: 20),

            // Personal Information
            _buildPersonalInfo(context),
            const SizedBox(height: 20),

            // Academic Information
            _buildAcademicInfo(context),
            const SizedBox(height: 20),

            // Account Information
            _buildAccountInfo(context),
            const SizedBox(height: 20),

            // Preferences
            _buildPreferences(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f): const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF9C27B0),
            child: Text(
              _getInitials(user['name'] ?? 'Student'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user['name'] ?? 'Unknown Student',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Student ID
          if (user['studentId'] != null &&
              user['studentId'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID: ${user['studentId']}',
                style: const TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (user['isActive'] == true ? Colors.green : Colors.red)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user['isActive'] == true ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                color: user['isActive'] == true ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {
    return _buildInfoCard('Personal Information', [
      if (user['email'] != null && user['email'].toString().isNotEmpty)
        _buildInfoRow(context, 'Email', user['email'], Icons.email),
      if (user['phoneNumber'] != null &&
          user['phoneNumber'].toString().isNotEmpty)
        _buildInfoRow(context, 'Phone', user['phoneNumber'], Icons.phone),
      if (user['dob'] != null && user['dob'].toString().isNotEmpty)
        _buildInfoRow(context, 'Date of Birth', user['dob'], Icons.cake),
      if (user['bio'] != null && user['bio'].toString().isNotEmpty)
        _buildInfoRow(context, 'Bio', user['bio'], Icons.person),
      if (user['address'] != null && user['address'].toString().isNotEmpty)
        _buildInfoRow(context, 'Address', user['address'], Icons.location_on),
    ], context);
  }

  Widget _buildAcademicInfo(BuildContext context) {
    return _buildInfoCard('Academic Information', [
      if (user['college'] != null && user['college'].toString().isNotEmpty)
        _buildInfoRow(context, 'College', user['college'], Icons.school),
      if (user['state'] != null && user['state'].toString().isNotEmpty)
        _buildInfoRow(context, 'State', user['state'], Icons.location_city),
      if (user['city'] != null && user['city'].toString().isNotEmpty)
        _buildInfoRow(context, 'City', user['city'], Icons.location_on),
      _buildInfoRow(
        context,
        'Enrolled Courses',
        '${user['enrolledCourses']?.length ?? 0}',
        Icons.book,
      ),
      _buildInfoRow(
        context,
        'Favorite Courses',
        '${user['favoriteCourses']?.length ?? 0}',
        Icons.favorite,
      ),
      _buildInfoRow(
        context,
        'Cart Items',
        '${user['cart']?.length ?? 0}',
        Icons.shopping_cart,
      ),
    ], context);
  }

  Widget _buildAccountInfo(BuildContext context) {
    return _buildInfoCard('Account Information', [
      _buildInfoRow(
        context,
        'Role',
        user['role'] ?? 'student',
        Icons.person_outline,
      ),
      _buildInfoRow(
        context,
        'Created At',
        _formatDate(user['createdAt']),
        Icons.calendar_today,
      ),
      _buildInfoRow(
        context,
        'Last Updated',
        _formatDate(user['updatedAt']),
        Icons.update,
      ),
      _buildInfoRow(
        context,
        'Interests Set',
        user['isInterestsSet'] == true ? 'Yes' : 'No',
        Icons.interests,
      ),
      if (user['refreshTokenExpiry'] != null)
        _buildInfoRow(
          context,
          'Token Expires',
          _formatDate(user['refreshTokenExpiry']),
          Icons.timer,
        ),
    ], context);
  }

  Widget _buildPreferences(BuildContext context) {
    final prefs =
        user['notificationPreferences'] as Map<String, dynamic>? ?? {};
    return _buildInfoCard('Notification Preferences', [
      _buildInfoRow(
        context,
        'Session Notifications',
        prefs['session'] == true ? 'Enabled' : 'Disabled',
        Icons.notifications,
      ),
      _buildInfoRow(
        context,
        'Messages',
        prefs['messages'] == true ? 'Enabled' : 'Disabled',
        Icons.message,
      ),
      _buildInfoRow(
        context,
        'Feedback',
        prefs['feedBack'] == true ? 'Enabled' : 'Disabled',
        Icons.feedback,
      ),
      _buildInfoRow(
        context,
        'New Enrollments',
        prefs['newEnrollments'] == true ? 'Enabled' : 'Disabled',
        Icons.school,
      ),
      _buildInfoRow(
        context,
        'Reviews',
        prefs['reviews'] == true ? 'Enabled' : 'Disabled',
        Icons.rate_review,
      ),
    ], context);
  }

  Widget _buildInfoCard(
    String title,
    List<Widget> children,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use a custom card color for dark mode for better contrast
    final cardColor = isDark ? const Color(0xFF23232B) : Colors.white;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.black87 : Colors.white);
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ) ??
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.black87 : Colors.white);
    final secondaryTextColor =
        theme.textTheme.bodyMedium?.color ??
        (isDark ? const Color(0xFFF6F4FB) : const Color(0xFF2e2d2f));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: secondaryTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ) ??
                      TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ) ??
                      TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    for (int i = 0; i < names.length && i < 2; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials.isEmpty ? 'S' : initials;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
