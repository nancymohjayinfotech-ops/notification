import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'CourseDetailsPage.dart';
import '../../models/course.dart';
import 'package:fluttertest/student/services/course_service.dart';
import 'package:fluttertest/student/services/favorites_service.dart';
import 'package:fluttertest/student/services/categories_service.dart';
import 'package:fluttertest/student/services/cart_api_service.dart';

class AllCoursesPage extends StatefulWidget {
  final String selectedLanguage;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;

  const AllCoursesPage({
    super.key,
    required this.selectedLanguage,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
  });

  @override
  State<AllCoursesPage> createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  final CourseService _courseService = CourseService();

  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  // Filter variables
  double _minRating = 0.0;
  double _maxPrice = 10000.0; // Increased to show all courses initially

  // API course data
  List<Course> _allCourses = [];
  List<Course> get filteredCourses {
    final filtered = _allCourses.where((course) {
      // Search filter
      bool matchesSearch =
          _searchQuery.isEmpty ||
          course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (course.instructor?.name ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      // Rating filter
      bool matchesRating = (course.averageRating ?? 0.0) >= _minRating;

      // Price filter
      bool matchesPrice = course.price <= _maxPrice;

      bool passes = matchesSearch && matchesRating && matchesPrice;
      if (!passes) {
        print(
          'DEBUG: Course "${course.title}" filtered out - Search: $matchesSearch, Rating: $matchesRating (${course.averageRating} >= $_minRating), Price: $matchesPrice (${course.price} <= $_maxPrice)',
        );
      }
      return passes;
    }).toList();

    print(
      'DEBUG: Filtered ${filtered.length} courses from ${_allCourses.length} total courses',
    );
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<Course> courses;

      // Load courses based on filters
      if (widget.subcategoryId != null) {
        // Load courses by subcategory
        courses = await _courseService.getCoursesBySubcategory(
          widget.subcategoryId!,
        );
        print(
          'DEBUG: Loaded ${courses.length} courses for subcategory: ${widget.subcategoryName}',
        );
      } else if (widget.categoryId != null) {
        // Load courses by category ID
        courses = await _courseService.getCoursesByCategory(widget.categoryId!);
        print(
          'DEBUG: Loaded ${courses.length} courses for category: ${widget.categoryName}',
        );
      } else if (widget.categoryName != null) {
        // Load courses by category name - need to find category ID first
        final categoriesService = CategoriesService();
        final categories = await categoriesService.getAllCategories();
        final category = categories.firstWhere(
          (cat) => cat.name.toLowerCase() == widget.categoryName!.toLowerCase(),
          orElse: () =>
              throw Exception('Category not found: ${widget.categoryName}'),
        );
        courses = await _courseService.getCoursesByCategory(category.id!);
        print(
          'DEBUG: Loaded ${courses.length} courses for category: ${widget.categoryName}',
        );
      } else {
        // Load all courses
        courses = await _courseService.getAllCourses(published: true);
        print('DEBUG: Loaded ${courses.length} courses from API');
      }

      for (int i = 0; i < courses.length && i < 5; i++) {
        print(
          'DEBUG: Course $i: ${courses[i].title} - Price: ${courses[i].price} - Rating: ${courses[i].averageRating}',
        );
      }

      setState(() {
        _allCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // filteredCourses getter moved to class level above

  void _showFilterDialog([BuildContext? dialogContext]) {
    showDialog(
      context: dialogContext ?? context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 16,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(color: Colors.grey[700]!, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF6A4C93).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: Color(0xFF6A4C93),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Filter Courses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.color,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Rating Filter Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]?.withOpacity(0.3)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(color: Colors.grey[700]!, width: 1)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Minimum Rating',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6A4C93),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_minRating.toStringAsFixed(1)} ⭐',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Color(0xFF6A4C93),
                              inactiveTrackColor: Color(
                                0xFF6A4C93,
                              ).withOpacity(0.3),
                              thumbColor: Color(0xFF6A4C93),
                              overlayColor: Color(0xFF6A4C93).withOpacity(0.2),
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _minRating,
                              min: 0.0,
                              max: 5.0,
                              divisions: 10,
                              onChanged: (value) {
                                setDialogState(() {
                                  _minRating = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Price Filter Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]?.withOpacity(0.3)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(color: Colors.grey[700]!, width: 1)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                color: Color(0xFF6A4C93),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Maximum Price',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6A4C93),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '₹${_maxPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Color(0xFF6A4C93),
                              inactiveTrackColor: Color(
                                0xFF6A4C93,
                              ).withOpacity(0.3),
                              thumbColor: Color(0xFF6A4C93),
                              overlayColor: Color(0xFF6A4C93).withOpacity(0.2),
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _maxPrice,
                              min: 0.0,
                              max: 10000.0,
                              divisions: 100,
                              onChanged: (value) {
                                setDialogState(() {
                                  _maxPrice = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                _minRating = 0.0;
                                _maxPrice = 10000.0;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Color(0xFF6A4C93)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: Color(0xFF6A4C93),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: Color(0xFF6A4C93),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A4C93),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Apply Filters',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is being used as a standalone page (with filters) or as a tab
    final isStandalone =
        widget.categoryId != null || widget.subcategoryId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      children: [
        // Fixed Search Bar with White Background and Grey Border
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey!, // Grey border for the search bar itself
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: isDark ? Colors.black : Colors.white),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.grey),
                  onPressed: () => _showFilterDialog(context),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        // Course List with Scroll
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 16),

                  _isLoading
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6A4C93),
                              ),
                            ),
                          ),
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadCourses,
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredCourses.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: Text(
                              'No courses found',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : Column(
                          children: filteredCourses
                              .map(
                                (course) => Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: _buildCourseCard(
                                    context,
                                    course: course,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    // If standalone (with category/subcategory filters), wrap in Scaffold
    if (isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.subcategoryName ?? widget.categoryName ?? 'All Courses',
          ),
          backgroundColor: const Color(0xFF6A4C93),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: content,
      );
    }

    // Otherwise return just the content for tab usage
    return content;
  }

  Widget _buildCourseCard(BuildContext context, {required Course course}) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final buttonWidth = isWeb ? 200.0 : double.infinity;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.grey[700]!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isWeb
          ? GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailsPage(
                      courseId: course.id ?? '',
                      courseTitle: course.title,
                      courseAuthor:
                          course.instructor?.name ??
                          course.author ??
                          'Unknown Instructor',
                      courseImage:
                          course.thumbnail ??
                          course.imageAsset ??
                          'assets/images/developer.png',
                      progress: course.progress ?? 0.0,
                      progressText: course.progressText ?? '0% completed',
                      slug: course.slug,
                      course: course,
                    ),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  Container(
                    width: 160,
                    height: 120,
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image:
                            course.thumbnail != null &&
                                course.thumbnail!.isNotEmpty
                            ? NetworkImage(course.thumbnail!)
                            : AssetImage('assets/images/developer.png')
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Course Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.color,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            course.instructor?.name ?? 'Unknown Instructor',
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFF3CD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (course.averageRating ?? 0.0)
                                          .toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.star,
                                      color: Color(0xFFFFD700),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Color(0xFFF59E0B),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Color(0xFFD97706),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '90 days access',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Section
                  Container(
                    width: 240,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price and Favorite
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${course.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A4C93),
                              ),
                            ),
                            Consumer<FavoritesService>(
                              builder: (context, favoritesService, child) {
                                final isFavorite = favoritesService.isFavorite(
                                  course.id ?? '',
                                );
                                return GestureDetector(
                                  onTap: () async {
                                    try {
                                      await favoritesService.toggleFavorite(
                                        course,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isFavorite
                                                ? '${course.title} removed from favorites!'
                                                : '${course.title} added to favorites!',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          backgroundColor: Color(0xFF6A4C93),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error updating favorites: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Enroll Now Button
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: () => _handleEnrollment(context, course),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A4C93),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Enroll Now',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Add to Cart Button
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _handleAddToCart(
                                context: context,
                                courseId: course.id ?? '',
                                courseTitle: course.title,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5F299E),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : // Refined Mobile Layout
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: DecorationImage(
                        image:
                            course.thumbnail != null &&
                                course.thumbnail!.isNotEmpty
                            ? NetworkImage(course.thumbnail!)
                            : AssetImage('assets/images/developer.png')
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Content Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Favorite
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                course.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Consumer<FavoritesService>(
                              builder: (context, favoritesService, child) {
                                final isFavorite = favoritesService.isFavorite(
                                  course.id ?? '',
                                );
                                return GestureDetector(
                                  onTap: () async {
                                    try {
                                      await favoritesService.toggleFavorite(
                                        course,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isFavorite
                                                ? 'Removed from favorites!'
                                                : 'Added to favorites!',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: Color(0xFF6A4C93),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error updating favorites',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // Instructor
                        Text(
                          course.instructor?.name ?? 'Unknown Instructor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),

                        SizedBox(height: 12),

                        // Rating and Access Time
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (course.averageRating ?? 0.0)
                                        .toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.star,
                                    color: Color(0xFFFFD700),
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '90 days',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Price and Actions
                        Row(
                          children: [
                            Text(
                              '₹${course.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A4C93),
                              ),
                            ),
                            Spacer(),

                            // Add to Cart Button
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: TextButton(
                                onPressed: () async {
                                  await _handleAddToCart(
                                    context: context,
                                    courseId: course.id ?? '',
                                    courseTitle: course.title,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(
                                    0xFF5F299E,
                                  ).withOpacity(0.1),
                                  foregroundColor: Color(0xFF5F299E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: Color(0xFF5F299E),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_rounded, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Cart',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: 8),

                            // Enroll Now Button
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _handleEnrollment(context, course),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6A4C93),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Enroll',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }

  // Helper methods
  Future<void> _handleEnrollment(BuildContext context, Course course) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrolling in course...'),
          backgroundColor: Color(0xFF6A4C93),
        ),
      );

      final success = await _courseService.enrollInCourse(course.id ?? '');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully enrolled!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enroll'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _handleAddToCart({
  required BuildContext context,
  required String courseId,
  required String courseTitle,
}) async {
  try {
    if (courseId.isEmpty) {
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
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Adding $courseTitle to cart...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    final cartService = CartApiService();
    final success = await cartService.add(courseId);

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
                  '$courseTitle added to cart successfully!',
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
      final errorMessage = cartService.error ?? 'Failed to add course to cart';

      // Check for specific error cases and provide user-friendly messages
      String userFriendlyMessage;
      Color backgroundColor;
      IconData iconData;

      if (errorMessage.toLowerCase().contains('already enrolled')) {
        userFriendlyMessage =
            'You are already enrolled in this course! Check your enrolled courses.';
        backgroundColor = Colors.orange[600]!;
        iconData = Icons.school_rounded;
      } else if (errorMessage.toLowerCase().contains('already in your cart') ||
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
        userFriendlyMessage = 'Unable to add course to cart. Please try again.';
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
