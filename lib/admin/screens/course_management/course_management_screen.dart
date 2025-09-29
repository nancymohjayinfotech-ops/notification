import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/api_service.dart';
import 'course_details_screen.dart';
import 'add_edit_course_screen.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Course> courses = [];
  List<Course> filteredCourses = [];
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedLevel = 'All';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAllCourses(limit: 50);
      print('API Response: $result');

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> coursesData = result['data']['courses'] ?? [];
        print('Found ${coursesData.length} courses in API response');
        setState(() {
          courses = coursesData.map((courseJson) {
            print('Processing course: ${courseJson['title']}');
            return Course.fromJson(courseJson);
          }).toList();
          filteredCourses = courses;
          _isLoading = false;
        });
        print('Total courses loaded: ${courses.length}');
        print(
          'Total students across all courses: ${courses.fold(0, (sum, course) => sum + course.enrolledStudents.length)}',
        );
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load courses';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching courses: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCourses() {
    setState(() {
      filteredCourses = courses.where((course) {
        bool matchesSearch =
            course.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            course.instructor.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
        bool matchesCategory =
            selectedCategory == 'All' ||
            course.category.name == selectedCategory;
        bool matchesLevel =
            selectedLevel == 'All' || course.level == selectedLevel;

        return matchesSearch && matchesCategory && matchesLevel;
      }).toList();
    });
  }

  void _deleteCourse(String courseId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.deleteCourse(courseId);

      if (result['success'] == true) {
        // Refresh data after delete operation
        await _fetchCourses();
        _showSnackBar('Course deleted successfully');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          'Failed to delete course: ${result['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error deleting course: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final iconButtonColor = isDark ? Colors.grey[700] : Colors.grey[200];
    final iconButtonForegroundColor = isDark
        ? Colors.grey[300]
        : Colors.grey[700];
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage and monitor courses',
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _fetchCourses,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        style: IconButton.styleFrom(
                          backgroundColor: iconButtonColor,
                          foregroundColor: iconButtonForegroundColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Courses',
                          '${courses.length}',
                          Icons.school,
                          const Color(0xFF9C27B0),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Active Courses',
                          '${courses.where((c) => c.published).length}',
                          Icons.check_circle,
                          const Color(0xFF4CAF50),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Inactive Courses',
                          '${courses.where((c) => !c.published).length}',
                          Icons.cancel,
                          const Color(0xFFF44336),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Total Students',
                          '${courses.fold(0, (sum, course) => sum + course.enrolledStudents.length)}',
                          Icons.people,
                          const Color(0xFF2196F3),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        _filterCourses();
                      },
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        hintStyle: TextStyle(color: secondaryTextColor),
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF9C27B0),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                          'Category',
                          selectedCategory,
                          [
                            'All',
                            'Mobile Development',
                            'Web Development',
                            'Data Science',
                            'Design',
                          ],
                          (value) {
                            selectedCategory = value!;
                            _filterCourses();
                          },
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFilterDropdown(
                          'Level',
                          selectedLevel,
                          ['All', 'Beginner', 'Intermediate', 'Advanced'],
                          (value) {
                            selectedLevel = value!;
                            _filterCourses();
                          },
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Courses List
                  filteredCourses.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'No courses found',
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: filteredCourses
                              .map((course) => _buildCourseCard(course, isDark))
                              .toList(),
                        ),
                ],
              ),
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddCourse(),
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Course'),
          elevation: 8,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildErrorState(bool isDark) {
    final textColor = isDark ? Colors.black : Colors.white;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchCourses, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.black : Colors.white;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          style: TextStyle(color: textColor),
          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: textColor),
          hint: Text(label, style: TextStyle(color: textColor)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(color: textColor)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, bool isDark) {
    final textColor = isDark ? Colors.black : Colors.white;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title on left, Price & Rating on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course title (left side)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: course.published
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.published ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: course.published ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price and Rating (right side)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price
                  Text(
                    '₹${course.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        course.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Actions menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: secondaryTextColor,
                ),
                color: isDark ? Colors.grey[800] : Colors.white,
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _navigateToCourseDetails(course);
                      break;
                    case 'edit':
                      _navigateToEditCourse(course);
                      break;
                    case 'delete':
                      _showDeleteDialog(course, isDark);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 16, color: textColor),
                        const SizedBox(width: 8),
                        Text('View', style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: textColor),
                        const SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: Instructor and Category
          Row(
            children: [
              // Instructor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructor',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.instructor.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
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

  void _navigateToCourseDetails(Course course) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(courseId: course.id),
      ),
    );

    // Refresh data if course was updated from details screen
    if (result == true) {
      await _fetchCourses();
    }
  }

  void _navigateToAddCourse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditCourseScreen()),
    );

    // Refresh data after add operation
    if (result == true) {
      await _fetchCourses();
      _showSnackBar('Course added successfully');
    }
  }

  void _navigateToEditCourse(Course course) async {
    try {
      // Show loading snackbar instead of dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Loading course details...'),
            ],
          ),
          duration: const Duration(
            seconds: 10,
          ), // Long duration, will be dismissed manually
        ),
      );

      // Fetch full course details including sections
      final result = await ApiService.getCourseById(course.id);

      // Dismiss loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success'] == true && result['data'] != null) {
        final fullCourse = Course.fromJson(result['data']['course']);

        final editResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditCourseScreen(course: fullCourse),
          ),
        );

        // Refresh data after edit operation
        if (editResult == true) {
          await _fetchCourses();
          _showSnackBar('Course updated successfully');
        }
      } else {
        _showSnackBar('Failed to load course details for editing');
      }
    } catch (e) {
      // Ensure loading indicator is dismissed
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar('Error loading course: $e');
    }
  }

  void _showDeleteDialog(Course course, bool isDark) {
    final textColor = isDark ? Colors.black : Colors.white;
    final backgroundColor = isDark ? Colors.grey[800] : Colors.white;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(
          context,
        ).copyWith(dialogBackgroundColor: backgroundColor),
        child: AlertDialog(
          title: Text('Delete Course', style: TextStyle(color: textColor)),
          content: Text(
            'Are you sure you want to delete "${course.title}"? This action cannot be undone.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: textColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCourse(course.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF9C27B0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
