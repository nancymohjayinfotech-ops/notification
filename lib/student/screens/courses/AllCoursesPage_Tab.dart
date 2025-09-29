import 'package:flutter/material.dart';
import 'CourseDetailsPage.dart';
import '../../models/course.dart';
import '../../models/category.dart';
import '../../repositories/course_repository.dart';
import '../../services/favorites_service.dart';
import '../../services/categories_service.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class AllCoursesPageTab extends StatefulWidget {
  final String selectedLanguage;
  final String? initialSubcategoryId;
  final String? initialSubcategoryName;

  const AllCoursesPageTab({
    super.key,
    required this.selectedLanguage,
    this.initialSubcategoryId,
    this.initialSubcategoryName,
  });

  @override
  State<AllCoursesPageTab> createState() => _AllCoursesPageTabState();
}

class _AllCoursesPageTabState extends State<AllCoursesPageTab> {
  final FavoritesService _favoritesService = FavoritesService();
  final CourseRepository _courseRepository = CourseRepositoryImpl();
  final CategoriesService _categoriesService = CategoriesService();
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  double _minRating = 0.0;
  double _maxPrice = 200.0;
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedCategoryName;
  String? _selectedSubcategoryName;

  // All courses data
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Categories and subcategories data
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _initializeCourses();
    _applyIncomingFilterFromRoute();
    _applyIncomingFilterFromConstructor();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  Future<void> _initializeCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final courses = await _courseRepository.getAllCourses();

