import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'dart:convert';
import 'create_course_page.dart';
import 'categories_view.dart';
import 'quiz_assessment_builder.dart';
import 'package:http/http.dart' as http;

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final List<String> _tabs = ['Course List', 'Categories'];
  int _currentTabIndex = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: Color(0xFF5F299E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.add, color: Colors.white),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const CreateCoursePage(),
          //       ),
          //     );
          //   },
          //   tooltip: 'Create New Course',
          // ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTabIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTabIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _currentTabIndex == index
                            ? [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentTabIndex == index
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tab Content
          Expanded(
            child: _currentTabIndex == 0
                ? const CourseListView()
                : const CategoriesView(),
          ),
        ],
      ),
    );
  }
}

class CourseListView extends StatefulWidget {
  const CourseListView({super.key});

  @override
  State<CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends State<CourseListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';
  bool _isLoading = true;
  final int _currentPage = 1;
  final int _pageSize = 10;

  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  List<String> _categories = ['All Categories'];
  final List<String> _statuses = ['All Status', 'Published', 'Draft'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.get(
        Uri.parse(
          'http://54.82.53.11:5001/api/instructor/courses?page=1&limit=10',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final courses = data['data']['courses'] as List;

          setState(() {
            _allCourses = List<Map<String, dynamic>>.from(courses);
            _extractCategories();
            _filterCourses();
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load courses: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      print('Error fetching courses: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load courses: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {
                _fetchCourses();
              },
            ),
          ),
        );
      }

      setState(() {
        _allCourses = [];
        _extractCategories();
        _filterCourses();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSampleCourses() {
    return [
      {
        '_id': 'course_1',
        'title': 'Flutter Development Masterclass',
        'category': {'name': 'Mobile Development'},
        'enrolledStudents': List.filled(42, ''),
        'thumbnail': 'assets/images/developer.png',
        'price': 99.99,
        'published': true,
        'averageRating': 4.8,
      },
      {
        '_id': 'course_2',
        'title': 'Advanced React & Node.js',
        'category': {'name': 'Web Development'},
        'enrolledStudents': List.filled(28, ''),
        'thumbnail': 'assets/images/devop.png',
        'price': 89.99,
        'published': true,
        'averageRating': 4.6,
      },
      {
        '_id': 'course_3',
        'title': 'UI/UX Design Fundamentals',
        'category': {'name': 'Design'},
        'enrolledStudents': List.filled(35, ''),
        'thumbnail': 'assets/images/digital.jpg',
        'price': 79.99,
        'published': true,
        'averageRating': 4.7,
      },
      {
        '_id': 'course_4',
        'title': 'Python for Data Science',
        'category': {'name': 'Data Science'},
        'enrolledStudents': List.filled(50, ''),
        'thumbnail': 'assets/images/developer.png',
        'price': 109.99,
        'published': false,
        'averageRating': 4.9,
      },
      {
        '_id': 'course_5',
        'title': 'Machine Learning Fundamentals',
        'category': {'name': 'AI & Machine Learning'},
        'enrolledStudents': List.filled(22, ''),
        'thumbnail': 'assets/images/devop.png',
        'price': 129.99,
        'published': false,
        'averageRating': 4.5,
      },
    ];
  }

  void _extractCategories() {
    final categories = ['All Categories'];

    for (var course in _allCourses) {
      final categoryName = course['category']?['name'];
      if (categoryName != null && !categories.contains(categoryName)) {
        categories.add(categoryName);
      }
    }

    setState(() {
      _categories = categories;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterCourses();
    });
  }

  void _filterCourses() {
    setState(() {
      _filteredCourses = _allCourses.where((course) {
        final title = course['title']?.toString().toLowerCase() ?? '';
        final category =
            course['category']?['name']?.toString().toLowerCase() ?? '';

        final matchesQuery =
            title.contains(_searchQuery.toLowerCase()) ||
            category.contains(_searchQuery.toLowerCase());

        final matchesCategory =
            _selectedCategory == 'All Categories' ||
            course['category']?['name'] == _selectedCategory;

        final courseStatus = course['published'] == true
            ? 'Published'
            : 'Draft';
        final matchesStatus =
            _selectedStatus == 'All Status' || courseStatus == _selectedStatus;

        return matchesQuery && matchesCategory && matchesStatus;
      }).toList();
    });
  }

  void _showFilterDialog() {
    String tempCategory = _selectedCategory;
    String tempStatus = _selectedStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Filter Courses',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempCategory,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => tempCategory = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempStatus,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: _statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => tempStatus = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    tempCategory = 'All Categories';
                    tempStatus = 'All Status';
                  });
                },
              ),
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Apply'),
                onPressed: () {
                  this.setState(() {
                    _selectedCategory = tempCategory;
                    _selectedStatus = tempStatus;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search your courses...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _showFilterDialog,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_selectedCategory != 'All Categories' ||
            _selectedStatus != 'All Status')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                if (_selectedCategory != 'All Categories')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_selectedCategory),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      deleteIconColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = 'All Categories';
                          _filterCourses();
                        });
                      },
                    ),
                  ),
                if (_selectedStatus != 'All Status')
                  Chip(
                    label: Text(_selectedStatus),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    deleteIconColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedStatus = 'All Status';
                        _filterCourses();
                      });
                    },
                  ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                '${_filteredCourses.length} courses found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _filteredCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No courses found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty ||
                                _selectedCategory != 'All Categories' ||
                                _selectedStatus != 'All Status'
                            ? 'Try adjusting your search or filters'
                            : 'You haven\'t created any courses yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_searchQuery.isEmpty &&
                          _selectedCategory == 'All Categories' &&
                          _selectedStatus == 'All Status')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateCoursePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          icon: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          label: Text(
                            'Create a Course',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = _filteredCourses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/developer.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Theme.of(context).dividerColor,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    course['category']?['name'] ??
                                        'Uncategorized',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).iconTheme.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course['enrolledStudents'] is List ? (course['enrolledStudents'] as List).length : 0} Enrolled',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course['averageRating'] ?? '0.0'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(
                                          course['published']
                                              ? 'Published'
                                              : 'Draft',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: course['published']
                                                ? Colors.green[800]
                                                : Colors.orange[800],
                                          ),
                                        ),
                                        backgroundColor: course['published']
                                            ? Colors.green[100]
                                            : Colors.orange[100],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.quiz,
                                              size: 20,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ),
                                            onPressed: () {
                                              final courseId =
                                                  course['_id']?.toString() ??
                                                  '';
                                              if (courseId.isNotEmpty) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        QuizAssessmentBuilderPage(
                                                          courseId: courseId,
                                                        ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Cannot create quiz: Course ID not available. Please try creating a new course.',
                                                    ),
                                                    backgroundColor: Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                                  ),
                                                );
                                              }
                                            },
                                            tooltip: 'Create Quiz',
                                          ),
                                          // IconButton(
                                          //   icon: Icon(
                                          //     Icons.edit,
                                          //     size: 20,
                                          //     color: Theme.of(
                                          //       context,
                                          //     ).colorScheme.primary,
                                          //   ),
                                          //   onPressed: () {
                                          //     // Edit course logic
                                          //   },
                                          // ),
                                          // IconButton(
                                          //   icon: Icon(
                                          //     Icons.delete,
                                          //     size: 20,
                                          //     color: Theme.of(
                                          //       context,
                                          //     ).colorScheme.error,
                                          //   ),
                                          //   onPressed: () {
                                          //     // Delete course logic
                                          //   },
                                          // ),
                                        ],
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
                  },
                ),
        ),
      ],
    );
  }
}
