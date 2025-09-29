import 'package:flutter/material.dart';
import 'package:fluttertest/student/models/category.dart';
import 'package:fluttertest/student/models/course.dart';
import 'package:fluttertest/student/models/offer.dart';
import 'package:fluttertest/student/models/dashboard_stats.dart';
import 'package:fluttertest/student/screens/categories/CategoriesPage.dart';
import 'package:fluttertest/student/screens/categories/SubCategories/SubcategoryPage.dart';
import 'package:fluttertest/student/screens/courses/CourseDetailsPage.dart';
import 'package:fluttertest/student/screens/courses/PopularCoursesPage.dart';
import 'package:fluttertest/student/screens/courses/RecommendedCoursesPage.dart';
import 'package:fluttertest/student/screens/courses/AllCoursesPage.dart';
import 'package:fluttertest/student/services/categories_service.dart';
import 'package:fluttertest/student/services/course_service.dart';
import 'package:fluttertest/student/services/offers_service.dart';
import 'package:fluttertest/student/services/favorites_service.dart';
import '../meetings/student_meetings.dart';
import 'package:fluttertest/student/utils/theme_helper.dart';
import 'package:provider/provider.dart';
import 'OfferPage.dart';
import 'FeaturedCoursesPage.dart';
import '../../widgets/event_slider.dart';
import '../event/student_event.dart';

class HomePageTab extends StatefulWidget {
  final String selectedLanguage;

  const HomePageTab({super.key, required this.selectedLanguage});

  @override
  State<HomePageTab> createState() => _HomePageTabState();
}