      setState(() {
        _allCourses = courses;
        _filteredCourses = List.from(_allCourses);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: ${e.toString()}';
        _isLoading = false;
        _allCourses = [];
        _filteredCourses = [];
      });
    }
  }

  Future<void> _applyIncomingFilterFromRoute() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final filterBy = args['filterBy'];
        if (filterBy == 'subcategory') {
          final String subcategoryId = args['subcategoryId'];
          final String? subcategoryName = args['subcategoryName'];
          setState(() {
            _isLoading = true;
            _selectedSubcategoryId = subcategoryId;
            _selectedSubcategoryName = subcategoryName;
          });
          try {
            final repo = _courseRepository;
            final courses = await repo.getCoursesBySubcategory(subcategoryId);
            setState(() {
              _allCourses = courses;
              _filteredCourses = List.from(_allCourses);
              _isLoading = false;
            });
          } catch (e) {
            setState(() {
              _errorMessage = 'Failed to load courses: $e';
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  Future<void> _applyIncomingFilterFromConstructor() async {
    if (widget.initialSubcategoryId != null) {
      setState(() {
        _isLoading = true;
        _selectedSubcategoryId = widget.initialSubcategoryId;
        _selectedSubcategoryName = widget.initialSubcategoryName;
      });
      try {
        final repo = _courseRepository;
        final courses = await repo.getCoursesBySubcategory(
          widget.initialSubcategoryId!,
        );
        setState(() {
          _allCourses = courses;
          _filteredCourses = List.from(_allCourses);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to load courses: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshCourses() async {
    await _initializeCourses();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    try {
      final subcategories = await _categoriesService.getSubcategories(
        categoryId,
      );
      setState(() {
        _subcategories = subcategories;
      });
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      setState(() {
        _subcategories = [];
      });
    }
  }

  bool _hasActiveFilters() {
    return _minRating > 0.0 ||
        _maxPrice < 200.0 ||
        _selectedCategoryId != null ||
        _selectedSubcategoryId != null;
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _filterCourses() {
    setState(() {
      _filteredCourses = _allCourses.where((course) {
        // Search filter
        bool matchesSearch =
            _searchQuery.isEmpty ||
            course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            course.author.toLowerCase().contains(_searchQuery.toLowerCase());

        // Rating filter
        bool matchesRating = (course.averageRating ?? 0.0) >= _minRating;

        // Price filter (course.price is already a double)
        bool matchesPrice = (course.price ?? double.infinity) <= _maxPrice;

        // Category filter
        bool matchesCategory =
            _selectedCategoryId == null ||
            course.category?.id == _selectedCategoryId;

        // Subcategory filter
        bool matchesSubcategory =
            _selectedSubcategoryId == null ||
            course.subcategory?.id == _selectedSubcategoryId;

        return matchesSearch &&
            matchesRating &&
            matchesPrice &&
            matchesCategory &&
            matchesSubcategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterCourses();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Courses'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Filter
                    Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
                    Slider(
                      value: _minRating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 50,
                      onChanged: (value) {
                        setDialogState(() {
                          _minRating = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Price Filter
                    Text('Maximum Price: \$${_maxPrice.toStringAsFixed(0)}'),
                    Slider(
                      value: _maxPrice,
                      min: 0.0,
                      max: 200.0,
                      divisions: 40,
                      onChanged: (value) {
                        setDialogState(() {
                          _maxPrice = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category Filter
                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          hint: const Text('All Categories'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ..._categories
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(category.name),
                                  ),
                                )
                                ,
                          ],
                          onChanged: (String? categoryId) async {
                            setDialogState(() {
                              _selectedCategoryId = categoryId;
                              _selectedCategoryName = categoryId != null
                                  ? _categories
                                        .firstWhere((c) => c.id == categoryId)
                                        .name
                                  : null;
                              // Reset subcategory when category changes
                              _selectedSubcategoryId = null;
                              _selectedSubcategoryName = null;
                            });

                            // Load subcategories for selected category
                            if (categoryId != null) {
                              await _loadSubcategories(categoryId);
                            } else {
                              setDialogState(() {
                                _subcategories = [];
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subcategory Filter (only show if category is selected)
                    if (_selectedCategoryId != null) ...[
                      const Text(
                        'Subcategory:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubcategoryId,
                            hint: const Text('All Subcategories'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Subcategories'),
                              ),
                              ..._subcategories
                                  .map(
                                    (subcategory) => DropdownMenuItem<String>(
                                      value: subcategory.id,
                                      child: Text(subcategory.name),
                                    ),
                                  )
                                  ,
                            ],
                            onChanged: (String? subcategoryId) {
                              setDialogState(() {
                                _selectedSubcategoryId = subcategoryId;
                                _selectedSubcategoryName = subcategoryId != null
                                    ? _subcategories
                                          .firstWhere(
                                            (s) => s.id == subcategoryId,
                                          )
                                          .name
                                    : null;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minRating = 0.0;
                      _maxPrice = 200.0;
                      _selectedCategoryId = null;
                      _selectedSubcategoryId = null;
                      _selectedCategoryName = null;
                      _selectedSubcategoryName = null;
                      _subcategories = [];
                    });
                    _filterCourses();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _filterCourses();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleEnrollment(Course course) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please login to enroll in courses'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (course.id == null || course.id!.isEmpty) {
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
              Text('Enrolling in ${course.title}...'),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      final courseService = CourseService();
      final success = await courseService.enrollInCourse(course.id!);

      ScaffoldMessenger.of(context).clearSnackBars();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Successfully enrolled in ${course.title}!'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to enroll in course. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
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
              Expanded(child: Text('Error enrolling in course: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F299E)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Responsive: show web layout for wide screens, mobile otherwise
    return RefreshIndicator(
      onRefresh: _refreshCourses,
      color: const Color(0xFF5F299E),
      child: _buildMobileLayout(),
    );
  }
  
  // Mobile Layout - Match home screen design
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with back button like home screen
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                const Expanded(
                  child: Text(
                    'All Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5F299E), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSubcategoryName != null
                      ? 'Courses · ${_selectedSubcategoryName!}'
                      : 'Explore All Courses',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your learning journey with our comprehensive course collection',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search and Filter Section
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _hasActiveFilters()
                      ? Colors.orange
                      : const Color(0xFF5F299E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _showFilterDialog,
                  icon: Icon(
                    _hasActiveFilters()
                        ? Icons.filter_list_off
                        : Icons.filter_list,
                    color: Colors.white,
                  ),
                  tooltip: _hasActiveFilters()
                      ? 'Clear filters'
                      : 'Filter courses',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Results count
          Text(
            '${_filteredCourses.length} courses found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic course list or empty state
          if (_filteredCourses.isEmpty)
            _buildEmptyState()
          else
            ..._filteredCourses.map(
              (course) => Column(
                children: [
                  _buildCourseCard(context, course: course),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Web Course Card - Horizontal Layout
  Widget _buildWebCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
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
                  course: course, // Pass the full course object
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Course Image - Left side (larger)
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(course.imageAsset),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Course Details - Center
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title - Larger and bold
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Course Description/Subtitle
                      Text(
                        'Build powerful ${course.title.toLowerCase()} skills with a comprehensive learning path.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Author and metadata
                      Row(
                        children: [
                          Text(
                            'By ${course.author}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• 1 other',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Updated date and course info
                      Row(
                        children: [
                          Text(
                            'Updated August 2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            course.duration,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '118 lectures',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'All Levels',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Rating and badge
                      Row(
                        children: [
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${course.averageRating ?? 0.0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                                const Icon(
                                  Icons.star_half,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '(106)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          // Highest Rated badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4B5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Highest Rated',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and Action - Right side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Favorite button - Top right
                    IconButton(
                      icon: Icon(
                        course.id != null &&
                                _favoritesService.isFavorite(course.id!)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            course.id != null &&
                                _favoritesService.isFavorite(course.id!)
                            ? Colors.red
                            : Colors.grey[400],
                        size: 24,
                      ),
                      onPressed: () => _toggleFavorite(course),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(height: 20),

                    // Start Course button and Price row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/addtocart',
                              arguments: {
                                'courseTitle': course.title,
                                'courseAuthor': course.author,
                                'courseImage': course.imageAsset,
                                'coursePrice': '\$${course.price.toStringAsFixed(0)}',
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F299E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Start Course',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Price - Large and prominent
                        Text(
                          '\$${course.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Course Card - Vertical Layout
  Widget _buildMobileCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Image
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: AssetImage(course.imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Course Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Title
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Author
                Text(
                  'By ${course.author}',
                  style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                ),
                const SizedBox(height: 8),

                // Rating and Price
                Row(
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${course.averageRating ?? 0.0}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700),
                            size: 12,
                          ),
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700),
                            size: 12,
                          ),
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700),
                            size: 12,
                          ),
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700),
                            size: 12,
                          ),
                          const Icon(
                            Icons.star_half,
                            color: Color(0xFFFFD700),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price
                    Text(
                      '\$${course.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F299E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Enroll Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _handleEnrollment(course);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shadowColor: Colors.green.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.school_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ENROLL NOW',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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
    );
  }

  // Empty State Widget
  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF5F299E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 64,
                color: const Color(0xFF5F299E).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Main message
            Text(
              'No Courses Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle message
            Text(
              _hasActiveFilters() 
                  ? 'No courses match your current filters.\nTry adjusting your search criteria.'
                  : 'You haven\'t enrolled in any courses yet.\nStart your learning journey by exploring our course catalog!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            if (_hasActiveFilters()) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _minRating = 0.0;
                    _maxPrice = 200.0;
                    _selectedCategoryId = null;
                    _selectedSubcategoryId = null;
                    _selectedCategoryName = null;
                    _selectedSubcategoryName = null;
                    _subcategories = [];
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _filterCourses();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F299E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _refreshCourses,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Courses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F299E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, {required Course course}) {
    return InkWell(
      onTap: () {
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
              course: course, // Pass the full course object
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.blue.withOpacity(0.1),
      highlightColor: Colors.blue.withOpacity(0.05),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        course.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.school,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                          );
                        },
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Rating and Price Row
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (course.averageRating ?? 0.0).toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '\$${course.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F299E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFEF3C7,
                            ), // Light yellow background
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B), // Yellow border
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFFD97706), // Amber color
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.duration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD97706), // Amber color
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Heart Icon for Favorites
                  IconButton(
                    icon: Icon(
                      course.id != null &&
                              _favoritesService.isFavorite(course.id!)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          course.id != null &&
                              _favoritesService.isFavorite(course.id!)
                          ? Colors.red
                          : Colors.grey[400],
                      size: 24,
                    ),
                    onPressed: () => _toggleFavorite(course),
                    tooltip:
                        course.id != null &&
                            _favoritesService.isFavorite(course.id!)
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                ],
              ),
            ),

            // Enroll Now Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleEnrollment(course);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shadowColor: Colors.green.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.school_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ENROLL NOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
