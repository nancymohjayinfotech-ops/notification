import 'package:flutter/material.dart';
import 'user_detail_screen.dart';
import '../../services/api_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _stats = {
    'total': 0,
    'isActive': 0,
    'isInactive': 0,
    'recentlyActive': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadStats();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_hasMoreData && !_isLoadingMore) {
        print('Triggering infinite scroll - loading more students...');
        _loadMoreStudents();
      }
    }
  }

  Future<void> _loadStudents({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _students.clear();
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getAllStudents(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success'] == true) {
        final newStudents = List<Map<String, dynamic>>.from(
          result['data']['students'] ?? [],
        );

        setState(() {
          if (isRefresh || _currentPage == 1) {
            _students = newStudents;
          } else {
            _students.addAll(newStudents);
          }
          // Show more button if we got a full page of results (indicating more might be available)
          _hasMoreData = newStudents.length == _limit;
          _isLoading = false;
        });

        // Debug: Print pagination info
        print(
          'Loaded ${newStudents.length} students, _hasMoreData: $_hasMoreData, _currentPage: $_currentPage',
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to load students');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading students: $e');
    }
  }

  Future<void> _loadMoreStudents() async {
    if (_isLoadingMore || !_hasMoreData) {
      print(
        'Skipping load more - isLoadingMore: $_isLoadingMore, hasMoreData: $_hasMoreData',
      );
      return;
    }

    print('Loading more students - page: ${_currentPage + 1}');
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final result = await ApiService.getAllStudents(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success'] == true) {
        final newStudents = List<Map<String, dynamic>>.from(
          result['data']['students'] ?? [],
        );

        print(
          'Loaded ${newStudents.length} more students. Total: ${_students.length + newStudents.length}, hasMoreData: ${newStudents.length == _limit}',
        );

        setState(() {
          _students.addAll(newStudents);
          _hasMoreData = newStudents.length == _limit;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _currentPage--; // Revert page increment on failure
          _isLoadingMore = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to load more students');
      }
    } catch (e) {
      setState(() {
        _currentPage--; // Revert page increment on failure
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Error loading more students: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await ApiService.getStudentStats();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _stats = result['data'];
        });
      }
    } catch (e) {
      // Silently handle stats loading error
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get filteredStudents {
    return _students;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and monitor student accounts',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Section
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white : Colors.black,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  _loadStudents(isRefresh: true);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Students',
                    '${_stats['total'] ?? 0}',
                    Icons.school,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    '${_stats['isActive'] ?? 0}',
                    Icons.check_circle,
                    const Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Inactive',
                    '${_stats['isInactive'] ?? 0}',
                    Icons.schedule,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Clear Search Button
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _loadStudents(isRefresh: true);
                      },
                      child: Text(
                        'Clear Search',
                        style: TextStyle(
                          color: isDark ? Colors.blue[300] : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Students List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.blue[300]! : const Color(0xFF9C27B0),
                        ),
                      ),
                    )
                  : _students.isEmpty
                  ? Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _students.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _students.length) {
                                // Loading indicator at the end for infinite scroll
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? Colors.blue[300]!
                                            : const Color(0xFF9C27B0),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final student = _students[index];
                              // Define card and text colors for the student card
                              final cardColor = isDark
                                  ? Colors.white!
                                  : Colors.black;
                              final textColor = isDark
                                  ? Colors.black
                                  : Colors.white;
                              final secondaryTextColor = isDark
                                  ? Colors.grey[400]!
                                  : Colors.grey[600]!;
                              final shadowColor = isDark
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.1);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildStudentCard(
                                  student,
                                  isDark,
                                  cardColor,
                                  textColor,
                                  secondaryTextColor,
                                  shadowColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      // floatingActionButton: Container(
      //   margin: const EdgeInsets.only(bottom: 16, right: 16),
      //   child: FloatingActionButton.extended(
      //     onPressed: _showCreateStudentDialog,
      //     backgroundColor: isDark ? Colors.blue[700] : const Color(0xFF9C27B0),
      //     foregroundColor: Colors.white,
      //     icon: const Icon(Icons.group_add),
      //     label: const Text('Create Student'),
      //     elevation: 8,
      //   ),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color : isDark
            ? const Color(0xFF2e2d2f)
            : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.grey
                : Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    Map<String, dynamic> student,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color shadowColor,
  ) {
    return GestureDetector(
      onTap: () => _navigateToStudentDetail(student),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.grey
                  : Colors.black,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark
                    ? Colors.blue[700]
                    : const Color(0xFF9C27B0),
                child: Text(
                  _getInitials(student['name'] ?? 'Student'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] ?? 'Unknown Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (student['email'] != null &&
                        student['email'].toString().isNotEmpty)
                      Text(
                        student['email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (student['studentId'] != null &&
                            student['studentId'].toString().isNotEmpty)
                          Expanded(
                            child: Text(
                              'ID: ${student['studentId']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (student['isActive'] == true
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student['isActive'] == true ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: student['isActive'] == true
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Phone number and menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: secondaryTextColor,
                        ),
                        onSelected: (value) =>
                            _handleStudentAction(value, student),
                        itemBuilder: (context) => _buildMenuItems(student),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (student['phoneNumber'] != null &&
                      student['phoneNumber'].toString().isNotEmpty)
                    Text(
                      student['phoneNumber'],
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    for (int i = 0; i < names.length && i < 2; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials.isEmpty ? 'S' : initials;
  }

  // Email validation function
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Phone number validation function
  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\d{10}$'); // Adjust as needed
    return phoneRegex.hasMatch(phone);
  }

  void _navigateToStudentDetail(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: student)),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(
              Icons.edit,
              size: 16,
              color: isDark ? Colors.blue[300] : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
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
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    ];
  }

  void _handleStudentAction(String action, Map<String, dynamic> student) {
    switch (action) {
      case 'edit':
        _showEditStudentDialog(student);
        break;
      case 'delete':
        _showDeleteStudentDialog(student);
        break;
    }
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: student['name'] ?? '');
    final emailController = TextEditingController(text: student['email'] ?? '');
    final phoneController = TextEditingController(
      text: student['phoneNumber'] ?? '',
    );
    final addressController = TextEditingController(
      text: student['address'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFFF6F4FB)
            : const Color(0xFF2e2d2f),
        title: Text(
          'Edit ${student['name']}',
          style: TextStyle(color: isDark ? Colors.black87 : Colors.white),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  style: TextStyle(
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  style: TextStyle(
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.blue[300] : Colors.blue),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate fields before updating
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (phoneController.text.trim().isNotEmpty &&
                  !_isValidPhone(phoneController.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid phone number (10 digits)',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (emailController.text.trim().isNotEmpty &&
                  !_isValidEmail(emailController.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updatedData = {
                'name': nameController.text.trim(),
                'phoneNumber': phoneController.text.trim(),
                'email': emailController.text.trim(),
                'address': addressController.text.trim(),
              };

              try {
                final result = await ApiService.updateStudent(
                  student['_id'] ?? student['id'].toString(),
                  updatedData,
                );

                Navigator.pop(context);

                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${student['name']} updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStudents(); // Refresh the list
                  _loadStats(); // Refresh the stats
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Failed to update student',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating student: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.blue[700]
                  : const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteStudentDialog(Map<String, dynamic> student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        title: Text(
          'Delete Student',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to delete ${student['name']}? This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.blue[300] : Colors.blue),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await ApiService.deleteStudent(
                  student['_id'] ?? student['id'].toString(),
                );

                Navigator.pop(context);

                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${student['name']} deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  _loadStudents(); // Refresh the list
                  _loadStats(); // Refresh the stats
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Failed to delete student',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting student: $e'),
                    backgroundColor: Colors.red,
                  ),
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

  void _showCreateStudentDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        title: Text(
          'Create New Student',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.blue[300]! : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.blue[300]! : Colors.blue,
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.blue[300]! : Colors.blue,
                    ),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.blue[300]! : Colors.blue,
                    ),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.blue[300] : Colors.blue),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate required fields
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (!_isValidPhone(phoneController.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid phone number (10 digits)',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (!_isValidEmail(emailController.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (addressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final result = await ApiService.createStudent(
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                );

                Navigator.pop(context);

                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${nameController.text.trim()} created successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStudents(isRefresh: true); // Refresh the list
                  _loadStats(); // Refresh the stats
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Failed to create student',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating student: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.blue[700]
                  : const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
