import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/cart_api_service.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String courseAuthor;
  final String courseImage;
  final double progress;
  final String progressText;
  final String? slug;
  final Course? course; // Add full course object
  final bool isEnrolled; // Add flag to indicate if user is enrolled

  const CourseDetailsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.courseAuthor,
    required this.courseImage,
    required this.progress,
    required this.progressText,
    this.slug,
    this.course, // Add course parameter
    this.isEnrolled = false, // Default to false
  });

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _testimonialController = PageController();
  int _currentTestimonialIndex = 0;
  bool _showCertificatePreview = false;

  Course? _courseDetails;
  bool _isLoading = false;
  String? _error;
  final CourseService _courseService = CourseService();

  // Review form controllers and state
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _courseDetails = widget.course;

    // Always load course details if slug is provided to get fresh data from API
    if (widget.slug != null) {
      _loadCourseDetails();
    } else if (_courseDetails == null) {
      _loadCourseDetails();
    }
  }

  Future<void> _loadCourseDetails() async {
    if (widget.slug == null && widget.courseId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Course? course;
      if (widget.slug != null) {
        course = await _courseService.getCourseBySlug(widget.slug!);
      } else {
        course = await _courseService.getCourseById(widget.courseId);
      }

      if (course != null) {
        setState(() {
          _courseDetails = course;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Course not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading course: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _testimonialController.dispose();
    _ratingController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with Consumer to listen to theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Stack(
          children: [
            Scaffold(
              backgroundColor: isDark ? Colors.black : Colors.grey[50],
              appBar: AppBar(
                backgroundColor: theme.primaryColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Course Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final isWeb = constraints.maxWidth >= 768;

                  // Show loading state
                  if (_isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.primaryColor),
                          SizedBox(height: 16),
                          Text('Loading course details...'),
                        ],
                      ),
                    );
                  }

                  // Show error state
                  if (_error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCourseDetails,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 36.0 : 16.0,
                        vertical: isWeb ? 20.0 : 0.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWeb) const SizedBox(height: 20),
                          _buildCourseHeader(),
                          _buildCourseInfo(),
                          _buildTabSection(),
                          _buildCourseFeatures(),
                          _buildInstructorSection(),
                          _buildReviewsSection(),
                          _buildCertificationPreviewSection(),
                          _buildCertificationSection(),
                          _buildContinueButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Certificate Preview Lightbox
            if (_showCertificatePreview)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCertificatePreview = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Full Certificate Design - Landscape
                        Container(
                          width: double.infinity,
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              // Header with logos
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Container(
                                        width: 12,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.yellow,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 90),
                                      const Text(
                                        'Mohjay Infotech',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Main content - Center Aligned for lightbox
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'DECLARATION OF',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1565C0),
                                        letterSpacing: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'COMPLETION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0),
                                        letterSpacing: 3.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 05),
                                    Text(
                                      'Your Name',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF1565C0),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10),
                                    Divider(thickness: 3, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text(
                                      'has successfully completed the online course',
                                      style: TextStyle(
                                        fontSize: 08,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 02),
                                    Text(
                                      'FLUTTER DEVELOPMENT',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0),
                                        letterSpacing: 2.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'This professional has demonstrated initiative and a commitment. Well done!',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
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
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                ),
              ),
              child:
                  _courseDetails?.thumbnail != null &&
                      _courseDetails!.thumbnail!.isNotEmpty
                  ? Image.network(
                      _courseDetails!.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF4A90E2),
                          child: const Icon(
                            Icons.school,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF4A90E2),
                      child: const Icon(
                        Icons.school,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _courseDetails?.title ?? widget.courseTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _courseDetails?.instructor?.name ?? widget.courseAuthor,
                      style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                    ),
                    if (_courseDetails?.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₹${_courseDetails!.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
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
              // Star rating display
              _buildStarRating(_courseDetails?.averageRating ?? 0.0),
              const SizedBox(width: 8),
              Text(
                '(${_courseDetails?.averageRating.toStringAsFixed(1) ?? '0.0'})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, color: Colors.grey[600], size: 20),
              const SizedBox(width: 4),
              Text(
                '${_courseDetails?.enrolledStudentsCount ?? _courseDetails?.enrolledStudents.length ?? 0} Learners',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _courseDetails?.description.isNotEmpty == true
                ? _courseDetails!.description
                : 'Master the fundamentals of ${widget.courseTitle.toLowerCase()} with hands-on projects and real-world applications. This comprehensive course covers everything from basic concepts to advanced techniques.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.textTheme.bodyLarge?.color?.withOpacity(
              0.6,
            ),
            indicatorColor: theme.primaryColor,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Curriculum'),
            ],
          ),
          SizedBox(
            height: 330,
            child: TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildCurriculumTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final course = _courseDetails;
    if (course == null) {
      return Center(child: Text('Course details not available'));
    }

    // Calculate dynamic values from course sections if API values are not available
    int totalDurationSeconds = course.totalDuration;
    int totalVideosCount = course.totalVideos;

    // If API doesn't provide these values, calculate from sections
    if (totalVideosCount == 0 && course.sections.isNotEmpty) {
      totalVideosCount = course.sections.fold(
        0,
        (sum, section) => sum + (section.videoCount ?? section.videos.length),
      );
    }

    // If still 0, provide a default based on sections
    if (totalVideosCount == 0 && course.sections.isNotEmpty) {
      totalVideosCount =
          course.sections.length * 3; // Estimate 3 videos per section
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Description
            if (course.description.isNotEmpty) ...[
              Text(
                'About This Course',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                course.description,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 20),
            ],

            // Course Stats
            Text(
              'Course Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // _buildOverviewItem(
            //   Icons.access_time,
            //   _formatDuration(totalDurationSeconds),
            //   'total course duration',
            // ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.video_library,
              '$totalVideosCount videos',
              'across ${course.sections.length} sections',
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.trending_up,
              course.level.toUpperCase(),
              'difficulty level',
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.people,
              '${course.enrolledStudentsCount > 0 ? course.enrolledStudentsCount : course.enrolledStudents.length} students',
              'currently enrolled',
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.star,
              '${course.averageRating.toStringAsFixed(1)} ⭐',
              'average rating',
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.category,
              course.category?.name ?? 'General',
              course.subcategory?.name ?? 'Course category',
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.card_membership,
              'Completion certificate',
              'awarded upon course completion',
            ),
            const SizedBox(height: 12),
            _buildOverviewItem(
              Icons.calendar_today,
              'Lifetime access',
              'learn at your own pace',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index < rating) {
          // Half star
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          // Empty star
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  Widget _buildOverviewItem(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurriculumTab() {
    final course = _courseDetails;
    if (course == null) {
      return Center(child: Text('Course curriculum not available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: course.sections.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Course curriculum will be available soon',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Content',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...course.sections.map(
                    (section) => _buildSectionItem(section),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionItem(CourseSection section) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          section.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.description != null) ...[
              const SizedBox(height: 4),
              Text(
                section.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${section.videoCount ?? section.videos.length} videos',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: section.videos.isNotEmpty
            ? section.videos
                  .map(
                    (video) => _buildCurriculumItem(
                      video.title,
                      _formatDuration(video.durationSeconds ?? 0),
                    ),
                  )
                  .toList()
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Video content will be available soon',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 min';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    }
    return '${remainingSeconds}s';
  }

  Widget _buildReviewsSection() {
    final course = _courseDetails ?? widget.course;
    if (course == null) return const SizedBox.shrink();

    // Show reviews section even if reviews are empty, but with different content

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use the average rating from API instead of calculating manually
    double avgRating = course.averageRating;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
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
              Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Reviews & Ratings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Summary
          Row(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avgRating.floor()
                            ? Icons.star
                            : index < avgRating
                            ? Icons.star_half
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.reviews.isNotEmpty
                        ? '${course.reviews.length} reviews'
                        : 'No reviews yet',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reviews Slider or No Reviews Message - Show existing reviews FIRST
          if (course.reviews.isNotEmpty) ...[
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _testimonialController,
                onPageChanged: (index) {
                  setState(() {
                    _currentTestimonialIndex = index;
                  });
                },
                itemCount: course.reviews.length,
                itemBuilder: (context, index) {
                  final review = course.reviews[index];
                  return _buildDynamicReviewCard(review);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Pagination dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                course.reviews.length,
                (index) => GestureDetector(
                  onTap: () {
                    _testimonialController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentTestimonialIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentTestimonialIndex == index
                          ? Colors.amber
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // No reviews placeholder
            Container(
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 32,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isEnrolled
                          ? 'Be the first to review this course!'
                          : 'Enroll to see and add reviews',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Add Review Section - Only for enrolled students (BELOW existing reviews)
          if (widget.isEnrolled) ...[
            const SizedBox(height: 20),
            _buildAddReviewSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicReviewCard(CourseReview review) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate user initials from user ID (since we don't have user name)
    String userInitials = review.user != null && review.user!.length >= 2
        ? review.user!.substring(review.user!.length - 2).toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  userInitials,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Review',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              review.review,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumItem(String title, String duration) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? theme.dividerColor.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline, color: theme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            duration,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseFeatures() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 768; // Web/Desktop breakpoint
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isWeb ? 3 : 2, // 3 columns on web, 2 on mobile
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isWeb ? 2.5 : 3, // Adjust aspect ratio for web
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildFeatureCard('918 Enroll', Icons.people, Colors.amber),
              _buildFeatureCard(
                '45 Video Record',
                Icons.video_library,
                Colors.green,
              ),
              _buildFeatureCard('12 Lessons', Icons.book, Colors.blue),
              _buildFeatureCard('120 Note File', Icons.note, Colors.orange),
              _buildFeatureCard('160 Quiz', Icons.quiz, Colors.purple),
              _buildFeatureCard(
                '76 Audio Record',
                Icons.audiotrack,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String text, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get instructor from course data or fallback to passed data
    final instructor =
        _courseDetails?.instructor ??
        widget.course?.instructor ??
        CourseInstructor(
          name: widget.courseAuthor ?? 'Unknown Instructor',
          bio: 'Course instructor',
        );

    // If no instructor data available, don't show the section
    if (instructor.name == null || instructor.name!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Instructor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildDynamicInstructorCard(instructor),
        ],
      ),
    );
  }

  Widget _buildDynamicInstructorCard(CourseInstructor instructor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Instructor Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            backgroundImage:
                instructor.avatar != null && instructor.avatar!.isNotEmpty
                ? NetworkImage('http://54.82.53.11:5001${instructor.avatar}')
                : null,
            onBackgroundImageError:
                instructor.avatar != null && instructor.avatar!.isNotEmpty
                ? (exception, stackTrace) {}
                : null,
            child: instructor.avatar == null || instructor.avatar!.isEmpty
                ? Icon(Icons.person, size: 30, color: Colors.blue[600])
                : null,
          ),
          const SizedBox(width: 16),
          // Instructor Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor.name ?? 'Unknown Instructor',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (instructor.email != null &&
                    instructor.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    instructor.email!,
                    style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                  ),
                ],
                if (instructor.bio != null && instructor.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    instructor.bio!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationPreviewSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 768;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: isWeb
          ? _buildWebCertificateLayout()
          : _buildMobileCertificateLayout(),
    );
  }

  Widget _buildWebCertificateLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Text content
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get a completion certificate',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Share your certificate with prospective employers and your professional network on LinkedIn.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCertificatePreview = true;
                    });
                  },
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  label: Text(
                    'Preview Certificate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width < 385
                          ? 14
                          : 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side: Certificate preview
        Expanded(flex: 1, child: _buildCertificatePreviewCard()),
      ],
    );
  }

  Widget _buildMobileCertificateLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Get a completion certificate',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Share your certificate with prospective employers and your professional network on LinkedIn.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCertificatePreviewCard(),
      ],
    );
  }

  Widget _buildCertificatePreviewCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Yellow accent shapes
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Yellow bottom accent bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Certificate Preview
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width <= 350 ? 320 : 280,
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width <= 350 ? 12 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with logos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mohjay Infotech',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width <= 350
                                      ? 12
                                      : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Main content - Center Aligned
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'DECLARATION OF',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width <= 350
                                    ? 10
                                    : 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1565C0),
                                letterSpacing: 2.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'COMPLETION',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width <= 350
                                    ? 20
                                    : 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Your Name',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width <= 350
                                    ? 16
                                    : 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1565C0),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            // Decorative divider replaced by gradient bar below in refined layout
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Preview button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCertificatePreview = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Preview button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCertificatePreview = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 768;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? theme.shadowColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Features & Videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (isWeb) ...[
            // Web: Single row with 4 cards
            Row(
              children: [
                Expanded(
                  child: _buildCertificationCard(
                    'Skills You Will Gain',
                    'Explore course skills',
                    Icons.card_membership,
                    Colors.amber,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                ),
                Expanded(
                  child: _buildCertificationCard(
                    'Video Lessons',
                    '45+ HD video tutorials',
                    Icons.play_circle_filled,
                    Colors.red,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                ),
                Expanded(
                  child: _buildCertificationCard(
                    'Downloadable Resources',
                    'PDFs, code files & more',
                    Icons.download,
                    Colors.green,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                ),
                Expanded(
                  child: _buildCertificationCard(
                    'Lifetime Access',
                    'Learn at your own pace',
                    Icons.all_inclusive,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mobile: Two rows with 2 cards each
            Row(
              children: [
                Expanded(
                  child: _buildCertificationCard(
                    'Skills You Will Gain',
                    'Explore course skills',
                    Icons.card_membership,
                    Colors.amber,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                ),
                Expanded(
                  child: _buildCertificationCard(
                    'Video Lessons',
                    '45+ HD video tutorials',
                    Icons.play_circle_filled,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCertificationCard(
                    'Downloadable Resources',
                    'PDFs, code files & more',
                    Icons.download,
                    Colors.green,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                ),
                Expanded(
                  child: _buildCertificationCard(
                    'Lifetime Access',
                    'Learn at your own pace',
                    Icons.all_inclusive,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.cardColor.withOpacity(0.1)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? theme.dividerColor.withOpacity(0.3)
              : color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 768;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<Map<String, String>> testimonials = [
      {
        'name': 'John Smith',
        'rating': '5.0',
        'comment':
            'Excellent course! Very well structured and easy to follow. Highly recommended for beginners.',
        'avatar': 'JS',
      },
      {
        'name': 'Emily Davis',
        'rating': '4.8',
        'comment':
            'Great content and practical examples. The instructor explains concepts very clearly.',
        'avatar': 'ED',
      },
      {
        'name': 'Michael Brown',
        'rating': '4.9',
        'comment':
            'This course helped me land my dream job. The projects were very helpful.',
        'avatar': 'MB',
      },
      {
        'name': 'Sarah Wilson',
        'rating': '4.7',
        'comment':
            'Amazing learning experience with hands-on projects and real-world examples.',
        'avatar': 'SW',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? theme.shadowColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Testimonials',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _testimonialController,
              physics: isWeb
                  ? const AlwaysScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentTestimonialIndex = index;
                });
              },
              itemCount: isWeb
                  ? (testimonials.length / 2).ceil()
                  : testimonials.length,
              itemBuilder: (context, pageIndex) {
                if (isWeb) {
                  // Web: Show 2 testimonials per slide
                  final startIndex = pageIndex * 2;
                  final endIndex = (startIndex + 2).clamp(
                    0,
                    testimonials.length,
                  );
                  final pageTestimonials = testimonials.sublist(
                    startIndex,
                    endIndex,
                  );

                  return Row(
                    children: pageTestimonials.asMap().entries.map((entry) {
                      final testimonialIndex = entry.key;
                      final testimonial = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                testimonialIndex < pageTestimonials.length - 1
                                ? 8
                                : 0,
                            left: testimonialIndex > 0 ? 8 : 0,
                          ),
                          child: _buildTestimonialCard(testimonial),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  // Mobile: Show 1 testimonial per slide (unchanged)
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildTestimonialCard(testimonials[pageIndex]),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              isWeb ? (testimonials.length / 2).ceil() : testimonials.length,
              (index) => GestureDetector(
                onTap: () {
                  _testimonialController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentTestimonialIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentTestimonialIndex == index
                        ? Colors.blue[600]
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, String> testimonial) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? theme.shadowColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
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
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  testimonial['avatar']!,
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width < 430 ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial['name']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          testimonial['rating']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            testimonial['comment']!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 768;
    final isSmallScreen = screenWidth < 430;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: isWeb ? _buildWebButtons() : _buildMobileButtons(),
    );
  }

  Widget _buildWebButtons() {
    // Hide buttons if user is already enrolled
    if (widget.isEnrolled) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: 400, // Fixed width for web
        child: Column(
          children: [
            // First Row - Buy Now and Add To Cart buttons
            Row(
              children: [
                // Buy Now Button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle buy now action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Purchasing ${widget.courseTitle}...',
                            ),
                            backgroundColor: Colors.green[600],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flash_on_rounded,
                            size: MediaQuery.of(context).size.width < 430
                                ? 18
                                : 20,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width < 430
                                ? 6
                                : 8,
                          ),
                          Text(
                            'BUY NOW',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 340
                                  ? 10
                                  : (MediaQuery.of(context).size.width < 385
                                        ? 11
                                        : 15),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                ),
                // Add To Cart Button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _handleAddToCart();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                        side: BorderSide(color: Colors.blue[600]!, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: MediaQuery.of(context).size.width < 430
                                ? 18
                                : 20,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width < 430
                                ? 6
                                : 8,
                          ),
                          Text(
                            'ADD TO CART',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 385
                                  ? 11
                                  : (MediaQuery.of(context).size.width < 430
                                        ? 13
                                        : 15),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Second Row - Ask Query button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showQueryDialog,
                icon: const Icon(Icons.help_outline, size: 18),
                label: Text(
                  'Ask Query About Course',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 385 ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileButtons() {
    // Hide buttons if user is already enrolled
    if (widget.isEnrolled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // First Row - Buy Now and Add To Cart buttons
        Row(
          children: [
            // Buy Now Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle buy now action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Purchasing ${widget.courseTitle}...'),
                        backgroundColor: Colors.green[600],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.blue.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon(Icons.flash_on_rounded, size: MediaQuery.of(context).size.width < 430 ? 18 : 20),
                      SizedBox(
                        width: MediaQuery.of(context).size.width < 430 ? 6 : 8,
                      ),
                      Text(
                        'BUY NOW',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 430
                              ? 13
                              : 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width < 430 ? 8 : 12),
            // Add To Cart Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleAddToCart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F299E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: const Color(0xFF5F299E).withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        size: MediaQuery.of(context).size.width < 430 ? 18 : 20,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width < 430 ? 6 : 8,
                      ),
                      Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 340
                              ? 10
                              : (MediaQuery.of(context).size.width < 385
                                    ? 11
                                    : 15),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row - Have a Query button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _showQueryDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF5F299E), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5F299E),
              elevation: 2,
              shadowColor: const Color(0xFF5F299E).withOpacity(0.15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.help_outline_rounded,
                  size: 22,
                  color: Color(0xFF5F299E),
                ),
                SizedBox(width: 10),
                Text(
                  'HAVE A QUERY?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Color(0xFF5F299E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddToCart() async {
    try {
      if (widget.courseId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Course ID not available'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Adding ${widget.courseTitle} to cart...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      final cartService = CartApiService();
      final success = await cartService.add(widget.courseId);

      ScaffoldMessenger.of(context).clearSnackBars();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.courseTitle} added to cart successfully!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Get the error message from CartApiService
        final errorMessage =
            cartService.error ?? 'Failed to add course to cart';

        // Check for specific error cases and provide user-friendly messages
        String userFriendlyMessage;
        Color backgroundColor;
        IconData iconData;

        if (errorMessage.toLowerCase().contains('already enrolled')) {
          userFriendlyMessage =
              'You are already enrolled in this course! Check your enrolled courses.';
          backgroundColor = Colors.orange[600]!;
          iconData = Icons.school_rounded;
        } else if (errorMessage.toLowerCase().contains(
              'already in your cart',
            ) ||
            errorMessage.toLowerCase().contains('already in cart') ||
            errorMessage.toLowerCase().contains('already added')) {
          userFriendlyMessage = errorMessage; // Use actual API response message
          backgroundColor = Colors.blue[600]!;
          iconData = Icons.shopping_cart_rounded;
        } else if (errorMessage.toLowerCase().contains('not found')) {
          userFriendlyMessage = 'Course not found. Please try again.';
          backgroundColor = Colors.red[600]!;
          iconData = Icons.error;
        } else if (errorMessage.toLowerCase().contains('unauthorized') ||
            errorMessage.toLowerCase().contains('login')) {
          userFriendlyMessage = 'Please login to add courses to cart.';
          backgroundColor = Colors.orange[600]!;
          iconData = Icons.login;
        } else {
          userFriendlyMessage =
              'Unable to add course to cart. Please try again.';
          backgroundColor = Colors.red[600]!;
          iconData = Icons.error;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(iconData, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(userFriendlyMessage)),
              ],
            ),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error adding course to cart: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showQueryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'HAVE A QUERY?',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 385 ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F299E),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help you with "${widget.courseTitle}"?',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Opening chat support...'),
                            backgroundColor: Colors.green[600],
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 385
                              ? 12
                              : 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 430 ? 8 : 12,
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Opening email support...'),
                            backgroundColor: Colors.blue[600],
                          ),
                        );
                      },
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 385
                              ? 12
                              : 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddReviewSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Your Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Input
          TextField(
            controller: _ratingController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Rating (1-5)',
              hintText: 'Enter rating from 1 to 5',
              prefixIcon: Icon(Icons.star, color: Colors.amber),
              labelStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[700] : Colors.white,
            ),
            style: TextStyle(color: isDark ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 12),

          // Review Text Input
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Your Review',
              hintText: 'Share your experience with this course...',
              prefixIcon: Icon(Icons.comment, color: theme.primaryColor),
              labelStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[700] : Colors.white,
            ),
            style: TextStyle(color: isDark ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingReview ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
              ),
              child: _isSubmittingReview
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Submitting...'),
                      ],
                    )
                  : Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    // Validate inputs
    final ratingText = _ratingController.text.trim();
    final reviewText = _reviewController.text.trim();

    if (ratingText.isEmpty || reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in both rating and review'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rating = double.tryParse(ratingText);
    if (rating == null || rating < 1 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating must be a number between 1 and 5'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      // Use the existing CourseService.addRating method
      final success = await _courseService.addRating(
        widget.courseId,
        rating.round(), // Convert to int as expected by the API
        review: reviewText,
      );

      if (success) {
        // Clear form
        _ratingController.clear();
        _reviewController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Review submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh course details to show new review
        _loadCourseDetails();
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }
}
