import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/ui_service.dart';

class EventApprovalScreen extends StatefulWidget {
  const EventApprovalScreen({super.key});

  @override
  State<EventApprovalScreen> createState() => _EventApprovalScreenState();
}

class _EventApprovalScreenState extends State<EventApprovalScreen> {
  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _filteredInstructors = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Verified, Unverified
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMoreData = true;

  // Stats
  Map<String, dynamic> _stats = {'total': 0, 'verified': 0, 'unverified': 0};

  // Pagination total from API
  int _totalInstructorsFromAPI = 0;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
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
      });
    }

    setState(() {
      _isLoading = isRefresh ? false : _currentPage == 1;
    });

    try {
      final result = await ApiService.getEventAccounts(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      print('🔍 Event Accounts API Response: $result');

      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        List<Map<String, dynamic>> newInstructors = [];

        // Handle different response structures
        if (data is List) {
          newInstructors = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data['instructors'] != null && data['instructors'] is List) {
            newInstructors = List<Map<String, dynamic>>.from(
              data['instructors'],
            );
          }

          // Handle pagination info
          if (data['pagination'] != null) {
            final pagination = data['pagination'];
            _hasMoreData =
                (pagination['current'] ?? 1) < (pagination['total'] ?? 1);
            _totalInstructorsFromAPI =
                pagination['count'] ?? 0; // Total count from API
          }
        }

        setState(() {
          if (isRefresh || _currentPage == 1) {
            _instructors = newInstructors;
          } else {
            _instructors.addAll(newInstructors);
          }
          _filteredInstructors = List.from(_instructors);
          _isLoading = false;

          // Update pagination
          if (newInstructors.length < _limit) {
            _hasMoreData = false;
          }
        });

        _calculateStats();
        _applyFilters();
      } else {
        setState(() {
          _isLoading = false;
        });
        UiService.showError(result['message'] ?? 'Failed to load instructors');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      UiService.showError('Error loading instructors: $e');
    }
  }

  Future<void> _loadMoreInstructors() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final result = await ApiService.getEventAccounts(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        List<Map<String, dynamic>> newInstructors = [];

        if (data is List) {
          newInstructors = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['instructors'] != null) {
          newInstructors = List<Map<String, dynamic>>.from(data['instructors']);

          if (data['pagination'] != null) {
            final pagination = data['pagination'];
            _hasMoreData =
                (pagination['current'] ?? 1) < (pagination['total'] ?? 1);
            _totalInstructorsFromAPI =
                pagination['count'] ?? 0; // Update total count
          }
        }

        setState(() {
          _instructors.addAll(newInstructors);
          _filteredInstructors = List.from(_instructors);
          _isLoadingMore = false;

          if (newInstructors.length < _limit) {
            _hasMoreData = false;
          }
        });

        _calculateStats();
        _applyFilters();
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revert page increment on error
      });
      print('Error loading more instructors: $e');
    }
  }

  void _calculateStats() {
    // Use total from pagination API, verified/unverified from loaded data
    final verified = _instructors
        .where((instructor) => instructor['isVerified'] == true)
        .length;
    final unverified = _instructors
        .where((instructor) => instructor['isVerified'] != true)
        .length;

    setState(() {
      _stats = {
        'total': _totalInstructorsFromAPI, // Total from pagination
        'verified': verified,
        'unverified': unverified,
      };
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredInstructors = _instructors.where((instructor) {
        // Apply search filter
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          matchesSearch =
              instructor['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              instructor['email'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              instructor['phoneNumber'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
        }

        // Apply verification filter
        bool matchesFilter = true;
        if (_selectedFilter == 'Verified') {
          matchesFilter = instructor['isVerified'] == true;
        } else if (_selectedFilter == 'Unverified') {
          matchesFilter = instructor['isVerified'] != true;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.black;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.black;
    final textColor = isDark ? Colors.black : Colors.white;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.black;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Decide how many cards per row based on screen width
                int crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
                double cardWidth =
                    (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
                    crossAxisCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      'Total Accounts',
                      _stats['total']?.toString() ?? '0',
                      Colors.blue,
                      Icons.people,
                      width: cardWidth,
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      'Verified',
                      _stats['verified']?.toString() ?? '0',
                      Colors.green,
                      Icons.verified,
                      width: cardWidth,
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      'Unverified',
                      _stats['unverified']?.toString() ?? '0',
                      Colors.orange,
                      Icons.pending,
                      width: cardWidth,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ),
          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search event accounts...',
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.search, color: hintColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                    ),
                    style: TextStyle(color: textColor),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    items: ['All', 'Verified', 'Unverified'].map((filter) {
                      return DropdownMenuItem(
                        value: filter,
                        child: Text(filter, style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) _onFilterChanged(value);
                    },
                    dropdownColor: cardColor,
                    icon: Icon(Icons.arrow_drop_down, color: textColor),
                    underline: const SizedBox(), // Remove default underline
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Instructors List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : Colors.blue,
                      ),
                    ),
                  )
                : _filteredInstructors.isEmpty
                ? Center(
                    child: Text(
                      'No event accounts found',
                      style: TextStyle(color: textColor),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        _filteredInstructors.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredInstructors.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.white : Colors.blue,
                              ),
                            ),
                          ),
                        );
                      }

                      final instructor = _filteredInstructors[index];
                      return _buildInstructorCard(instructor, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    double? width,
    required bool isDark,
  }) {
    final cardColor = isDark
        ? const Color(0xFF2e2d2f)
        : const Color(0xFFF6F4FB);
    final textColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorCard(Map<String, dynamic> instructor, bool isDark) {
    final isVerified = instructor['isVerified'] == true;
    final cardColor = isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.white;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isVerified ? Colors.green : Colors.orange,
          child: Text(
            instructor['name']?.toString().substring(0, 1).toUpperCase() ?? 'I',
            style: TextStyle(
              color: isDark ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          instructor['name']?.toString() ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              instructor['email']?.toString() ?? '',
              style: TextStyle(color: subtitleColor),
            ),
            Text(
              instructor['phoneNumber']?.toString() ?? '',
              style: TextStyle(color: subtitleColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Unverified',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVerified)
              Icon(Icons.verified, color: Colors.green)
            else
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _approveInstructor(instructor),
                tooltip: 'Approve',
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textColor),
              onSelected: (String value) {
                if (value == 'view_details') {
                  _showUserDetailsModal(instructor, isDark);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'view_details',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20, color: textColor),
                      const SizedBox(width: 8),
                      Text('View Details', style: TextStyle(color: textColor)),
                    ],
                  ),
                ),
              ],
              color: cardColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveInstructor(Map<String, dynamic> instructor) async {
    try {
      final result = await ApiService.verifyEventAccount(
        instructor['_id'] ?? instructor['id'],
      );

      if (result['success'] == true) {
        UiService.showSuccess('Event account approved successfully');
        _loadInstructors(isRefresh: true);
      } else {
        UiService.showError(
          result['message'] ?? 'Failed to approve event account',
        );
      }
    } catch (e) {
      UiService.showError('Error approving event account: $e');
    }
  }

  void _showUserDetailsModal(Map<String, dynamic> user, bool isDark) {
    final dialogColor = isDark ? const Color(0xFF23232B) : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: dialogColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dialogColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar and close button
                Row(
                  children: [
                    _buildUserAvatar(user),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name']?.toString() ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (user['isVerified'] == true)
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (user['isVerified'] == true)
                                  ? 'Verified'
                                  : 'Unverified',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: textColor),
                      splashRadius: 22,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // User details
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Email and Phone Number
                        _buildTwoColumnRowAlways(
                          'Email',
                          user['email']?.toString(),
                          'Phone Number',
                          user['phoneNumber']?.toString(),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        // Row 2: State and City
                        _buildTwoColumnRowAlways(
                          'State',
                          user['state']?.toString(),
                          'City',
                          user['city']?.toString(),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        // Row 3: Role and Date of Birth
                        _buildTwoColumnRowAlways(
                          'Role',
                          user['role']?.toString(),
                          'Date of Birth',
                          user['dob']?.toString(),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        // Row 4: Skills (full width)
                        _buildDetailRowAlways(
                          'Skills',
                          _formatSkillsAlways(user['skills']),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        // Row 5: Bio (full width)
                        _buildDetailRowAlways(
                          'Bio',
                          user['bio']?.toString(),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        // Row 6: Address (full width)
                        _buildDetailRowAlways(
                          'Address',
                          user['address']?.toString(),
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                if (user['isVerified'] != true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          backgroundColor: isDark
                              ? Colors.grey[850]
                              : Colors.grey[200],
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _approveInstructor(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final isVerified = user['isVerified'] == true;
    final avatarUrl = user['avatar']?.toString();

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Use the base URL from ApiService
      final fullAvatarUrl = avatarUrl.startsWith('http')
          ? avatarUrl
          : '${ApiService.baseUrl}$avatarUrl';

      return CircleAvatar(
        radius: 30,
        backgroundColor: isVerified ? Colors.green : Colors.orange,
        backgroundImage: NetworkImage(fullAvatarUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to initial if image fails to load
        },
        child: avatarUrl.isEmpty
            ? Text(
                user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
      );
    } else {
      return CircleAvatar(
        radius: 30,
        backgroundColor: isVerified ? Colors.green : Colors.orange,
        child: Text(
          user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
    }
  }

  Widget _buildTwoColumnRowAlways(
    String label1,
    String? value1,
    String label2,
    String? value2, {
    required Color textColor,
    required Color subtitleColor,
  }) {
    // Always show both columns, use "NA" for empty values
    String displayValue1 =
        (value1 == null || value1.isEmpty || value1.trim().isEmpty)
        ? 'NA'
        : value1;
    String displayValue2 =
        (value2 == null || value2.isEmpty || value2.trim().isEmpty)
        ? 'NA'
        : value2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: displayValue1 == 'NA' ? subtitleColor : textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // Space between columns
          // Second column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: displayValue2 == 'NA' ? subtitleColor : textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowAlways(
    String label,
    String? value, {
    required Color textColor,
    required Color subtitleColor,
  }) {
    // Always show field, use "NA" for empty values
    String displayValue =
        (value == null || value.isEmpty || value.trim().isEmpty) ? 'NA' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: displayValue == 'NA' ? subtitleColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSkillsAlways(dynamic skills) {
    if (skills == null) return 'NA';
    if (skills is List) {
      if (skills.isEmpty) return 'NA';
      return skills.join(', ');
    }
    String skillsStr = skills.toString().trim();
    return skillsStr.isEmpty ? 'NA' : skillsStr;
  }
}
