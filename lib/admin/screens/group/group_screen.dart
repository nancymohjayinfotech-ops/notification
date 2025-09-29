import 'package:flutter/material.dart';
import "group_detail.dart";
import '../../services/api_service.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String _searchQuery = '';
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _groups = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Add a key to force rebuild of group cards when data changes
  Key _groupListKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreGroups();
    }
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final response = await ApiService.getAllGroups(
        page: 1,
        limit: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: null,
      );

      if (mounted) {
        if (response['success'] == true) {
          final data = response['data'];
          List<dynamic> groups = [];

          if (data is List) {
            groups = data;
          } else if (data['groups'] != null) {
            groups = data['groups'];
          } else if (data['data'] != null) {
            groups = data['data'];
          }

          setState(() {
            _groups = groups;
            _hasMore = groups.length >= 20;
            _currentPage = 1;
            _isLoading = false;
            _groupListKey = UniqueKey(); // Force rebuild of group cards
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load groups';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreGroups() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.getAllGroups(
        page: nextPage,
        limit: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: null,
      );

      if (mounted && response['success'] == true) {
        final data = response['data'];
        List<dynamic> newGroups = [];

        if (data is List) {
          newGroups = data;
        } else if (data['groups'] != null) {
          newGroups = data['groups'];
        } else if (data['data'] != null) {
          newGroups = data['data'];
        }

        setState(() {
          _groups.addAll(newGroups);
          _hasMore = newGroups.length >= 20;
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadGroups();
      }
    });
  }

  List<dynamic> get filteredGroups {
    return _groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: Text('Groups',
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark? Colors.white : Colors.black, fontSize: 24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage and monitor group activities',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onSubmitted: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search groups...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 12 : 16,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _isLoading && _groups.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading groups',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                  ),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loadGroups,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9C27B0),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 16 : 24,
                                      vertical: isMobile ? 8 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredGroups.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          key: _groupListKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _scrollController,
                          itemCount: filteredGroups.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= filteredGroups.length) {
                              return _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _buildGroupCard(filteredGroups[index]);
                          },
                        ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGroupDialog,
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add),
        label: const Text('New Group'),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    String avatar = 'G';
    final groupName =
        group['title']?.toString() ?? group['name']?.toString() ?? '';
    if (groupName.isNotEmpty) {
      final nameParts = groupName.split(' ');
      if (nameParts.length > 1) {
        avatar = '${nameParts[0][0]}${nameParts[1][0]}';
      } else if (nameParts[0].length > 1) {
        avatar = nameParts[0].substring(0, 2);
      } else {
        avatar = nameParts[0][0];
      }
    }

    final color = _generateColor(group['_id'] ?? groupName ?? 'group');

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailPage(
                groupId: group['_id'],
                groupName: group['title'] ?? group['name'] ?? '',
                groupDescription: group['description'] ?? '',
                memberCount: group['memberCount'] ?? 0,
                color: color,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      avatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['title']?.toString() ??
                              group['name']?.toString() ??
                              'Unnamed Group',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _GroupMemberCount(
                          groupId: group['_id'],
                          fallbackCount:
                              group['memberCount']?.toString() ?? '0',
                          key: ValueKey(
                            '${group['_id']}_${_groupListKey.toString()}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(group).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(group),
                      style: TextStyle(
                        color: _getStatusColor(group),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleGroupAction(value, group),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'view_details',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'add_member',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Add Member'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'manage_members',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                SizedBox(width: 8),
                                Text('Manage Members'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
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
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group['description']?.toString() ?? 'No description available',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(group['createdAt'] ?? group['createdDate'])}',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (group['category'] != null)
                    Text(
                      group['category'].toString(),
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
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

  void _showGroupDetailsDialog(Map<String, dynamic> group) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupId = group['_id'] ?? group['id'];

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getGroupDetails(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading group details...'),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!['success'] != true) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(
                snapshot.data?['message'] ?? 'Failed to load group details',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          final groupData = snapshot.data!['data']['group'];
          final stats = snapshot.data!['data']['stats'];
          final membersByRole = snapshot.data!['data']['membersByRole'];

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final dialogWidth = isMobile
                    ? constraints.maxWidth * 0.9
                    : constraints.maxWidth * 0.7;
                final dialogHeight = isMobile
                    ? constraints.maxHeight * 0.9
                    : constraints.maxHeight * 0.8;
                return Container(
                  width: dialogWidth,
                  height: dialogHeight,
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                groupData['name'] ?? 'Group Details',
                                style: TextStyle(
                                  fontSize: isMobile ? 20 : 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 16),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Information',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 6 : 12),
                                _buildInfoRow(
                                  'Group ID',
                                  groupData['_id'] ?? 'N/A',
                                ),
                                _buildInfoRow(
                                  'Name',
                                  groupData['name'] ?? 'N/A',
                                ),
                                _buildInfoRow(
                                  'Description',
                                  groupData['description'] ?? 'No description',
                                ),
                                _buildInfoRow(
                                  'Category',
                                  groupData['category'] ?? 'General',
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 4 : 8,
                                        vertical: isMobile ? 2 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (groupData['isActive'] == true
                                                    ? Colors.green
                                                    : Colors.orange)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        groupData['isActive'] == true
                                            ? 'Active'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color: groupData['isActive'] == true
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                          fontSize: isMobile ? 10 : 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 4 : 8),
                                _buildInfoRow(
                                  'Created At',
                                  _formatDateTime(groupData['createdAt']),
                                ),
                                _buildInfoRow(
                                  'Updated At',
                                  _formatDateTime(groupData['updatedAt']),
                                ),
                                if (groupData['deletedAt'] != null)
                                  _buildInfoRow(
                                    'Deleted At',
                                    _formatDateTime(groupData['deletedAt']),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 16),
                        if (groupData['admin'] != null) ...[
                          Text(
                            'Group Admin',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 8),
                          Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    groupData['admin']['avatar'] != null
                                    ? NetworkImage(groupData['admin']['avatar'])
                                    : null,
                                backgroundColor: const Color(0xFF9C27B0),
                                child: groupData['admin']['avatar'] == null
                                    ? Text(
                                        (groupData['admin']['name']
                                                    ?.toString() ??
                                                'A')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                groupData['admin']['name'] ?? 'Unknown Admin',
                              ),
                              subtitle: Text(groupData['admin']['email'] ?? ''),
                              trailing: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 20),
                        ],
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Statistics',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 8 : 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmallScreen =
                                        constraints.maxWidth < 400;
                                    return Wrap(
                                      spacing: isMobile ? 6.0 : 12.0,
                                      runSpacing: isMobile ? 6.0 : 12.0,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _buildStatCard(
                                          'Total Members',
                                          stats['totalMembers']?.toString() ??
                                              '0',
                                          Icons.group,
                                          Colors.purple,
                                          isMobile: isMobile,
                                        ),
                                        _buildStatCard(
                                          'Instructors',
                                          stats['instructors']?.toString() ??
                                              '0',
                                          Icons.school,
                                          Colors.blue,
                                          isMobile: isMobile,
                                        ),
                                        _buildStatCard(
                                          'Events',
                                          stats['events']?.toString() ?? '0',
                                          Icons.event,
                                          Colors.green,
                                          isMobile: isMobile,
                                        ),
                                        _buildStatCard(
                                          'Students',
                                          stats['students']?.toString() ?? '0',
                                          Icons.person,
                                          Colors.green,
                                          isMobile: isMobile,
                                        ),
                                        _buildStatCard(
                                          'Messages',
                                          stats['totalMessages']?.toString() ??
                                              '0',
                                          Icons.message,
                                          Colors.orange,
                                          isMobile: isMobile,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 16),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Members',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 8 : 16),
                                SizedBox(
                                  height: isMobile ? 300 : 400,
                                  child: DefaultTabController(
                                    length: 3,
                                    child: Column(
                                      children: [
                                        const TabBar(
                                          labelColor: Color(0xFF9C27B0),
                                          unselectedLabelColor: Colors.grey,
                                          indicatorColor: Color(0xFF9C27B0),
                                          tabs: [
                                            Tab(text: 'Instructors'),
                                            Tab(text: 'Students'),
                                            Tab(text: 'Events'),
                                          ],
                                        ),
                                        SizedBox(height: isMobile ? 8 : 16),
                                        Expanded(
                                          child: TabBarView(
                                            children: [
                                              _buildDetailedMembersList(
                                                membersByRole['instructors'] ??
                                                    [],
                                                groupId,
                                                'instructor',
                                              ),
                                              _buildDetailedMembersList(
                                                membersByRole['students'] ?? [],
                                                groupId,
                                                'student',
                                              ),
                                              _buildDetailedMembersList(
                                                membersByRole['events'] ?? [],
                                                groupId,
                                                'event',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 16),
                        if (snapshot.data!['data']['messages'] != null) ...[
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 8 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recent Messages',
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 6 : 12),
                                  if (snapshot
                                      .data!['data']['messages']['data']
                                      .isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          'No messages yet',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    ...snapshot
                                        .data!['data']['messages']['data']
                                        .map<Widget>(
                                          (message) => ListTile(
                                            title: Text(
                                              message['content'] ?? 'Message',
                                            ),
                                            subtitle: Text(
                                              message['sender'] ??
                                                  'Unknown sender',
                                            ),
                                            trailing: Text(
                                              _formatDateTime(
                                                message['createdAt'],
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 8 : 12,
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _generateColor(String input) {
    int hash = input.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.8, 0.7).toColor();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      if (date is String) {
        final dateTime = DateTime.tryParse(date);
        if (dateTime != null) {
          return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        }
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _getStatusText(Map<String, dynamic> group) {
    if (group['status'] != null) {
      if (group['status'] is bool) {
        return group['status'] == true ? 'Active' : 'Inactive';
      }
      final status = group['status'].toString().toLowerCase();
      if (status == 'true' || status == 'active') return 'Active';
      if (status == 'false' || status == 'inactive') return 'Inactive';
      return group['status'].toString();
    }

    if (group['isActive'] != null) {
      if (group['isActive'] is bool) {
        return group['isActive'] ? 'Active' : 'Inactive';
      }
      return group['isActive'].toString() == 'true' ? 'Active' : 'Inactive';
    }

    return 'Inactive';
  }

  Color _getStatusColor(Map<String, dynamic> group) {
    final statusText = _getStatusText(group);
    return statusText == 'Active' ? Colors.green : Colors.orange;
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off_outlined
                      : Icons.group_off_outlined,
                  size: isMobile ? 48 : 72,
                  color: Colors.grey[300],
                ),
                SizedBox(height: isMobile ? 12 : 24),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No matching groups found'
                      : 'No groups found',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 6 : 12),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24.0,
                  ),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term or clear the search to see all groups.'
                        : 'Get started by creating a new group to organize your members.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isMobile ? 12 : 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  SizedBox(height: isMobile ? 12 : 24),
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9C27B0),
                      side: const BorderSide(color: Color(0xFF9C27B0)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 24,
                        vertical: isMobile ? 6 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clear Search'),
                  ),
                ] else ...[
                  SizedBox(height: isMobile ? 16 : 32),
                  ElevatedButton(
                    onPressed: _showAddGroupDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 32,
                        vertical: isMobile ? 8 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Create New Group',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleGroupAction(String action, Map<String, dynamic> group) {
    switch (action) {
      case 'view_details':
        _showGroupDetailsDialog(group);
        break;
      case 'edit':
        _showEditGroupDialog(group);
        break;
      case 'add_member':
        _showAddMemberDialog(group);
        break;
      case 'manage_members':
        _showManageMembersDialog(group);
        break;
      case 'delete':
        _showDeleteGroupDialog(group);
        break;
    }
  }

  Future<void> _showAddGroupDialog() async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isCreating = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Container(
                width: isMobile
                    ? constraints.maxWidth * 0.9
                    : constraints.maxWidth * 0.7,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                color: isDark
                    ? Colors.black
                    : Colors.white, // Set background color to white
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create New Group',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Group Name *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: categoryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Category *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.category),
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                if (!isMobile) const SizedBox(width: 12),
                                if (!isMobile)
                                  Expanded(
                                    child: TextField(
                                      controller: descriptionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Description *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.description),
                                        labelStyle: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (isMobile) ...[
                              SizedBox(height: isMobile ? 8 : 12),
                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isCreating
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          onPressed: isCreating
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty ||
                                      categoryController.text.trim().isEmpty ||
                                      descriptionController.text
                                          .trim()
                                          .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in all required fields',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isCreating = true);

                                  try {
                                    final response =
                                        await ApiService.createGroup(
                                          name: nameController.text.trim(),
                                          category: categoryController.text
                                              .trim(),
                                          description: descriptionController
                                              .text
                                              .trim(),
                                        );

                                    if (response['success'] == true) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Group "${nameController.text}" created successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadGroups();
                                    } else {
                                      setDialogState(() => isCreating = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response['message'] ??
                                                'Failed to create group',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isCreating = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error creating group: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('CREATE'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditGroupDialog(Map<String, dynamic> group) {
    final groupName =
        group['title']?.toString() ?? group['name']?.toString() ?? '';
    final nameController = TextEditingController(text: groupName);
    final descriptionController = TextEditingController(
      text: group['description']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: group['category']?.toString() ?? '',
    );
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Container(
                width: isMobile
                    ? constraints.maxWidth * 0.9
                    : constraints.maxWidth * 0.8,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit $groupName',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Group Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isUpdating
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: isUpdating
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty ||
                                      descriptionController.text
                                          .trim()
                                          .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in all required fields',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isUpdating = true);

                                  try {
                                    final groupId = group['_id'] ?? group['id'];
                                    final response =
                                        await ApiService.updateGroup(
                                          groupId: groupId,
                                          name: nameController.text.trim(),
                                          description: descriptionController
                                              .text
                                              .trim(),
                                          category:
                                              categoryController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? categoryController.text.trim()
                                              : null,
                                        );

                                    if (response['success'] == true) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${nameController.text} updated successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadGroups();
                                    } else {
                                      setDialogState(() => isUpdating = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response['message'] ??
                                                'Failed to update group',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isUpdating = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error updating group: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                          ),
                          child: isUpdating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showManageMembersDialog(Map<String, dynamic> group) async {
    final groupName =
        group['title']?.toString() ?? group['name']?.toString() ?? 'Group';
    final groupId = group['_id'] ?? group['id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Function to refresh the dialog data
          void refreshDialog() {
            setDialogState(() {
              // This will trigger a rebuild of the FutureBuilder
            });
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getGroupDetails(groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Dialog(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading group details...'),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!['success'] != true) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(
                    snapshot.data?['message'] ?? 'Failed to load group details',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              }

              final groupData = snapshot.data!['data']['group'];
              final stats = snapshot.data!['data']['stats'];
              final membersByRole = snapshot.data!['data']['membersByRole'];

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final dialogWidth = isMobile
                        ? constraints.maxWidth * 0.9
                        : constraints.maxWidth * 0.9;
                    final dialogHeight = isMobile
                        ? constraints.maxHeight * 0.85
                        : constraints.maxHeight * 0.8;
                    return Container(
                      width: dialogWidth,
                      height: dialogHeight,
                      padding: EdgeInsets.all(isMobile ? 12 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupData['name'] ?? groupName,
                                      style: TextStyle(
                                        fontSize: isMobile ? 18 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: isMobile ? 2 : 4),
                                    Text(
                                      'Total: ${stats['totalMembers']} members',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 8 : 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Instructors',
                                  stats['instructors']?.toString() ?? '0',
                                  Icons.school,
                                  Colors.blue,
                                  isMobile: isMobile,
                                ),
                              ),
                              SizedBox(width: isMobile ? 6 : 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Students',
                                  stats['students']?.toString() ?? '0',
                                  Icons.person,
                                  Colors.green,
                                  isMobile: isMobile,
                                ),
                              ),
                              SizedBox(width: isMobile ? 6 : 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Events',
                                  stats['events']?.toString() ?? '0',
                                  Icons.event,
                                  Colors.green,
                                  isMobile: isMobile,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 12 : 20),
                          Expanded(
                            child: DefaultTabController(
                              length: 3,
                              child: Column(
                                children: [
                                  const TabBar(
                                    labelColor: Color(0xFF9C27B0),
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Color(0xFF9C27B0),
                                    tabs: [
                                      Tab(text: 'Instructors'),
                                      Tab(text: 'Students'),
                                      Tab(text: 'Events'),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 8 : 16),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _buildMembersList(
                                          membersByRole['instructors'] ?? [],
                                          groupId,
                                          'instructor',
                                          onRefresh: refreshDialog,
                                        ),
                                        _buildMembersList(
                                          membersByRole['students'] ?? [],
                                          groupId,
                                          'student',
                                          onRefresh: refreshDialog,
                                        ),
                                        _buildMembersList(
                                          membersByRole['events'] ?? [],
                                          groupId,
                                          'event',
                                          onRefresh: refreshDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 18 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    List<dynamic> members,
    String groupId,
    String role, {
    VoidCallback? onRefresh,
  }) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role == 'instructor'
                  ? Icons.school
                  : role == 'event'
                  ? Icons.event
                  : Icons.person,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              role == 'event' ? 'No events in this group' : 'No ${role}s yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (role != 'event' && member['avatar'] != null)
                  ? NetworkImage(member['avatar'])
                  : null,
              backgroundColor: role == 'event'
                  ? Colors.orange
                  : const Color(0xFF9C27B0),
              child:
                  (role != 'event' && member['avatar'] == null) ||
                      role == 'event'
                  ? Icon(
                      role == 'event' ? Icons.event : Icons.person,
                      color: Colors.white,
                      size: role == 'event' ? 20 : 24,
                    )
                  : (role != 'event' && member['avatar'] == null)
                  ? Text(
                      (member['name']?.toString() ??
                              member['title']?.toString() ??
                              'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              role == 'event'
                  ? (member['title']?.toString() ??
                        member['name']?.toString() ??
                        'Unknown Event')
                  : (member['name']?.toString() ?? 'Unknown User'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role == 'event') ...[
                  if (member['description'] != null)
                    Text(
                      member['description'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (member['startDate'] != null)
                    Text(
                      'Start: ${_formatDateTime(member['startDate'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ] else ...[
                  Text(member['email']?.toString() ?? ''),
                  if (member['phoneNumber'] != null)
                    Text(
                      member['phoneNumber'].toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveMemberDialog(
                    member,
                    groupId,
                    onMemberRemoved: onRefresh,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveMemberDialog(
    Map<String, dynamic> member,
    String groupId, {
    VoidCallback? onMemberRemoved,
  }) {
    bool isRemoving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Container(
                width: isMobile
                    ? constraints.maxWidth * 0.9
                    : constraints.maxWidth * 0.4,
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Remove Member',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Are you sure you want to remove "${member['name']}" from this group?',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 12 : 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isRemoving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: isRemoving
                              ? null
                              : () async {
                                  setDialogState(() => isRemoving = true);

                                  try {
                                    print(
                                      'DEBUG: Attempting to remove member ${member['_id']} from group $groupId',
                                    );
                                    print('DEBUG: Member data: $member');

                                    final response =
                                        await ApiService.removeMemberFromGroup(
                                          groupId: groupId,
                                          memberId: member['_id'],
                                          role: member['role']?.toString(),
                                        );

                                    print('DEBUG: API Response: $response');

                                    if (response['success'] == true) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${member['name']} removed from group successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      await _loadGroups();
                                      // Call the refresh callback to update the dialog
                                      if (onMemberRemoved != null) {
                                        onMemberRemoved();
                                      }
                                    } else {
                                      setDialogState(() => isRemoving = false);
                                      print(
                                        'DEBUG: API call failed with response: $response',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response['message'] ??
                                                'Failed to remove member. Please check console for details.',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isRemoving = false);
                                    print('DEBUG: Exception occurred: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error removing member: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: isRemoving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddMemberDialog(Map<String, dynamic> group) {
    final groupName =
        group['title']?.toString() ?? group['name']?.toString() ?? 'Group';
    final groupId = group['_id'] ?? group['id'];
    final searchController = TextEditingController();

    List<Map<String, dynamic>> availableUsers = [];
    Map<String, List<Map<String, dynamic>>> selectedUsersByRole = {
      'instructor': [],
      'student': [],
      'event': [],
    };
    bool isLoading = false;
    bool isAddingMembers = false;
    String selectedRole = 'instructor';

    final roles = [
      {'value': 'instructor', 'label': 'Instructor'},
      {'value': 'student', 'label': 'Student'},
      {'value': 'event', 'label': 'Event'},
    ];

    List<Map<String, dynamic>> getAllSelectedUsers() {
      List<Map<String, dynamic>> allSelected = [];
      for (var users in selectedUsersByRole.values) {
        allSelected.addAll(users);
      }
      return allSelected;
    }

    Future<void> loadUsers([String? search]) async {
      if (!mounted) return;

      final response = await ApiService.getAvailableUsers(
        role: selectedRole,
        search: search,
        groupId: groupId,
      );

      if (response['success'] == true && response['data'] != null) {
        availableUsers = List<Map<String, dynamic>>.from(response['data']);
      } else {
        availableUsers = [];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final dialogWidth = isMobile
                  ? constraints.maxWidth * 0.9
                  : constraints.maxWidth * 0.7;
              final dialogHeight = isMobile
                  ? constraints.maxHeight * 0.85
                  : constraints.maxHeight * 0.6;
              return Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    Text(
                      'Add Members to $groupName',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'User Role',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                        contentPadding: EdgeInsets.all(isMobile ? 8 : 12),
                      ),
                      items: roles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role['value'],
                              child: Text(role['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        setDialogState(() {
                          selectedRole = value!;
                          isLoading = true;
                        });
                        await loadUsers(
                          searchController.text.trim().isNotEmpty
                              ? searchController.text.trim()
                              : null,
                        );
                        setDialogState(() => isLoading = false);
                      },
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search users...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () async {
                                  searchController.clear();
                                  setDialogState(() => isLoading = true);
                                  await loadUsers();
                                  setDialogState(() => isLoading = false);
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.all(isMobile ? 8 : 12),
                      ),
                      onChanged: (value) async {
                        setDialogState(() => isLoading = true);
                        await loadUsers(
                          value.trim().isNotEmpty ? value.trim() : null,
                        );
                        setDialogState(() => isLoading = false);
                      },
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    if (getAllSelectedUsers().isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${getAllSelectedUsers().length} user(s) selected',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                            SizedBox(height: isMobile ? 2 : 4),
                            ...selectedUsersByRole.entries
                                .where((entry) => entry.value.isNotEmpty)
                                .map(
                                  (entry) => Text(
                                    '${entry.value.length} ${entry.key}${entry.value.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : availableUsers.isEmpty
                          ? const Center(
                              child: Text(
                                'No users found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: availableUsers.length,
                              itemBuilder: (context, index) {
                                final user = availableUsers[index];
                                final isSelected =
                                    selectedUsersByRole[selectedRole]!.any(
                                      (u) => u['_id'] == user['_id'],
                                    );

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        final userWithRole =
                                            Map<String, dynamic>.from(user);
                                        userWithRole['role'] = selectedRole;
                                        selectedUsersByRole[selectedRole]!.add(
                                          userWithRole,
                                        );
                                      } else {
                                        selectedUsersByRole[selectedRole]!
                                            .removeWhere(
                                              (u) => u['_id'] == user['_id'],
                                            );
                                      }
                                    });
                                  },
                                  title: Text(
                                    user['name']?.toString() ?? 'Unknown User',
                                  ),
                                  subtitle: Text(
                                    user['email']?.toString() ?? '',
                                  ),
                                  secondary: CircleAvatar(
                                    child: Text(
                                      (user['name']?.toString() ?? 'U')[0]
                                          .toUpperCase(),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isAddingMembers
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed:
                              isAddingMembers || getAllSelectedUsers().isEmpty
                              ? null
                              : () async {
                                  setDialogState(() => isAddingMembers = true);

                                  try {
                                    final allSelectedUsers =
                                        getAllSelectedUsers();
                                    final members = allSelectedUsers
                                        .map(
                                          (user) => {
                                            'userId': user['_id'].toString(),
                                            'role': user['role'] ?? 'student',
                                          },
                                        )
                                        .toList();
                                    final response =
                                        await ApiService.addMembersToGroup(
                                          groupId: groupId,
                                          members: members,
                                        );

                                    if (response['success'] == true) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${allSelectedUsers.length} member(s) added to $groupName',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadGroups();
                                    } else {
                                      setDialogState(
                                        () => isAddingMembers = false,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response['message'] ??
                                                'Failed to add members',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(
                                      () => isAddingMembers = false,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error adding members: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                          ),
                          child: isAddingMembers
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Add ${getAllSelectedUsers().length} Member(s)',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).then((_) {
      Future.microtask(() async {
        if (mounted) {
          await loadUsers();
        }
      });
    });
  }

  void _showDeleteGroupDialog(Map<String, dynamic> group) {
    final groupName =
        group['title']?.toString() ?? group['name']?.toString() ?? 'this group';
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Container(
                width: isMobile
                    ? constraints.maxWidth * 0.9
                    : constraints.maxWidth * 0.4,
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Delete Group',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Are you sure you want to delete "$groupName"? This action cannot be undone.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 12 : 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  setDialogState(() => isDeleting = true);

                                  try {
                                    final groupId = group['_id'] ?? group['id'];
                                    final response =
                                        await ApiService.deleteGroup(groupId);

                                    if (response['success'] == true) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$groupName updated successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadGroups();
                                    } else {
                                      setDialogState(() => isDeleting = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response['message'] ??
                                                'Failed to delete group',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isDeleting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error deleting group: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildDetailedMembersList(
    List<dynamic> members,
    String groupId,
    String role,
  ) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role == 'instructor'
                  ? Icons.school
                  : role == 'event'
                  ? Icons.event
                  : Icons.person,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              role == 'event'
                  ? 'No events in this group'
                  : 'No ${role}s in this group',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _generateColor(member['name'] ?? 'Unknown'),
              child: Text(
                (member['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['email'] ?? 'No email'),
                if (member['phone'] != null) Text('Phone: ${member['phone']}'),
                if (member['joinedAt'] != null)
                  Text('Joined: ${_formatDateTime(member['joinedAt'])}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveMemberDialog(
                    member,
                    groupId,
                    onMemberRemoved: () {
                      // This is in the detailed members list, we need to refresh the parent dialog
                      Navigator.pop(context); // Close the detailed view
                      _showManageMembersDialog({
                        '_id': groupId,
                        'name': 'Group',
                      }); // Reopen the manage dialog
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Group'),
                    ],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _GroupMemberCount extends StatefulWidget {
  final String groupId;
  final String fallbackCount;

  const _GroupMemberCount({
    Key? key,
    required this.groupId,
    required this.fallbackCount,
  }) : super(key: key);

  @override
  State<_GroupMemberCount> createState() => _GroupMemberCountState();
}

class _GroupMemberCountState extends State<_GroupMemberCount> {
  String? _memberCount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberCount();
  }

  @override
  void didUpdateWidget(_GroupMemberCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when the key changes (indicating data should be refreshed)
    if (oldWidget.key != widget.key) {
      _loadMemberCount();
    }
  }

  Future<void> _loadMemberCount() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getGroupDetails(widget.groupId);
      if (mounted && response['success'] == true) {
        final stats = response['data']['stats'];
        final totalMembers = stats['totalMembers'] ?? 0;
        setState(() {
          _memberCount = totalMembers.toString();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _memberCount = widget.fallbackCount;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _memberCount = widget.fallbackCount;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _isLoading
          ? '${widget.fallbackCount} members'
          : '${_memberCount ?? widget.fallbackCount} members',
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
    );
  }
}
