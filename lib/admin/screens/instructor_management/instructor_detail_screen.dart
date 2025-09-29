import 'package:flutter/material.dart';
import '../../models/instructor.dart';
import '../../services/api_service.dart';

class InstructorDetailScreen extends StatefulWidget {
  final Instructor instructor;

  const InstructorDetailScreen({super.key, required this.instructor});

  @override
  State<InstructorDetailScreen> createState() => _InstructorDetailScreenState();
}

class _InstructorDetailScreenState extends State<InstructorDetailScreen> {
  int selectedTabIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _instructorData;
  Map<String, dynamic>? _performance;
  Map<String, dynamic>? _personalInfo;
  List<dynamic> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadInstructorDetails();
  }

  Future<void> _loadInstructorDetails() async {
    try {
      final result = await ApiService.getInstructorById(widget.instructor.id);
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _instructorData = result['data']['instructor'];
          _performance = result['data']['performance'];
          _personalInfo = result['data']['personalInfo'];
          _courses = result['data']['courses'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(
          result['message'] ?? 'Failed to load instructor details',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading instructor details: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        title: Text(_instructorData?['name'] ?? widget.instructor.name),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildStatsCards(),
                  _buildTabSection(),
                  _buildTabContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final instructor = _instructorData ?? {};
    final name = instructor['name'] ?? widget.instructor.name;
    final email = instructor['email'] ?? '';
    final phoneNumber = instructor['phoneNumber'] ?? '';
    final isActive = instructor['isActive'] ?? false;
    final avatar = instructor['avatar'];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: avatar != null && avatar.toString().isNotEmpty
                ? NetworkImage(avatar.toString())
                : null,
            child: avatar == null || avatar.toString().isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'I',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email.isNotEmpty ? email : 'No email provided',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: Colors.white70, size: 20),
              const SizedBox(width: 4),
              Text(
                phoneNumber.isNotEmpty ? phoneNumber : 'No phone',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final performance = _performance ?? {};
    final totalStudents = performance['totalStudents']?.toString() ?? '0';
    final totalCourses = performance['totalCourses']?.toString() ?? '0';
    final totalVideos = performance['totalVideos']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(Icons.people, totalStudents, 'Students'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(Icons.play_circle, totalCourses, 'Courses'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(Icons.video_library, totalVideos, 'Videos'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f): const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9C27B0), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : Colors.grey,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Personal Info', 0)),
          Expanded(child: _buildTabButton('Courses', 1)),
          Expanded(child: _buildTabButton('Performance', 2)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C27B0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getTabContent(),
      ),
    );
  }

  Widget _getTabContent() {
    switch (selectedTabIndex) {
      case 0:
        return _buildPersonalInfo();
      case 1:
        return _buildCoursesTab();
      case 2:
        return _buildPerformanceTab();
      default:
        return _buildPersonalInfo();
    }
  }

  Widget _buildPersonalInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personalInfo = _personalInfo ?? {};
    final instructorData = _instructorData ?? {};

    final email = personalInfo['email'] ?? instructorData['email'] ?? '';
    final phoneNumber =
        personalInfo['phoneNumber'] ?? instructorData['phoneNumber'] ?? '';
    final bio = instructorData['bio'] ?? '';
    final skills = List<String>.from(
      personalInfo['skills'] ?? instructorData['skills'] ?? [],
    );
    final role = instructorData['role'] ?? 'instructor';
    final isActive = instructorData['isActive'] ?? false;
    final joinDate =
        personalInfo['joinDate'] ?? instructorData['createdAt'] ?? '';

    return Container(
      key: const ValueKey('personal_info'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.email,
              'Email',
              email.isNotEmpty ? email : 'Not provided',
            ),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              phoneNumber.isNotEmpty ? phoneNumber : 'Not provided',
            ),
            _buildInfoRow(Icons.work, 'Role', role.toUpperCase()),
            _buildInfoRow(
              Icons.verified,
              'Status',
              isActive ? 'Active' : 'Inactive',
            ),
            if (joinDate.isNotEmpty)
              _buildInfoRow(
                Icons.calendar_today,
                'Join Date',
                _formatDate(joinDate),
              ),
            const SizedBox(height: 16),
            Text(
              'Bio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bio.isNotEmpty ? bio : 'No bio provided',
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            skills.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF9C27B0,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                color: Color(0xFF9C27B0),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Text(
                    'No skills listed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.grey[700] : Colors.grey),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark? Colors.grey : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const ValueKey('courses'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Courses Taught',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _courses.isNotEmpty
                      ? Column(
                          children: _courses
                              .map((course) => _buildCourseItem(course))
                              .toList(),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses assigned yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This instructor hasn\'t been assigned to any courses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    final title = course['title'] ?? 'Untitled Course';
    final category = course['category'] ?? 'General';
    final enrolledCount = course['enrolledStudents']?.length ?? 0;
    final duration = course['duration'] ?? 0;
    final isActive = course['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$enrolledCount students',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${duration}h',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final performance = _performance ?? {};
    final instructorData = _instructorData ?? {};

    final totalStudents = performance['totalStudents']?.toString() ?? '0';
    final totalCourses = performance['totalCourses']?.toString() ?? '0';
    final totalVideos = performance['totalVideos']?.toString() ?? '0';
    final avgRating = performance['avgRating']?.toString() ?? '0.0';
    final quizzesCreated = performance['quizzesCreated']?.toString() ?? '0';
    final assessmentsCreated =
        performance['assessmentsCreated']?.toString() ?? '0';
    final liveSessions = performance['liveSessions']?.toString() ?? '0';

    return Container(
      key: const ValueKey('performance'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildPerformanceItem(
              'Total Students',
              totalStudents,
              Icons.people,
              Colors.blue,
            ),
            _buildPerformanceItem(
              'Total Courses',
              totalCourses,
              Icons.book,
              Colors.green,
            ),
            _buildPerformanceItem(
              'Total Videos',
              totalVideos,
              Icons.video_library,
              Colors.purple,
            ),
            _buildPerformanceItem(
              'Average Rating',
              avgRating,
              Icons.star,
              Colors.amber,
            ),
            _buildPerformanceItem(
              'Quizzes Created',
              quizzesCreated,
              Icons.quiz,
              Colors.orange,
            ),
            _buildPerformanceItem(
              'Assessments Created',
              assessmentsCreated,
              Icons.assignment,
              Colors.teal,
            ),
            _buildPerformanceItem(
              'Live Sessions',
              liveSessions,
              Icons.live_tv,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
