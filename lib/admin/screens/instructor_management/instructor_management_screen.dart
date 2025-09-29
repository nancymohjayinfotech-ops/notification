import 'package:flutter/material.dart';
import '../../models/instructor.dart';
import '../../services/api_service.dart';
import 'instructor_detail_screen.dart';

class InstructorManagementScreen extends StatefulWidget {
  const InstructorManagementScreen({super.key});

  @override
  State<InstructorManagementScreen> createState() =>
      _InstructorManagementScreenState();
}

class _InstructorManagementScreenState
    extends State<InstructorManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Instructor> instructors = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  String _searchQuery = '';
  String selectedFilter = 'All';
  Map<String, dynamic> _stats = {'total': 0, 'isActive': 0, 'isInactive': 0};

  @override
  void initState() {
    super.initState();
    _loadInstructors();
    _loadStats();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_hasMoreData && !_isLoadingMore) {
        print('Triggering infinite scroll - loading more instructors...');
        _loadMoreInstructors();
      }
    }
  }

  Future<void> _loadInstructors({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        instructors.clear();
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getAllInstructors(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: selectedFilter != 'All' ? selectedFilter.toLowerCase() : null,
      );

      if (result['success'] == true) {
        final newInstructors = (result['data']['instructors'] as List)
            .map((json) => Instructor.fromJson(json))
            .toList();

        setState(() {
          if (isRefresh || _currentPage == 1) {
            instructors = newInstructors;
          } else {
            instructors.addAll(newInstructors);
          }
          _hasMoreData = newInstructors.length == _limit;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to load instructors');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading instructors: $e');
    }
  }

  Future<void> _loadMoreInstructors() async {
    if (_isLoadingMore || !_hasMoreData) {
      print(
        'Skipping load more - isLoadingMore: $_isLoadingMore, hasMoreData: $_hasMoreData',
      );
      return;
    }

    print('Loading more instructors - page: ${_currentPage + 1}');
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final result = await ApiService.getAllInstructors(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: selectedFilter != 'All' ? selectedFilter.toLowerCase() : null,
      );

      if (result['success'] == true) {
        final newInstructors = (result['data']['instructors'] as List)
            .map((json) => Instructor.fromJson(json))
            .toList();

        print(
          'Loaded ${newInstructors.length} more instructors. Total: ${instructors.length + newInstructors.length}, hasMoreData: ${newInstructors.length == _limit}',
        );

        setState(() {
          instructors.addAll(newInstructors);
          _hasMoreData = newInstructors.length == _limit;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _currentPage--; // Revert page increment on failure
          _isLoadingMore = false;
        });
        _showErrorSnackBar(
          result['message'] ?? 'Failed to load more instructors',
        );
      }
    } catch (e) {
      setState(() {
        _currentPage--; // Revert page increment on failure
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Error loading more instructors: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await ApiService.getInstructorStats();
      if (result['success'] == true) {
        setState(() {
          _stats = result['data'];
        });
      }
    } catch (e) {
      print('Error loading instructor stats: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double _getResponsiveWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Small screens (mobile)
      return screenWidth * 0.95;
    } else if (screenWidth < 1200) {
      // Medium screens (tablet)
      return screenWidth * 0.85;
    } else {
      // Large screens (desktop)
      return screenWidth * 0.7;
    }
  }

  double _getDialogWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 350) {
      // Ultra-small screens - use maximum available width with minimal padding
      return screenWidth - 16; // Only 8px padding on each side
    } else if (screenWidth < 600) {
      // Small screens (mobile) - use almost full screen width
      return screenWidth * 0.98;
    } else if (screenWidth < 900) {
      // Medium screens (tablet) - use 85% of screen
      return screenWidth * 0.85;
    } else if (screenWidth < 1200) {
      // Large tablets/small desktop - use 75% of screen
      return screenWidth * 0.75;
    } else {
      // Large screens (desktop) - use 65% of screen
      return screenWidth * 0.65;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          // Header with stats
          _buildStatsHeader(isDark: isDark),

          // Search and filters
          SizedBox(
            width: _getResponsiveWidth(context),
            child: _buildSearchAndFilters(isDark: isDark),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : Color(0xFF9C27B0),
                      ),
                    ),
                  )
                : instructors.isEmpty
                ? _buildEmptyState(isDark: isDark)
                : _buildInstructorList(isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader({bool isDark = false}) {
    return Container(
      width: _getResponsiveWidth(context),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.school,
            _stats['total']?.toString() ?? '0',
            'Total Instructors',
          ),
          _buildStatItem(
            Icons.verified,
            _stats['isActive']?.toString() ?? '0',
            'Active',
          ),
          _buildStatItem(
            Icons.cancel,
            _stats['isInactive']?.toString() ?? '0',
            'Inactive',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.black : Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters({bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              style: TextStyle(color: isDark ? Colors.black : Colors.white),
              onChanged: (value) {
                _searchQuery = value;
                _loadInstructors(isRefresh: true);
              },
              decoration: InputDecoration(
                hintText: 'Search instructors...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter buttons
          Row(
            children: [
              Expanded(child: _buildFilterButton('All', isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterButton('Active', isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterButton('Inactive', isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter, {bool isDark = false}) {
    bool isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
          _loadInstructors(isRefresh: true);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9C27B0)
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C27B0)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          filter,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorList({bool isDark = false}) {
    return Center(
      child: SizedBox(
        width: _getResponsiveWidth(context),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: instructors.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == instructors.length) {
              // Loading indicator at the end for infinite scroll
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : Color(0xFF9C27B0),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInstructorCard(instructors[index], isDark: isDark),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstructorCard(Instructor instructor, {bool isDark = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                InstructorDetailScreen(instructor: instructor),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Image/Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child:
                    instructor.avatar != null && instructor.avatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          instructor.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),

              // Instructor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            instructor.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // Verification Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: instructor.isVerified
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            instructor.isVerified ? 'Verified' : 'Not Verified',
                            style: TextStyle(
                              color: instructor.isVerified
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Active Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: instructor.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            instructor.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: instructor.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instructor.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            instructor.phoneNumber.isNotEmpty
                                ? instructor.phoneNumber
                                : 'No phone',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (instructor.skills.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              instructor.skills.take(2).join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Action button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                onSelected: (value) =>
                    _handleInstructorAction(value, instructor),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!instructor.isVerified)
                    const PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text('Approve'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
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

  Widget _buildEmptyState({bool isDark = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No instructors found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first instructor to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _handleInstructorAction(String action, Instructor instructor) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                InstructorDetailScreen(instructor: instructor),
          ),
        );
        break;
      case 'edit':
        _showEditInstructorDialog(instructor);
        break;
      case 'approve':
        _showApproveDialog(instructor);
        break;
      case 'delete':
        _showDeleteInstructorDialog(instructor);
        break;
    }
  }

  void _showAddInstructorDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final bioController = TextEditingController();
    String selectedSpecialization = 'Mobile Development';
    List<String> selectedSkills = [];

    final specializations = [
      'Mobile Development',
      'Web Development',
      'UI/UX Design',
      'Backend Development',
      'Data Science',
      'DevOps',
    ];

    final availableSkills = [
      'Flutter',
      'Dart',
      'React',
      'JavaScript',
      'Python',
      'Java',
      'Swift',
      'Kotlin',
      'Node.js',
      'Firebase',
      'AWS',
      'Docker',
      'Figma',
      'Adobe XD',
      'MongoDB',
      'PostgreSQL',
      'REST APIs',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Instructor'),
          content: SizedBox(
            width: _getDialogWidth(context),
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSpecialization,
                    decoration: const InputDecoration(
                      labelText: 'Specialization',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: specializations
                        .map(
                          (spec) => DropdownMenuItem(
                            value: spec,
                            child: Text(
                              spec,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                    ? 12
                                    : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedSpecialization = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSkills.map((skill) {
                          bool isSelected = selectedSkills.contains(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedSkills.add(skill);
                                } else {
                                  selectedSkills.remove(skill);
                                }
                              });
                            },
                            selectedColor: const Color(
                              0xFF9C27B0,
                            ).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF9C27B0),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name is required'),
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
                      content: Text('Enter a valid email address'),
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
                      content: Text('Enter a valid phone number (10 digits)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _addInstructor(
                  nameController.text,
                  emailController.text,
                  phoneController.text,
                  selectedSpecialization,
                  bioController.text,
                  selectedSkills,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Instructor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInstructor(
    String name,
    String email,
    String phone,
    String specialization,
    String bio,
    List<String> skills,
  ) async {
    try {
      // Only send fields that the API accepts
      final instructorData = {
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'specializations': specialization,
        'skills': skills,
      };

      final result = await ApiService.addInstructor(instructorData);

      if (result['success'] == true) {
        await _loadInstructors(isRefresh: true);
        await _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added successfully as instructor'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to add instructor');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding instructor: $e');
    }
  }

  void _showEditInstructorDialog(Instructor instructor) {
    final nameController = TextEditingController(text: instructor.name);
    final emailController = TextEditingController(text: instructor.email);
    final phoneController = TextEditingController(text: instructor.phoneNumber);
    final bioController = TextEditingController(text: instructor.bio);
    String selectedSpecialization =
        'Mobile Development'; // Default since no specialization field
    List<String> selectedSkills = List.from(instructor.skills);
    bool isActive = instructor.isActive;

    final specializations = [
      'Mobile Development',
      'Web Development',
      'UI/UX Design',
      'Backend Development',
      'Data Science',
      'DevOps',
    ];

    final availableSkills = [
      'Flutter',
      'Dart',
      'React',
      'JavaScript',
      'Python',
      'Java',
      'Swift',
      'Kotlin',
      'Node.js',
      'Firebase',
      'AWS',
      'Docker',
      'Figma',
      'Adobe XD',
      'MongoDB',
      'PostgreSQL',
      'REST APIs',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${instructor.name}'),
          content: SizedBox(
            width: _getDialogWidth(context),
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSpecialization,
                    decoration: const InputDecoration(
                      labelText: 'Specialization',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: specializations
                        .map(
                          (spec) => DropdownMenuItem(
                            value: spec,
                            child: Text(
                              spec,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                    ? 12
                                    : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedSpecialization = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSkills.map((skill) {
                          bool isSelected = selectedSkills.contains(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedSkills.add(skill);
                                } else {
                                  selectedSkills.remove(skill);
                                }
                              });
                            },
                            selectedColor: const Color(
                              0xFF9C27B0,
                            ).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF9C27B0),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Status: '),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF9C27B0),
                      ),
                      Text(isActive ? 'Active' : 'Inactive'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate email if provided
                if (emailController.text.trim().isNotEmpty &&
                    !_isValidEmail(emailController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid email address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                // Validate phone if provided
                if (phoneController.text.trim().isNotEmpty &&
                    !_isValidPhone(phoneController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid phone number (10 digits)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Allow partial updates - only validate that at least one field has content
                if (nameController.text.trim().isNotEmpty ||
                    emailController.text.trim().isNotEmpty ||
                    phoneController.text.trim().isNotEmpty ||
                    // bioController.text.trim().isNotEmpty ||
                    selectedSkills.isNotEmpty) {
                  _updateInstructor(
                    instructor,
                    nameController.text.trim().isEmpty
                        ? instructor.name
                        : nameController.text.trim(),
                    emailController.text.trim().isEmpty
                        ? instructor.email
                        : emailController.text.trim(),
                    phoneController.text.trim().isEmpty
                        ? instructor.phoneNumber
                        : phoneController.text.trim(),
                    selectedSpecialization,
                    bioController.text.trim().isEmpty
                        ? instructor.bio
                        : bioController.text.trim(),
                    selectedSkills.isEmpty ? instructor.skills : selectedSkills,
                    isActive,
                  );
                  Navigator.pop(context);
                } else {
                  // Show error if all fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill at least one field to update'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateInstructor(
    Instructor instructor,
    String name,
    String email,
    String phone,
    String specialization,
    String bio,
    List<String> skills,
    bool isActive,
  ) async {
    try {
      // Only send fields that the API accepts
      final updateData = {
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'specializations': specialization,
        'skills': skills,
      };

      final result = await ApiService.updateInstructor(
        instructor.id,
        updateData,
      );

      if (result['success'] == true) {
        await _loadInstructors(isRefresh: true);
        await _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to update instructor');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating instructor: $e');
    }
  }

  void _showApproveDialog(Instructor instructor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Instructor'),
        content: Text(
          'Are you sure you want to approve "${instructor.name}"? This will verify their instructor status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approveInstructor(instructor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveInstructor(Instructor instructor) async {
    try {
      // Show loading state
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.verifyUser(instructor.id);

      if (result['success'] == true) {
        // Update the instructor's verification status locally
        setState(() {
          instructor.isVerified = true;
          _isLoading = false;
        });

        // Refresh the list to get updated data from server
        await _loadInstructors(isRefresh: true);
        await _loadStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${instructor.name} approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to approve instructor');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error approving instructor: $e');
    }
  }

  Future<void> _deleteInstructor(Instructor instructor) async {
    try {
      final result = await ApiService.deleteInstructor(instructor.id);

      if (result['success'] == true) {
        await _loadInstructors(isRefresh: true);
        await _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${instructor.name} deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to delete instructor');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting instructor: $e');
    }
  }

  void _showDeleteInstructorDialog(Instructor instructor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Instructor'),
        content: Text(
          'Are you sure you want to delete "${instructor.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteInstructor(instructor);
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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\d{10}$'); // 10 digits only
    return phoneRegex.hasMatch(phone);
  }
}
