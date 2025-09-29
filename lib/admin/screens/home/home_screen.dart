import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/navigation_service.dart';
import '../../core/constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final result = await ApiService.getDashboardStats();
      if (result['success'] == true) {
        setState(() {
          _dashboardData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final boxShadow = [
      BoxShadow(
        color: isDark ? Colors.black : Colors.grey,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.white : Colors.purple,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.red[200] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.black : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.purple[700] : null,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadDashboardStats();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final overview = _dashboardData?['overview'] ?? {};

    return Container(
      color: isDark ? Colors.black : Colors.white,
      child: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.purple.withOpacity(0.5)
                          : Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      AppStrings.welcomeBackAdmin,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.dashboardSubtitle,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                AppStrings.overview,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Users',
                      '${overview['totalUsers'] ?? 0}',
                      Icons.people,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      '${overview['totalStudents'] ?? 0}',
                      Icons.school,
                      const Color(0xFF2196F3),
                      onTap: () => _navigateToStudentManagement(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Instructors',
                      '${overview['totalInstructors'] ?? 0}',
                      Icons.person_outline,
                      const Color(0xFF9C27B0),
                      onTap: () => _navigateToInstructorManagement(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Courses',
                      '${overview['totalCourses'] ?? 0}',
                      Icons.book,
                      const Color(0xFF4CAF50),
                      onTap: () => _navigateToCourseManagement(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Events',
                      '${overview['totalEvents'] ?? 0}',
                      Icons.event,
                      const Color(0xFFFF9800),
                      onTap: () => _navigateToEventManagement(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Enrollments',
                      '${overview['totalEnrollments'] ?? 0}',
                      Icons.assignment,
                      const Color(0xFFF44336),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Revenue',
                      '₹${overview['totalRevenue'] ?? 0}',
                      Icons.attach_money,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Monthly Revenue',
                      '₹${overview['monthlyRevenue'] ?? 0}',
                      Icons.trending_up,
                      const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: boxShadow,
                ),
                child: _buildRecentActivityList(isDark: isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
              else
                Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );

    // Return clickable or non-clickable card based on onTap
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }

  Widget _buildRecentActivityList({bool isDark = false}) {
    final recentActivity = _dashboardData?['recentActivity'];
    if (recentActivity == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No recent activity',
          style: TextStyle(color: isDark ? Colors.black : Colors.white),
        ),
      );
    }

    final newUsers = recentActivity['newUsers'] as List<dynamic>? ?? [];
    final recentPayments =
        recentActivity['recentPayments'] as List<dynamic>? ?? [];

    if (newUsers.isEmpty && recentPayments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No recent activity',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // New Users
        ...newUsers.map((user) => _buildUserActivityItem(user)),
        // Add dividers between items if there are multiple
        if (newUsers.isNotEmpty && recentPayments.isNotEmpty)
          const Divider(height: 1),
        // Recent Payments (if any)
        ...recentPayments.map((payment) => _buildPaymentActivityItem(payment)),
      ],
    );
  }

  Widget _buildUserActivityItem(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'user';
    final createdAt = user['createdAt'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Format the date
    String timeAgo = _formatTimeAgo(createdAt);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar or Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRoleColor(role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
              color: Colors.grey,
              width: 1,
              ),
            ),
            child: user['avatar'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      user['avatar'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: _getRoleColor(role),
                        size: 20,
                      ),
                    ),
                  )
                : Icon(Icons.person, color: _getRoleColor(role), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New $role registered',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: _getRoleColor(role),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActivityItem(Map<String, dynamic> payment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment received',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Amount: \$${payment['amount'] ?? '0'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(payment['createdAt'] ?? ''),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF9C27B0);
      case 'instructor':
        return const Color(0xFF2196F3);
      case 'student':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatTimeAgo(String dateString) {
    if (dateString.isEmpty) return 'Unknown time';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  // Navigation methods
  void _navigateToStudentManagement() {
    print('HomeScreen: _navigateToStudentManagement called');
    NavigationService.navigateToIndex(NavigationService.userManagementIndex);
  }

  void _navigateToInstructorManagement() {
    print('HomeScreen: _navigateToInstructorManagement called');
    NavigationService.navigateToIndex(
      NavigationService.instructorManagementIndex,
    );
  }

  void _navigateToCourseManagement() {
    print('HomeScreen: _navigateToCourseManagement called');
    NavigationService.navigateToIndex(NavigationService.courseManagementIndex);
  }

  void _navigateToEventManagement() {
    print('HomeScreen: _navigateToEventManagement called');
    NavigationService.navigateToIndex(NavigationService.eventManagementIndex);
  }
}
