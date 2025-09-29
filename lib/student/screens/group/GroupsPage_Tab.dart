import 'package:flutter/material.dart';
import 'GroupChatPage.dart';
import '../../services/favorites_service.dart';
import '../../services/groups_service.dart';
import '../../models/group.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GroupPageTab extends StatefulWidget {
  final String selectedLanguage;

  const GroupPageTab({super.key, required this.selectedLanguage});

  @override
  State<GroupPageTab> createState() => _GroupPageTabState();
}

class _GroupPageTabState extends State<GroupPageTab> {
  final FavoritesService _favoritesService = FavoritesService();
  final GroupsService _groupsService = GroupsService();
  List<Group> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _loadGroups();
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // treat response as dynamic so runtime shape checks work without static type conflicts
      final dynamic response = await _groupsService.getMyGroups();

      // Try to normalize several possible shapes into a List<Group>
      List<Group>? groups;

      // Case 1: service returned a raw List<Group>
      if (response is List<Group>) {
        groups = response;
      }
      // Case 2: service returned an object with `.data` (e.g. ApiResponse<List<Group>>)
      else if (response != null && response.data != null) {
        final data = response.data;
        if (data is List<Group>) {
          groups = data;
        } else if (data is List) {
          // if it's a raw List<dynamic>, try to cast to List<Group>
          groups = data.cast<Group>();
        }
      }
      // Case 3: service returned a Map shape like { data: [...] }
      else if (response is Map && response['data'] is List) {
        groups = (response['data'] as List).cast<Group>();
      }

      if (groups != null) {
        setState(() {
          _groups = groups!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load groups';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading groups: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [
                            const Color.fromARGB(255, 98, 72, 139),
                            const Color.fromARGB(109, 185, 127, 240),
                          ]
                        : [
                            const Color.fromARGB(255, 82, 41, 116),
                            const Color.fromARGB(255, 41, 7, 61),
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                    bottom: 30,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Groups',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Refresh button
                          IconButton(
                            onPressed: _loadGroups,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connect with fellow students and collaborate',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content Section
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, bottom: 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (_error != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadGroups,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ] else if (_groups.isEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.black
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 48,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No groups yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You haven\'t joined any groups yet. Groups will appear here once you join them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Groups List
                  ...(_groups
                      .map(
                        (group) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildGroupListItem(context, group),
                        ),
                      )
                      .toList()),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupListItem(BuildContext context, Group group) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color parseColor(String hexColor, {double opacity = 1.0}) {
      var hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      final value = int.parse(hex, radix: 16);
      return Color(value).withOpacity(opacity);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.black : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.1)
                : Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatPage(group: group.toJson()),
              ),
            );
            if (!mounted) return;
            if (result == 'left') {
              await _loadGroups();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('You left "${group.name}"')),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Group Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        parseColor(group.color ?? '#5F299E'),
                        parseColor(group.color ?? '#5F299E', opacity: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: parseColor(
                          group.color ?? '#5F299E',
                          opacity: 0.3,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (group.name.isNotEmpty ? group.name[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatTime(group.updatedAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group.description.isNotEmpty
                                  ? group.description
                                  : 'No description available',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.75)
                                    : const Color(0xFF6B7280),
                                height: 1.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if ((group.unreadCount ?? 0) > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF5F299E),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                (group.unreadCount ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
