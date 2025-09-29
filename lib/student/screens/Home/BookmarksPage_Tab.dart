import 'package:flutter/material.dart';
import '../courses/CourseDetailsPage.dart';
import '../../models/course.dart';
import '../../services/favorites_service.dart';

class BookMarkPageTab extends StatefulWidget {
  final String selectedLanguage;

  const BookMarkPageTab({super.key, required this.selectedLanguage});

  @override
  State<BookMarkPageTab> createState() => _BookMarkPageTabState();
}

class _BookMarkPageTabState extends State<BookMarkPageTab> {
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  double _minRating = 0.0;
  double _maxPrice = 200.0;
  String _searchQuery = '';

  // All courses data
  late List<Course> _allCourses;
  late List<Course> _filteredCourses;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _initializeCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _initializeCourses() {
    _allCourses = [
      Course(
        title: 'Flutter Development Fundamentals',
        author: 'By John Carter',
        imageAsset: 'assets/images/developer.png',
        price: 89.99,
        averageRating: 4.8,
        students: '2.5k',
        duration: '90 days access',
        description: 'Learn Flutter development from scratch',
      ),
      Course(
        title: 'User Experience Design Fundamentals',
        author: 'By John Carter',
        imageAsset: 'assets/images/tester.jpg',
        price: 79.99,
        averageRating: 4.6,
        students: '1.8k',
        duration: '90 days access',
        description: 'Master UX design principles',
      ),
      Course(
        title: 'DevOps and Cloud Computing',
        author: 'By John Carter',
        imageAsset: 'assets/images/devop.jpg',
        price: 129.99,
        averageRating: 4.9,
        students: '3.2k',
        duration: '90 days access',
        description: 'Learn DevOps and cloud technologies',
      ),
      Course(
        title: 'Software Testing and QA',
        author: 'By John Carter',
        imageAsset: 'assets/images/test.png',
        price: 69.99,
        averageRating: 4.5,
        students: '1.5k',
        duration: '90 days access',
        description: 'Comprehensive software testing course',
      ),
      Course(
        title: 'Complete Flutter Development',
        author: 'By Sarah Wilson',
        imageAsset: 'assets/images/developer.png',
        price: 149.99,
        averageRating: 4.9,
        students: '4.1k',
        duration: '90 days access',
        description: 'Advanced Flutter development course',
      ),
      Course(
        title: 'Digital Marketing Mastery',
        author: 'By Mike Johnson',
        imageAsset: 'assets/images/splash1.png',
        price: 59.99,
        averageRating: 4.3,
        students: '2.8k',
        duration: '90 days access',
        description: 'Master digital marketing strategies',
      ),
      Course(
        title: 'Python for Data Science',
        author: 'By Dr. Emily Chen',
        imageAsset: 'assets/images/devop.jpg',
        price: 99.99,
        averageRating: 4.7,
        students: '3.5k',
        duration: '90 days access',
        description: 'Learn Python for data analysis',
      ),
      Course(
        title: 'Web Design Fundamentals',
        author: 'By Alex Rodriguez',
        imageAsset: 'assets/images/homescreen.png',
        price: 49.99,
        averageRating: 4.4,
        students: '1.9k',
        duration: '90 days access',
        description: 'Learn modern web design',
      ),
      Course(
        title: 'Business Analytics',
        author: 'By Jennifer Lee',
        imageAsset: 'assets/images/tester.jpg',
        price: 89.99,
        averageRating: 4.6,
        students: '2.1k',
        duration: '90 days access',
        description: 'Master business analytics',
      ),
      Course(
        title: 'Mobile App Design',
        author: 'By David Kim',
        imageAsset: 'assets/images/splash2.png',
        price: 79.99,
        averageRating: 4.5,
        students: '1.7k',
        duration: '90 days access',
        description: 'Design beautiful mobile apps',
      ),
      Course(
        title: 'Machine Learning Basics',
        author: 'By Dr. Robert Smith',
        imageAsset: 'assets/images/devop.png',
        price: 119.99,
        averageRating: 4.8,
        students: '2.9k',
        duration: '90 days access',
        description: 'Introduction to machine learning',
      ),
      Course(
        title: 'UI/UX Design with Figma',
        author: 'By Maria Garcia',
        imageAsset: 'assets/images/test.png',
        price: 69.99,
        averageRating: 4.7,
        students: '2.3k',
        duration: '90 days access',
        description: 'Master Figma for UI/UX design',
      ),
      Course(
        title: 'Agile Project Management',
        author: 'By Thomas Brown',
        imageAsset: 'assets/images/splash2.png',
        price: 59.99,
        averageRating: 4.4,
        students: '1.6k',
        duration: '90 days access',
        description: 'Learn agile methodologies',
      ),
      Course(
        title: 'DevOps Engineering',
        author: 'By Lisa Anderson',
        imageAsset: 'assets/images/devop.png',
        price: 139.99,
        averageRating: 4.9,
        students: '3.8k',
        duration: '90 days access',
        description: 'Advanced DevOps engineering',
      ),
    ];
    _filteredCourses = List.from(_allCourses);
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
        bool matchesRating = course.averageRating >= _minRating;

        // Price filter
        bool matchesPrice = course.price <= _maxPrice;

        return matchesSearch && matchesRating && matchesPrice;
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
              title: Text('Filter Courses'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  SizedBox(height: 20),
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minRating = 0.0;
                      _maxPrice = 200.0;
                    });
                    _filterCourses();
                    Navigator.of(context).pop();
                  },
                  child: Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _filterCourses();
                    Navigator.of(context).pop();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, {required Course course}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsPage(
              courseId: course.id ?? 'unknown',
              courseTitle: course.title,
              courseAuthor: course.author,
              courseImage: course.imageAsset,
              progress: course.progress,
              progressText: course.progressText,
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
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image and Title Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: AssetImage(course.imageAsset),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          course.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                        SizedBox(height: 6),
                        // Rating and Price Row
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              course.averageRating.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              '\$${course.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F299E),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFEF3C7), // Light yellow background
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFF59E0B), // Yellow border
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFFD97706), // Amber color
                              ),
                              SizedBox(width: 4),
                              Text(
                                '90 days access',
                                style: TextStyle(
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
                  // Heart Icon for Favorites (fixed)
                  IconButton(
                    icon: Icon(
                      _favoritesService.isFavorite(course.id ?? '')
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _favoritesService.isFavorite(course.id ?? '')
                          ? Colors.red
                          : Colors.grey[400],
                      size: 24,
                    ),
                    onPressed: () => _toggleFavorite(course),
                    tooltip: _favoritesService.isFavorite(course.id ?? '')
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                ],
              ),
            ),

            // Start Course Button
            Padding(
              padding: EdgeInsets.all(16),
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
                          progress: course.progress,
                          progressText: course.progressText,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5F299E),
                    side: BorderSide(color: Color(0xFF5F299E), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shadowColor: Color(0xFF5F299E).withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Start Course',
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

  // Update _toggleFavorite to accept a Course object
  Future<void> _toggleFavorite(Course course) async {
    final wasFavorite = _favoritesService.isFavorite(course.id ?? '');
    final success = await _favoritesService.toggleFavorite(course);

    if (!mounted) return;

    final isNowFavorite = _favoritesService.isFavorite(course.id ?? '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isNowFavorite
                    ? '${course.title} added to favorites'
                    : '${course.title} removed from favorites')
              : 'Failed to update favorites',
              style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              ),
        ),
        backgroundColor: success
            ? (isNowFavorite ? Colors.green : Colors.red)
            : Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Courses'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _filteredCourses.isEmpty
                ? Center(
                    child: Text(
                      'No courses found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      return _buildCourseCard(context, course: course);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
