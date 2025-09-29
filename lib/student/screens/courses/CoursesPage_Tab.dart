import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/courses/AllCoursesPage.dart';
import '../../services/course_service.dart';
import '../../models/course.dart';
import '../../utils/theme_helper.dart';
import '../../screens/courses/CourseDetailsPage.dart';

class CoursesPageTab extends StatefulWidget {
  const CoursesPageTab({super.key});

  @override
  State<CoursesPageTab> createState() => _CoursesPageTabState();
}

class _CoursesPageTabState extends State<CoursesPageTab> {
  final CourseService _courseService = CourseService();

  @override
  void initState() {
    super.initState();
    _courseService.addListener(_onCourseServiceChanged);
    _loadEnrolledCourses();
  }

  @override
  void dispose() {
    _courseService.removeListener(_onCourseServiceChanged);
    super.dispose();
  }

  void _onCourseServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadEnrolledCourses() async {
    await _courseService.getEnrolledCourses();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header for Enrolled Courses
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Enrolled Courses',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[800],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: _loadEnrolledCourses,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Content (loading / error / list)
              Expanded(child: _buildContent(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_courseService.isLoadingEnrolled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark ? Colors.white70 : const Color(0xFF5F299E),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your enrolled courses...',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_courseService.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _courseService.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEnrolledCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.grey[700]
                    : const Color(0xFF5F299E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_courseService.enrolledCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No enrolled courses yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning by enrolling in courses!, or go to dashboard to select course',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _courseService.enrolledCourses.length,
      itemBuilder: (context, index) {
        final course = _courseService.enrolledCourses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCourseCard(context, course: course, isDark: isDark),
        );
      },
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required Course course,
    required bool isDark,
  }) {
    final double progress = course.progress;
    final String progressText = course.progressText;
    final String buttonText = "Continue Course";

    return InkWell(
      onTap: () {
        // Navigation removed - no action when tapping the card
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
      highlightColor: Colors.blue.withOpacity(isDark ? 0.1 : 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: isDark ? Border.all(color: Colors.grey[700]!) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image and Title Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          course.thumbnail != null &&
                              course.thumbnail!.isNotEmpty
                          ? Image.network(
                              course.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[300],
                                  child: Icon(
                                    Icons.school,
                                    size: 30,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                              child: Icon(
                                Icons.school,
                                size: 30,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Course Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${course.author}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.blue[300] : Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (course.level.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF42320A)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFF59E0B).withOpacity(0.6)
                                    : const Color(0xFFF59E0B),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 14,
                                  color: isDark
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.level.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.purple[400]
                              : const Color(0xFF5F299E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Course Details
            if (course.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  course.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Continue/Start Course Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailsPage(
                          courseId: course.id ?? 'unknown',
                          courseTitle: course.title,
                          courseAuthor: course.author,
                          courseImage: course.imageAsset,
                          progress: progress,
                          progressText: progressText,
                          slug: course.slug,
                          course: course,
                          isEnrolled: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black : Colors.white,
                    foregroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF5F299E),
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey[500]!
                          : const Color(0xFF5F299E),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
}