class _HomePageTabState extends State<HomePageTab>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Page controller for offers
  late PageController _offersPageController;
  int _currentOfferIndex = 0;

  // Page controller for categories
  late PageController _categoriesPageController;
  final int _currentCategoryIndex = 0;

  // Progress slider controller (added during merge)
  late PageController _progressPageController;
  final int _currentProgressIndex = 0;

  // Categories data
  final CategoriesService _categoriesService = CategoriesService();
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;

  // Course data
  final CourseService _courseService = CourseService();
  final FavoritesService _favoritesService = FavoritesService();
  List<Course> _featuredCourses = [];
  List<Course> _popularCourses = [];
  List<Course> _recommendedCourses = [];
  List<Course> _enrolledCourses = [];
  bool _featuredCoursesLoading = true;
  bool _popularCoursesLoading = true;
  bool _recommendedCoursesLoading = true;
  bool _isLoadingEnrolled = false;

  // Dashboard stats data
  DashboardStats? _dashboardStats;
  bool _dashboardStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize page controllers
    _offersPageController = PageController();
    _categoriesPageController = PageController();
    _progressPageController = PageController();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    // Load categories, offers, and courses
    _loadCategories();
    _loadOffers();
    _loadFeaturedCourses();
    _loadPopularCourses();
    _loadRecommendedCourses();
    _loadEnrolledCourses();
    _loadDashboardStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _offersPageController.dispose();
    _categoriesPageController.dispose();
    _progressPageController.dispose();
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
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

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories; // Show all categories in scrollable view
          _categoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesLoading = false;
        });
      }
    }
  }

  // Meetings Card
  Widget _buildMeetingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF5F299E).withOpacity(0.9),
            const Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F299E).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with icon and content
          Row(
            children: [
              // Icon section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meetings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join virtual meetings with instructors',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Button section below
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentMeetingsPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Go to Meetings',
                    style: TextStyle(
                      color: const Color(0xFF5F299E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: const Color(0xFF5F299E),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFeaturedCourses() async {
    try {
      final courses = await _courseService.getFeaturedCourses(limit: 6);
      if (mounted) {
        setState(() {
          _featuredCourses = courses;
          _featuredCoursesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _featuredCoursesLoading = false;
        });
      }
    }
  }

  Future<void> _loadPopularCourses() async {
    setState(() {
      _popularCoursesLoading = true;
    });

    try {
      final courses = await _courseService.getPopularCourses();
      setState(() {
        _popularCourses = courses.take(6).toList();
        _popularCoursesLoading = false;
      });
    } catch (e) {
      setState(() {
        _popularCoursesLoading = false;
      });
      debugPrint('Error loading popular courses: $e');
    }
  }

  Future<void> _loadRecommendedCourses() async {
    setState(() {
      _recommendedCoursesLoading = true;
    });

    try {
      final courses = await _courseService.getRecommendedCourses();
      setState(() {
        _recommendedCourses = courses.take(6).toList();
        _recommendedCoursesLoading = false;
      });
    } catch (e) {
      setState(() {
        _recommendedCoursesLoading = false;
      });
      debugPrint('Error loading recommended courses: $e');
    }
  }

  void _loadOffers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OffersService>().fetchOffers();
      }
    });
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _courseService.getDashboardStats();
      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _dashboardStatsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardStatsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF1A1A1A), Colors.black, const Color(0xFF1A1A1A)]
              : [Colors.grey[50]!, Colors.white, Colors.grey[50]!],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Welcome Header with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildWelcomeHeader(),
                ),
              ),
              const SizedBox(height: 20),

              // Meetings Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMeetingsCard(),
                ),
              ),
              const SizedBox(height: 20),
              // Special Offers Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSectionHeader(
                  'Special Offers',
                  'View All',
                  Icons.local_offer_rounded,
                ),
              ),
              const SizedBox(height: 12),

              // Special Offers Horizontal List
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildSpecialOffersSection(),
                ),
              ),
              const SizedBox(height: 20),

              // Categories Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSectionHeader(
                  'All Category',
                  'View All',
                  Icons.category_rounded,
                ),
              ),
              const SizedBox(height: 12),

              // Categories Grid
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildCategoriesSection(),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats Cards with Scale Animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildQuickStatsSection(),
                ),
              ),
              const SizedBox(height: 20),

              // Featured Course Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSectionHeader(
                  'Featured Course',
                  'View All',
                  Icons.star_rounded,
                ),
              ),
              const SizedBox(height: 12),

              // Enhanced Featured Course Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildFeaturedCourseCard(),
                ),
              ),
              const SizedBox(height: 24),

              // Popular Courses Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSectionHeader(
                  'Popular Courses',
                  'View All',
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(height: 12),

              // Popular Courses List
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildPopularCoursesSection(),
              ),
              const SizedBox(height: 24),

              // Learning Progress Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLearningProgressSection(),
                ),
              ),
              const SizedBox(height: 24),

              // Recommended Courses Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSectionHeader(
                  'Recommended for You',
                  'View All',
                  Icons.recommend_rounded,
                ),
              ),
              const SizedBox(height: 12),

              // Recommended Courses
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildRecommendedCourses(),
              ),
              const SizedBox(height: 32),

              // Upcoming Events Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSectionHeader(
                  'Upcoming Events',
                  'View All',
                  Icons.event_rounded,
                ),
              ),
              const SizedBox(height: 12),

              // Events Slider
              FadeTransition(
                opacity: _fadeAnimation,
                child: const EventSlider(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Welcome Header Section
  Widget _buildWelcomeHeader() {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Center(
      child: Container(
        width: isWeb
            ? MediaQuery.of(context).size.width * 0.7
            : double.infinity,
        height: isWeb ? 150 : null,
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeHelper.getPrimaryColor(context).withOpacity(0.8),
              ThemeHelper.getPrimaryColor(context),
              ThemeHelper.getPrimaryColor(context).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 119, 95, 53).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isWeb
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Continue your ${widget.selectedLanguage} journey',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.school_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Stats Section
  Widget _buildQuickStatsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final isVerySmallScreen = screenWidth <= 352;
    final isMediumSmallScreen = screenWidth > 340 && screenWidth <= 385;

    // Responsive card width - smaller for screens below 352px
    double cardWidth;
    if (isWeb) {
      cardWidth = 120.0;
    } else if (isVerySmallScreen) {
      cardWidth = 80.0; // Smaller for very small screens
    } else {
      cardWidth = 100.0; // Keep original size for other screens
    }

    if (_dashboardStatsLoading) {
      return SizedBox(
        height: 90,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildLoadingStatCard(Colors.blue[600]!),
            ),
            SizedBox(
              width: isVerySmallScreen
                  ? 8
                  : (isMediumSmallScreen ? 6 : (isWeb ? 16 : 12)),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildLoadingStatCard(Colors.green[600]!),
            ),
            SizedBox(
              width: isVerySmallScreen
                  ? 8
                  : (isMediumSmallScreen ? 6 : (isWeb ? 16 : 12)),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildLoadingStatCard(
                ThemeHelper.getPrimaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
              _dashboardStats?.totalCourses.toString() ?? '0',
              'Courses',
              Icons.school_rounded,
              Colors.blue[600]!,
            ),
          ),
          SizedBox(width: isMediumSmallScreen ? 6 : (isWeb ? 16 : 12)),
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
              _dashboardStats?.formattedLearningHours ?? '0h',
              'Learning',
              Icons.access_time_rounded,
              Colors.green[600]!,
            ),
          ),
          SizedBox(width: isMediumSmallScreen ? 6 : (isWeb ? 16 : 12)),
          SizedBox(
            width: cardWidth,
            child: _buildStatCard(
              _dashboardStats?.formattedRating ?? '0.0',
              'Rating',
              Icons.star_rounded,
              ThemeHelper.getPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.15), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Reduced padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16), // Smaller icon
          ),
          const SizedBox(height: 3), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen
                  ? 10
                  : 12, // Smaller font for screens below 380px
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen
                  ? 10
                  : 12, // Smaller font for screens below 380px
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCard(Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.15), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 20,
            height: 12,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 30,
            height: 10,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // Featured Course Card
  Widget _buildFeaturedCourseCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_featuredCoursesLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: ThemeHelper.getPrimaryColor(context),
          ),
        ),
      );
    }

    if (_featuredCourses.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_outline,
                size: 48,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
              SizedBox(height: 8),
              Text(
                'No featured courses available',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final course = _featuredCourses.first;

    return GestureDetector(
      onTap: () => _navigateToCourseDetails(course),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/developer.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ThemeHelper.getPrimaryColor(context),
                                const Color(0xFFFFD700),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${course.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Heart/Favorite Icon
                        GestureDetector(
                          onTap: () => _toggleFavorite(course),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              course.id != null &&
                                      _favoritesService.isFavorite(course.id!)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  course.id != null &&
                                      _favoritesService.isFavorite(course.id!)
                                  ? Colors.red
                                  : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: ThemeHelper.getPrimaryColor(context),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (course.rating ?? 0.0).toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 10,
                          backgroundImage: AssetImage(
                            'assets/images/homescreen.png',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course.author,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${course.enrolledStudentsCount ?? course.enrolledStudents.length} Students',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
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

  // Enhanced Section Header
  Widget _buildSectionHeader(String title, String actionText, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 350;

    // Responsive font size for very small screens
    double titleFontSize = isVerySmallScreen ? 14.0 : 18.0;
    double iconSize = isVerySmallScreen ? 14.0 : 18.0;
    double iconPadding = isVerySmallScreen ? 5.0 : 8.0;
    double spacing = isVerySmallScreen ? 6.0 : 12.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeHelper.getPrimaryColor(context),
                    const Color(0xFFFFD700),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: ThemeHelper.getPrimaryColor(
                      context,
                    ).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(width: spacing),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            // Navigate based on section title
            if (title == 'Special Offers') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OfferPage()),
              );
            } else if (title == 'All Category') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoriesPage()),
              );
            } else if (title == 'Featured Course') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeaturedCoursesPage(),
                ),
              );
            } else if (title == 'Popular Courses') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PopularCoursesPage(),
                ),
              );
            } else if (title == 'Recommended for You') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecommendedCoursesPage(),
                ),
              );
            } else if (title == 'Upcoming Events') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentEventPage(),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ThemeHelper.getPrimaryColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: ThemeHelper.getPrimaryColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Categories Section - Horizontal Scrolling
  Widget _buildCategoriesSection() {
    if (_categoriesLoading) {
      return SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ThemeHelper.getPrimaryColor(context),
            ),
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[500]
                    : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No categories available',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isWeb = MediaQuery.of(context).size.width > 600;
    final cardWidth = isWeb ? 140.0 : 120.0;

    return Center(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 8),
          shrinkWrap: true,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return Container(
              width: cardWidth,
              margin: EdgeInsets.only(
                right: 12,
                left: isWeb && index == 0 ? 0 : 0,
              ),
              child: _buildCategoryCard(category),
            );
          },
        ),
      ),
    );
  }

  // Enhanced Category Card - Similar to Special Offers Style
  Widget _buildCategoryCard(CategoryModel category) {
    // Check if we're on web/desktop for responsive layout
    final isWeb = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategoryPage(
              categoryName: category.name,
              categoryIcon: category.icon.toString(),
              categoryColor: category.color,
            ),
          ),
        );
      },
      onLongPress: () {
        // Show bottom sheet with navigation options
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.category, color: category.color),
                    title: const Text('View Subcategories'),
                    subtitle: const Text('Browse subcategories first'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubcategoryPage(
                            categoryName: category.name,
                            categoryIcon: category.icon.toString(),
                            categoryColor: category.color,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.school, color: category.color),
                    title: const Text('View All Courses'),
                    subtitle: const Text('See all courses in this category'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllCoursesPage(
                            selectedLanguage: 'en',
                            categoryName: category.name,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [category.color.withOpacity(0.8), category.color],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with background
              Container(
                width: isWeb ? 40 : 50,
                height: isWeb ? 40 : 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isWeb ? 10 : 15),
                ),
                child: Icon(
                  category.icon,
                  size: isWeb ? 22 : 28,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isWeb ? 8 : 12),

              // Category name
              Text(
                category.name,
                style: TextStyle(
                  fontSize: isWeb ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Course count with badge style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${category.courseCount} courses',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Popular Courses Section
  Widget _buildPopularCoursesSection() {
    // Check if we're on web/desktop for responsive layout
    final isWeb = MediaQuery.of(context).size.width > 600;
    final cardHeight = isWeb ? 200.0 : 180.0;

    if (_popularCoursesLoading) {
      return SizedBox(
        height: cardHeight,
        child: Center(
          child: CircularProgressIndicator(
            color: ThemeHelper.getPrimaryColor(context),
          ),
        ),
      );
    }

    if (_popularCourses.isEmpty) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return SizedBox(
        height: cardHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No popular courses available',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _popularCourses.length,
        itemBuilder: (context, index) {
          final course = _popularCourses[index];
          return _buildCompactCourseCard(
            course.title,
            '₹${course.price.toStringAsFixed(2)}',
            course.imageAsset,
            course.rating,
            '${course.enrolledStudentsCount ?? course.enrolledStudents.length}',
            course,
          );
        },
      ),
    );
  }

  // Compact Course Card for Popular Courses
  Widget _buildCompactCourseCard(
    String title,
    String price,
    String imagePath,
    double rating,
    String students,
    Course course,
  ) {
    // Check if we're on web/desktop for responsive layout
    final isWeb = MediaQuery.of(context).size.width > 600;
    final cardWidth = isWeb ? 200.0 : 180.0;
    final imageHeight = isWeb ? 110.0 : 100.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.12),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToCourseDetails(course),
        borderRadius: BorderRadius.circular(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Heart/Favorite Icon
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(course),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          course.id != null &&
                                  _favoritesService.isFavorite(course.id!)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              course.id != null &&
                                  _favoritesService.isFavorite(course.id!)
                              ? Colors.red
                              : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Price Tag
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF3D3D3D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        price,
                        style: TextStyle(
                          color: ThemeHelper.getPrimaryColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: isWeb ? 12 : 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 12 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: isWeb ? 14 : 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toString(),
                              style: TextStyle(
                                fontSize: isWeb ? 12 : 10,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$students students',
                          style: TextStyle(
                            fontSize: isWeb ? 10 : 9,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Load enrolled courses for the current user
  Future<void> _loadEnrolledCourses() async {
    try {
      setState(() {
        _isLoadingEnrolled = true;
      });
      final courses = await _courseService.getEnrolledCourses();
      if (mounted) {
        setState(() {
          _enrolledCourses = courses;
          _isLoadingEnrolled = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading enrolled courses: $e');
      if (mounted) {
        setState(() {
          _isLoadingEnrolled = false;
        });
      }
    }
  }

  // Learning Progress Section
  Widget _buildLearningProgressSection() {
    final hasEnrolledCourses = _enrolledCourses.isNotEmpty;
    final progress = hasEnrolledCourses
        ? (_enrolledCourses[0].progress ?? 0.0)
        : 0.0;
    final progressText = '${progress.toStringAsFixed(0)}%';
    final totalVideos = hasEnrolledCourses
        ? (_enrolledCourses[0].totalVideos ?? 0)
        : 0;
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Center(
      child: Container(
        width: isWeb
            ? MediaQuery.of(context).size.width * 0.7
            : double.infinity,
        height: isWeb ? 180 : null,
        padding: EdgeInsets.all(isWeb ? 24 : 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[400]!, Colors.purple[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isWeb
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    progressText,
                    style: TextStyle(
                      color: ThemeHelper.getPrimaryColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            hasEnrolledCourses
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _enrolledCourses[0].title ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (progress / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalVideos > 0
                            ? '$totalVideos ${totalVideos == 1 ? 'lesson' : 'lessons'}'
                            : 'No lessons available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'No courses enrolled yet',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
          ],
        ),
      ),
    );
  }

  // Recommended Courses
  Widget _buildRecommendedCourses() {
    // Check if we're on web/desktop for responsive layout
    final isWeb = MediaQuery.of(context).size.width > 600;
    final cardHeight = isWeb ? 200.0 : 180.0;

    if (_recommendedCoursesLoading) {
      return SizedBox(
        height: cardHeight,
        child: Center(
          child: CircularProgressIndicator(
            color: ThemeHelper.getPrimaryColor(context),
          ),
        ),
      );
    }

    if (_recommendedCourses.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: Center(
          child: Text(
            'No recommended courses available',
            style: TextStyle(
              color: ThemeHelper.getSecondaryTextColor(context),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recommendedCourses.length,
        itemBuilder: (context, index) {
          final course = _recommendedCourses[index];
          return _buildRecommendedCourseCard(course);
        },
      ),
    );
  }

  Widget _buildRecommendedCourseCard(Course course) {
    // Check if we're on web/desktop for responsive layout
    final isWeb = MediaQuery.of(context).size.width > 600;
    final cardWidth = isWeb ? 200.0 : 180.0;
    final imageHeight = isWeb ? 110.0 : 100.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.getShadowColor(context),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToCourseDetails(course),
        borderRadius: BorderRadius.circular(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
                color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey[300],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                    child: course.thumbnail != null
                        ? Image.network(
                            course.thumbnail!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode
                                    ? const Color(0xFF3D3D3D)
                                    : Colors.grey[300],
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  size: isWeb ? 36 : 32,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isDarkMode
                                ? const Color(0xFF3D3D3D)
                                : Colors.grey[300],
                            child: Icon(
                              Icons.play_circle_outline,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              size: isWeb ? 36 : 32,
                            ),
                          ),
                  ),
                  // Heart/Favorite Icon
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(course),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          course.id != null &&
                                  _favoritesService.isFavorite(course.id!)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              course.id != null &&
                                  _favoritesService.isFavorite(course.id!)
                              ? Colors.red
                              : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF3D3D3D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '₹${(course.price ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: ThemeHelper.getPrimaryColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: isWeb ? 12 : 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Course Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 12 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.getTextColor(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: isWeb ? 14 : 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              (course.rating ?? 0.0).toString(),
                              style: TextStyle(
                                fontSize: isWeb ? 12 : 10,
                                fontWeight: FontWeight.w600,
                                color: ThemeHelper.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                        // Students count
                        Text(
                          '${course.enrolledStudentsCount ?? course.enrolledStudents.length} students',
                          style: TextStyle(
                            fontSize: isWeb ? 10 : 9,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          course: course, // Pass the full course object
        ),
      ),
    );
  }

  // Enhanced Course Card
  Widget _buildEnhancedCourseCard(
    String title,
    String price,
    String imagePath,
    double rating,
    String students,
    Color accentColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 180, // More compact width
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : accentColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 85, // More compact height
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
                gradient: LinearGradient(
                  colors: [Colors.transparent, accentColor.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF3D3D3D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        price,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: ThemeHelper.getPrimaryColor(context),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$students students',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Special Offers Section
  Widget _buildSpecialOffersSection() {
    return Consumer<OffersService>(
      builder: (context, offersService, child) {
        debugPrint('🏠 HomePage: Building offers section...');
        debugPrint('🏠 Loading: ${offersService.isLoading}');
        debugPrint('🏠 Error: ${offersService.errorMessage}');
        debugPrint('🏠 Total offers: ${offersService.offers.length}');
        debugPrint('🏠 Active offers: ${offersService.activeOffers.length}');

        // Check loading state
        if (offersService.isLoading) {
          debugPrint('🏠 Showing loading state');
          return _buildOffersLoadingState();
        }

        // Skip error state - proceed to show empty state or available offers

        // Get offers for home page display (limit to 4)
        // First try active offers, then fall back to all offers if none are active
        var offers = offersService.getHomePageOffers(limit: 4);

        // If no active offers, show all offers (including expired) for demo purposes
        if (offers.isEmpty && offersService.offers.isNotEmpty) {
          offers = offersService.offers.take(4).toList();
          debugPrint(
            '🏠 No active offers, showing all offers including expired ones',
          );
        }

        debugPrint('🏠 Home page offers: ${offers.length}');

        // Check empty state
        if (offers.isEmpty) {
          debugPrint('🏠 Showing empty state');
          return _buildOffersEmptyState();
        }

        debugPrint(
          '🏠 Showing dynamic offers view with ${offers.length} offers',
        );
        return _buildDynamicOffersView(offers);
      },
    );
  }

  // Loading state for offers
  Widget _buildOffersLoadingState() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ThemeHelper.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading offers...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state for offers
  Widget _buildOffersEmptyState() {
    // Check if we're on web/desktop for responsive layout
    final isWeb = MediaQuery.of(context).size.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: isWeb ? 250 : 200,
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: Colors.grey[400],
              size: isWeb ? 48 : 36,
            ),
            SizedBox(height: isWeb ? 16 : 12),
            Text(
              'No offers available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isWeb ? 8 : 6),
            Flexible(
              child: Text(
                'Check back later for exciting deals!',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: isWeb ? 14 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isWeb ? 16 : 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfferPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeHelper.getPrimaryColor(context),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 24 : 16,
                  vertical: isWeb ? 12 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'View All Offers',
                style: TextStyle(fontSize: isWeb ? 14 : 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build offers view with static data (fallback)
  Widget _buildStaticOffersView(List<Map<String, dynamic>> offers) {
    return Column(
      children: [
        // Single offer card with PageView
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _offersPageController,
            onPageChanged: (index) {
              setState(() {
                _currentOfferIndex = index;
              });
            },
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildOfferCard(
                  percentage: offer['percentage'] as String,
                  title: offer['title'] as String,
                  subtitle: offer['subtitle'] as String,
                  backgroundColor: offer['backgroundColor'] as Color,
                  imageAsset: offer['imageAsset'] as String,
                  shapeIndex: index,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        _buildDotsIndicator(offers.length),
      ],
    );
  }

  // Dots Indicator
  Widget _buildDotsIndicator(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentOfferIndex == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentOfferIndex == index
                ? ThemeHelper.getPrimaryColor(context)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // Build offers view with dynamic API data
  Widget _buildDynamicOffersView(List<Offer> offers) {
    // Safety check - this should be handled by the caller, but just in case
    if (offers.isEmpty) {
      return _buildOffersEmptyState();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _offersPageController,
            onPageChanged: (index) {
              setState(() {
                _currentOfferIndex = index;
              });
            },
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildDynamicOfferCard(
                  offer: offer,
                  backgroundColor: _getOfferColorByIndex(index),
                  imageAsset: _getOfferImageByIndex(index),
                  shapeIndex: index,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            offers.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentOfferIndex == index
                    ? ThemeHelper.getPrimaryColor(context)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getOfferColorByIndex(int index) {
    final colors = [
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }

  String _getOfferImageByIndex(int index) {
    final images = [
      'assets/images/developer.png',
      'assets/images/tester.jpg',
      'assets/images/devop.jpg',
      'assets/images/splash1.png',
      'assets/images/homescreen.png',
    ];
    return images[index % images.length];
  }

  String _generateCouponCode(String percentage) {
    // Generate coupon codes based on percentage
    switch (percentage) {
      case '25%':
        return 'FRIDAY25';
      case '30%':
        return 'DESIGN30';
      case '35%':
        return 'TODAY35';
      default:
        return 'SAVE${percentage.replaceAll('%', '')}';
    }
  }

  // Full width Offer Card
  Widget _buildOfferCard({
    required String percentage,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required String imageAsset,
    required int shapeIndex,
  }) {
    String couponCode = _generateCouponCode(percentage);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative background shapes
          _buildBackgroundShapes(shapeIndex, backgroundColor),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left side - Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            percentage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Coupon code box
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: backgroundColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              couponCode,
                              style: TextStyle(
                                color: backgroundColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side - Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 40,
                          ),
                        );
                      },
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
}

// Dynamic Offer Card for API data
Widget _buildDynamicOfferCard({
  required Offer offer,
  required Color backgroundColor,
  required String imageAsset,
  required int shapeIndex,
}) {
  final isExpired = !offer.isValid;
  final cardColor = isExpired ? Colors.grey[600]! : backgroundColor;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: cardColor.withOpacity(0.3),
          spreadRadius: 0,
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Background shapes
        _buildBackgroundShapes(shapeIndex, cardColor),

        // Expired overlay
        if (isExpired)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withOpacity(0.3),
            ),
          ),

        // Expired badge
        if (isExpired)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'EXPIRED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Main content
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Left side - Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      offer.discountText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      offer.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.detailedValidityText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${offer.code}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right side - Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
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

// Background shapes for offer cards
Widget _buildBackgroundShapes(int shapeIndex, Color backgroundColor) {
  switch (shapeIndex % 4) {
    case 0: // Circles and dots pattern - positioned in center blank space
      return Positioned(
        top: 15,
        left: 140, // Position in the center area between text and image
        right: 100, // Leave space for the image
        bottom: 15,
        child: Stack(
          children: [
            // Large decorative circle in center
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Medium circle with gradient
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            // Small decorative dots
            Positioned(
              top: 35,
              right: 20,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 30,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      );
    case 1: // Bubble and geometric pattern - positioned in center blank space (Pink card)
      return Positioned(
        top: 15,
        left: 130, // Position in the center area between text and image
        right: 90, // Leave space for the image
        bottom: 15,
        child: Stack(
          children: [
            // Large bubble shape (like cyan card style)
            Positioned(
              top: 15,
              left: 10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            // Medium bubble
            Positioned(
              top: 30,
              right: 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.08),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Small accent bubble
            Positioned(
              bottom: 20,
              left: 30,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Tiny floating dots
            Positioned(
              top: 45,
              left: 40,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 35,
              right: 30,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
          ],
        ),
      );
    case 2: // Infinity and tech shapes - positioned in center blank space (Cyan card)
      return Positioned(
        top: 12,
        left: 140, // Position in the center area between text and image
        right: 100, // Leave space for the image
        bottom: 12,
        child: Stack(
          children: [
            // Infinity symbol shape
            Positioned(
              top: 12,
              left: 6,
              child: Container(
                width: 45,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Hexagonal tech shape
            Positioned(
              bottom: 10,
              right: 6,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Small gear-like accent
            Positioned(
              top: 38,
              right: 20,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.32),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Circuit-like line accent
            Positioned(
              bottom: 28,
              left: 12,
              child: Container(
                width: 20,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                    Container(
                      width: 4,
                      height: 4,
                      margin: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    case 3: // Layered wave patterns
      return Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Large wave shape
              Positioned(
                top: -25,
                right: -35,
                child: Container(
                  width: 130,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(65),
                      topRight: Radius.circular(45),
                      topLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Medium curved element
              Positioned(
                bottom: -25,
                left: -25,
                child: Container(
                  width: 90,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(45),
                      bottomLeft: Radius.circular(35),
                      topLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Small flowing accent
              Positioned(
                top: 45,
                left: 45,
                child: Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                      topRight: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    default:
      return Container();
  }
}
