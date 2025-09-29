import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/course.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isLoading = true;
  Course? _course;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getCourseById(widget.courseId);
      
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _course = Course.fromJson(result['data']['course']);
          _stats = result['data']['stats'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load course details';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          if (_course != null)
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(action),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Course'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Course', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _course != null
                  ? _buildCourseDetails()
                  : const Center(child: Text('Course not found')),
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading course',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchCourseDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseDetails() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              _buildCourseHeader(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Stats Cards
              _buildStatsCards(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Course Information
              _buildCourseInfo(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Instructor Information
              _buildInstructorInfo(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Intro Video Information
              if (_course!.introVideo != null)
                _buildIntroVideoInfo(isMobile: isMobile),
              if (_course!.introVideo != null)
                SizedBox(height: isMobile ? 16 : 24),

              // Course Content
              _buildCourseContent(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Enrolled Students
              _buildEnrolledStudents(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Ratings and Reviews
              _buildRatingsAndReviews(isMobile: isMobile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCourseHeader({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 75 : 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_getFullImageUrl(_course!.thumbnail)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              
              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _course!.title,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _course!.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
                          decoration: BoxDecoration(
                            color: _getLevelColor(_course!.level).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _course!.level.toUpperCase(),
                            style: TextStyle(
                              color: _getLevelColor(_course!.level),
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
                          decoration: BoxDecoration(
                            color: _course!.published ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _course!.published ? 'PUBLISHED' : 'DRAFT',
                            style: TextStyle(
                              color: _course!.published ? Colors.green : Colors.red,
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_course!.isFeatured) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          _course!.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${_course!.enrolledStudents.length} students'),
                        const SizedBox(width: 16),
                        Text(
                          '₹${_course!.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCards({required bool isMobile}) {
    if (_stats == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        return Wrap(
          spacing: isMobile ? 8 : 16,
          runSpacing: isMobile ? 8 : 16,
          alignment: WrapAlignment.start,
          children: [
            _buildStatCard(
              'Enrolled Students',
              '${_stats!['enrolledStudents']}',
              Icons.people,
              const Color(0xFF2196F3),
              isMobile: isMobile,
            ),
            _buildStatCard(
              'Total Ratings',
              '${_stats!['totalRatings']}',
              Icons.star,
              const Color(0xFFFF9800),
              isMobile: isMobile,
            ),
            _buildStatCard(
              'Sections',
              '${_stats!['totalSections']}',
              Icons.library_books,
              const Color(0xFF9C27B0),
              isMobile: isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      width: isMobile ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Information',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Category', _course!.category.name, isMobile: isMobile),
          _buildInfoRow('Subcategory', _course!.subcategory.name, isMobile: isMobile),
          _buildInfoRow('Level', _course!.level.toUpperCase(), isMobile: isMobile),
          _buildInfoRow('Price', '₹${_course!.price.toStringAsFixed(0)}', isMobile: isMobile),
          _buildInfoRow('Created', DateFormat('MMM dd, yyyy').format(_course!.createdAt), isMobile: isMobile),
          _buildInfoRow('Last Updated', DateFormat('MMM dd, yyyy').format(_course!.updatedAt), isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorInfo({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructor',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isMobile ? 25 : 30,
                backgroundImage: _course!.instructor.avatar != null
                    ? NetworkImage(_getFullImageUrl(_course!.instructor.avatar!))
                    : null,
                child: _course!.instructor.avatar == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _course!.instructor.name,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _course!.instructor.email,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    if (_course!.instructor.bio != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _course!.instructor.bio!,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroVideoInfo({required bool isMobile}) {
    if (_course!.introVideo == null) return const SizedBox.shrink();
    
    final introVideo = _course!.introVideo!;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intro Video',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 80 : 100,
                height: isMobile ? 60 : 75,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      introVideo.title,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      introVideo.description,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${introVideo.durationSeconds} seconds',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent({required bool isMobile}) {
    if (_course!.sections.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No course content available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Content',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._course!.sections.map((section) => _buildSectionCard(section, isMobile: isMobile)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(CourseSection section, {required bool isMobile}) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: ExpansionTile(
        title: Text(
          section.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        subtitle: Text(
          '${section.videos.length} videos',
          style: TextStyle(
            color: Colors.grey,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        children: [
          if (section.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 6 : 8),
              child: Text(
                section.description,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ...section.videos.map((video) => _buildVideoItem(video, isMobile: isMobile)),
        ],
      ),
    );
  }

  Widget _buildVideoItem(CourseVideo video, {required bool isMobile}) {
    return ListTile(
      leading: const Icon(Icons.play_circle_outline, color: Colors.red),
      title: Text(
        video.title,
        style: TextStyle(
          fontSize: isMobile ? 12 : 14,
        ),
      ),
      subtitle: Text(
        video.formattedDuration,
        style: TextStyle(
          color: Colors.grey,
          fontSize: isMobile ? 10 : 12,
        ),
      ),
      onTap: () {
        // TODO: Handle video play
      },
    );
  }

  Widget _buildEnrolledStudents({required bool isMobile}) {
    if (_course!.enrolledStudents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrolled Students',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: isMobile ? 6 : 8,
            runSpacing: isMobile ? 6 : 8,
            children: _course!.enrolledStudents.map((student) => _buildStudentChip(student, isMobile: isMobile)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentChip(EnrolledStudent student, {required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: isMobile ? 10 : 12,
            backgroundImage: student.avatar.isNotEmpty
                ? NetworkImage(_getFullImageUrl(student.avatar))
                : null,
            child: student.avatar.isEmpty
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          SizedBox(width: isMobile ? 4 : 8),
          Text(
            student.name,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsAndReviews({required bool isMobile}) {
    if (_course!.ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratings & Reviews',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._course!.ratings.map((rating) => _buildRatingItem(rating, isMobile: isMobile)),
        ],
      ),
    );
  }

  Widget _buildRatingItem(Rating rating, {required bool isMobile}) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 14 : 16,
                  backgroundImage: rating.user.avatar.isNotEmpty
                      ? NetworkImage(_getFullImageUrl(rating.user.avatar))
                      : null,
                  child: rating.user.avatar.isEmpty
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating.rating ? Icons.star : Icons.star_border,
                              size: isMobile ? 14 : 16,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(rating.createdAt),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rating.review.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rating.review,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper function to get full URL
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // Already a full URL
    }
    return '${ApiService.baseUrl}$url'; // Add baseUrl for relative paths
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit course
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${_course!.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final res = await ApiService.deleteCourse(_course!.id);
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course deleted successfully'), backgroundColor: Colors.green),
                );
                Navigator.pop(context, true); // Return to previous screen
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message']?.toString() ?? 'Failed to delete course'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}