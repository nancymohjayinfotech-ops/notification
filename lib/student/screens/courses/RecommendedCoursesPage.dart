import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/favorites_service.dart';
import '../../utils/theme_helper.dart';
import 'CourseDetailsPage.dart';

class RecommendedCoursesPage extends StatefulWidget {
  const RecommendedCoursesPage({super.key});

  @override
  State<RecommendedCoursesPage> createState() => _RecommendedCoursesPageState();
}

class _RecommendedCoursesPageState extends State<RecommendedCoursesPage> {
  final CourseService _courseService = CourseService();
  final FavoritesService _favoritesService = FavoritesService();
  List<Course> _recommendedCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedCourses();
    _favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRecommendedCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _courseService.getRecommendedCourses();
      setState(() {
        _recommendedCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recommended courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Recommended for You'),
        backgroundColor: ThemeHelper.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ThemeHelper.getPrimaryColor(context),
              ),
            )
          : _recommendedCourses.isEmpty
              ? _buildEmptyState()
              : _buildCoursesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Recommended Courses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll recommend courses based on your interests',
            style: TextStyle(
              fontSize: 14,
              color: ThemeHelper.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRecommendedCourses,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.getPrimaryColor(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return RefreshIndicator(
      onRefresh: _loadRecommendedCourses,
      color: ThemeHelper.getPrimaryColor(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recommendedCourses.length,
        itemBuilder: (context, index) {
          final course = _recommendedCourses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.getShadowColor(context),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToCourseDetails(course),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: course.thumbnail != null
                      ? Image.network(
                          course.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.grey[600],
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Course Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Instructor
                    Text(
                      course.instructor?.name ?? course.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Rating and Price Row
                    Row(
                      children: [
                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: ThemeHelper.getTextColor(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${course.enrolledStudentsCount})',
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeHelper.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        
                        // Heart Icon
                        GestureDetector(
                          onTap: () => _toggleFavorite(course),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ThemeHelper.getBorderColor(context, opacity: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              course.id != null && _favoritesService.isFavorite(course.id!)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: course.id != null && _favoritesService.isFavorite(course.id!)
                                  ? Colors.red
                                  : ThemeHelper.getSecondaryTextColor(context),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeHelper.getPrimaryColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${course.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ThemeHelper.getPrimaryColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Category and Enrollment
                    Row(
                      children: [
                        if (course.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeHelper.getBorderColor(context, opacity: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              course.category?.name ?? 'General',
                              style: TextStyle(
                                fontSize: 10,
                                color: ThemeHelper.getSecondaryTextColor(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '${course.enrolledStudentsCount} students',
                          style: TextStyle(
                            fontSize: 10,
                            color: ThemeHelper.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Course course) async {
    if (course.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add course to favorites: missing course ID'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final success = await _favoritesService.toggleFavorite(course);

      if (success) {
        final isNowFavorite = _favoritesService.isFavorite(course.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowFavorite
                  ? '${course.title} added to favorites'
                  : '${course.title} removed from favorites',
                  style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              ),
            ),
            backgroundColor: isNowFavorite ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final error = _favoritesService.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to update favorites'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToCourseDetails(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsPage(
          slug: course.slug,
          courseId: course.id ?? '',
          courseTitle: course.title,
          courseAuthor: course.author,
          courseImage: course.imageAsset,
          progress: course.progress,
          progressText: course.progressText,
        ),
      ),
    );
  }
}
