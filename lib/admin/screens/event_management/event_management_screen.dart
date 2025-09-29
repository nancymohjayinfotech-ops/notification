import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/event.dart';
import 'add_edit_event_screen.dart';
import 'event_details_screen.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  EventCategory? _selectedCategoryFilter;
  EventMode? _selectedModeFilter;

  // Event stats from API
  bool _isLoadingStats = false;
  Map<String, dynamic>?
  _eventStats; // { totalEvents, upcomingEvents, totalAttendance, totalRevenue }

  // Events loaded from API
  final List<Event> _events = [];
  bool _isLoadingEvents = false;

  // Pagination
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  final int _limit = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<Event> get filteredEvents {
    List<Event> filtered = _events;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            event.venue.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((event) => event.category == _selectedCategoryFilter)
          .toList();
    }

    // Apply mode filter
    if (_selectedModeFilter != null) {
      filtered = filtered
          .where((event) => event.mode == _selectedModeFilter)
          .toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _fetchEventStats();
    _fetchEvents(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchEventStats() async {
    print('DEBUG: _fetchEventStats called');
    setState(() {
      _isLoadingStats = true;
    });
    print('DEBUG: Calling getEventStats API...');
    final result = await ApiService.getEventStats();
    print('DEBUG: getEventStats result: $result');
    if (mounted) {
      setState(() {
        _isLoadingStats = false;
        if (result['success'] == true &&
            result['data'] is Map<String, dynamic>) {
          _eventStats = result['data'] as Map<String, dynamic>;
          print('DEBUG: Event stats updated: $_eventStats');
        } else {
          _eventStats = null; // keep using static fallback
          print('DEBUG: Event stats failed, using fallback');
        }
      });
    } else {
      print('DEBUG: Widget not mounted, skipping stats update');
    }
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoadingEvents) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchEvents(reset: false);
    }
  }

  Future<void> _fetchEvents({required bool reset}) async {
    print('DEBUG: _fetchEvents called with reset=$reset');
    if (reset) {
      print('DEBUG: Resetting events list and pagination');
      setState(() {
        _isLoadingEvents = true;
        _page = 1;
        _hasMore = true;
        _events.clear();
      });
    } else {
      print('DEBUG: Loading more events (pagination)');
      setState(() {
        _isLoadingMore = true;
      });
    }

    final result = await ApiService.getAllEvents(
      page: _page,
      limit: _limit,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    print('DEBUG: getAllEvents result: $result');
    if (!mounted) return;
    if (result['success'] == true && result['data'] != null) {
      // Accept either { data: { events: [...] }} or { data: [...] }
      List<dynamic> eventsJson = [];
      final data = result['data'];
      print('DEBUG: data type: ${data.runtimeType}, data: $data');
      if (data is Map<String, dynamic> && data['events'] is List) {
        eventsJson = List<dynamic>.from(data['events'] as List);
        print('DEBUG: Found events in data.events: ${eventsJson.length}');
      } else if (data is List) {
        eventsJson = List<dynamic>.from(data);
        print('DEBUG: Found events in data directly: ${eventsJson.length}');
      } else {
        print('DEBUG: No events found in data structure');
      }
      final List<Event> mapped = [];
      for (int i = 0; i < eventsJson.length; i++) {
        final e = eventsJson[i] as Map<String, dynamic>;
        // Combine startDate and startTime into one DateTime
        DateTime dateTime;
        try {
          final DateTime base = DateTime.parse(e['startDate']);
          final String? startTime = e['startTime'];
          if (startTime != null && startTime.isNotEmpty) {
            final parts = startTime.split(':');
            final int hour = int.tryParse(parts[0]) ?? 0;
            final int minute = int.tryParse(parts[1]) ?? 0;
            dateTime = DateTime(base.year, base.month, base.day, hour, minute);
          } else {
            dateTime = base;
          }
        } catch (_) {
          dateTime = DateTime.now();
        }

        // Map category and mode
        EventCategory category;
        switch ((e['category'] ?? '').toString()) {
          case 'workshop':
            category = EventCategory.workshop;
            break;
          case 'seminar':
            category = EventCategory.seminar;
            break;
          case 'conference':
            category = EventCategory.conference;
            break;
          case 'training':
            category = EventCategory.training;
            break;
          case 'webinar':
            category = EventCategory.webinar;
            break;
          case 'meeting':
            category = EventCategory.meeting;
            break;
          case 'networking':
            category = EventCategory.networking;
            break;
          default:
            category = EventCategory.other;
            break;
        }

        EventMode mode;
        switch ((e['eventType'] ?? '').toString()) {
          case 'online':
            mode = EventMode.online;
            break;
          case 'offline':
            mode = EventMode.offline;
            break;
          case 'hybrid':
            mode = EventMode.hybrid;
            break;
          default:
            mode = EventMode.offline;
            break;
        }

        final int currentAttendees = (e['enrollments'] is List)
            ? (e['enrollments'] as List).length
            : 0;

        final backendId = (e['_id'] ?? e['id'] ?? '').toString();
        mapped.add(
          Event(
            id: backendId, // Use backend ID directly as the event ID
            title: (e['title'] ?? '').toString(),
            description: (e['description'] ?? '').toString(),
            venue: (e['location'] ?? '').toString(),
            dateTime: dateTime,
            maxAttendees: (e['maxParticipants'] ?? 0) is int
                ? e['maxParticipants'] as int
                : int.tryParse((e['maxParticipants'] ?? '0').toString()) ?? 0,
            price: (e['price'] == null) ? null : (e['price'] as num).toDouble(),
            contactEmail: null,
            contactPhone: null,
            meetingLink: null,
            tags: (e['tags'] is List)
                ? List<String>.from(e['tags'])
                : <String>[],
            mode: mode,
            category: category,
            resources: const <String>[],
            imageUrl: (e['images'] is List && (e['images'] as List).isNotEmpty)
                ? (e['images'] as List).first.toString()
                : null,
            createdAt:
                DateTime.tryParse((e['createdAt'] ?? '').toString()) ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse((e['updatedAt'] ?? '').toString()) ??
                DateTime.now(),
            currentAttendees: currentAttendees,
          ),
        );
      }
      print('DEBUG: Mapped ${mapped.length} events');

      if (mounted) {
        print('DEBUG: About to update state with ${mapped.length} events');
        print('DEBUG: Current events count before update: ${_events.length}');
        setState(() {
          if (reset) {
            print('DEBUG: Clearing events list (reset=true)');
            _events.clear();
          }
          _events.addAll(mapped);
          _isLoadingEvents = false;
          _isLoadingMore = false;
          // hasMore: if returned less than limit, no more pages
          final int returned = eventsJson.length;
          if (returned < _limit) {
            _hasMore = false;
          } else {
            _page += 1;
            _hasMore = true;
          }
        });
        print('DEBUG: State updated. New events count: ${_events.length}');
      } else {
        print('DEBUG: Widget not mounted, skipping state update');
      }
    } else {
      print('DEBUG: API call failed: ${result['message']}');
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _isLoadingMore = false;
        });
        if (result['message'] != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'].toString())));
        }
      }
    }
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
                  'Event Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create, manage and monitor events',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Cards - 2x2 Grid
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Events',
                        '${_eventStats?['totalEvents'] ?? _events.length}',
                        Icons.event,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Upcoming',
                        '${_eventStats?['upcomingEvents'] ?? _events.where((e) => e.dateTime.isAfter(DateTime.now())).length}',
                        Icons.schedule,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Attendees',
                        '${_eventStats?['totalAttendance'] ?? _events.fold(0, (sum, event) => sum + event.currentAttendees)}',
                        Icons.people,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Revenue',
                        _eventStats != null
                            ? '₹${_eventStats!['totalRevenue']}'
                            : '₹${_events.fold(0.0, (sum, event) => sum + ((event.price ?? 0) * event.currentAttendees)).toStringAsFixed(0)}',
                        Icons.attach_money,
                        const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filter Section
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2e2d2f)
                          : const Color(0xFFF6F4FB),
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.grey : Colors.white,
                        ),
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
                Expanded(
                  child: _buildFilterDropdown(
                    'Category',
                    _selectedCategoryFilter?.displayName ?? 'All Categories',
                    () => _showCategoryFilter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    'Mode',
                    _selectedModeFilter?.displayName ?? 'All Modes',
                    () => _showModeFilter(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Events List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2e2d2f)
                      : const Color(0xFFF6F4FB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2e2d2f)
                            : const Color(0xFFF6F4FB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Text(
                              'Event',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Date & Time',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // Expanded(flex: 2, child: Text('Attendees', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Actions',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Events List
                    Expanded(
                      child: _isLoadingEvents
                          ? const Center(child: CircularProgressIndicator())
                          : filteredEvents.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () async {
                                await Future.wait([
                                  _fetchEvents(reset: true),
                                  _fetchEventStats(),
                                ]);
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount:
                                    filteredEvents.length +
                                    (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_isLoadingMore &&
                                      index == filteredEvents.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final event = filteredEvents[index];
                                  return _buildEventRow(event);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddEvent(),
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Create Event'),
          elevation: 8,
        ),
      ),
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
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventRow(Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUpcoming = event.dateTime.isAfter(DateTime.now());
    // final attendancePercentage = (event.currentAttendees / event.maxAttendees * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Event Info
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: event.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        event.category.displayName,
                        style: TextStyle(
                          color: event.category.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (event.price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '₹${event.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.venue,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Date & Time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd').format(event.dateTime),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(event.dateTime),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          // Attendees - Commented out
          // Expanded(
          //   flex: 2,
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         '${event.currentAttendees}/${event.maxAttendees}',
          //         style: const TextStyle(
          //           fontWeight: FontWeight.w500,
          //           fontSize: 11,
          //         ),
          //       ),
          //       const SizedBox(height: 3),
          //       LinearProgressIndicator(
          //         value: event.currentAttendees / event.maxAttendees,
          //         backgroundColor: Colors.grey[200],
          //         valueColor: AlwaysStoppedAnimation<Color>(
          //           attendancePercentage >= 80
          //               ? const Color(0xFFF44336)
          //               : attendancePercentage >= 60
          //                   ? const Color(0xFFFF9800)
          //                   : const Color(0xFF4CAF50),
          //         ),
          //         minHeight: 3,
          //       ),
          //     ],
          //   ),
          // ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isUpcoming ? 'Up' : 'Past',
                style: TextStyle(
                  color: isUpcoming
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 50,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
              onSelected: (value) => _handleEventAction(value, event),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Color(0xFF9C27B0)),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Color(0xFFF44336)),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 16,
                        color: Color(0xFF2196F3),
                      ),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first event to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddEvent(),
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEventScreen(
          onSave: (event) {
            // This will be called when the form is saved
          },
        ),
      ),
    );

    // Refresh data when returning from add/edit screen
    if (result == true || result == 'success') {
      await Future.wait([_fetchEvents(reset: true), _fetchEventStats()]);
    }
  }

  void _handleEventAction(String action, Event event) {
    switch (action) {
      case 'edit':
        _navigateToEditEvent(event);
        break;
      case 'delete':
        _showDeleteDialog(event);
        break;
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(eventId: event.id),
          ),
        );
        break;
    }
  }

  void _navigateToEditEvent(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEventScreen(
          event: event,
          onSave: (updatedEvent) {
            // This will be called when the form is saved
          },
        ),
      ),
    );

    // Refresh data when returning from edit screen
    if (result == true || result == 'success') {
      await Future.wait([_fetchEvents(reset: true), _fetchEventStats()]);
    }
  }

  void _showDeleteDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              print('DEBUG: Starting delete for event ID: ${event.id}');

              // Show loading state
              setState(() {
                _isLoadingEvents = true;
              });

              print('DEBUG: Calling deleteEvent API...');
              final res = await ApiService.deleteEvent(event.id);
              print('DEBUG: Delete API response: $res');

              if (mounted) {
                if (res['success'] == true) {
                  print('DEBUG: Delete successful, refreshing data...');

                  // Refresh both events and stats FIRST
                  print('DEBUG: Calling _fetchEvents(reset: true)...');
                  try {
                    await _fetchEvents(reset: true);
                    print('DEBUG: _fetchEvents completed successfully');
                  } catch (e) {
                    print('DEBUG: _fetchEvents failed: $e');
                  }

                  print('DEBUG: Calling _fetchEventStats()...');
                  try {
                    await _fetchEventStats();
                    print('DEBUG: _fetchEventStats completed successfully');
                  } catch (e) {
                    print('DEBUG: _fetchEventStats failed: $e');
                  }
                  print('DEBUG: Refresh completed');

                  // Show success message AFTER refresh
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  print('DEBUG: Delete failed: ${res['message']}');
                  setState(() {
                    _isLoadingEvents = false;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res['message']?.toString() ??
                              'Failed to delete event',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                print('DEBUG: Widget not mounted, skipping UI updates');
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

  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Categories'),
              onTap: () {
                setState(() {
                  _selectedCategoryFilter = null;
                });
                Navigator.pop(context);
              },
              selected: _selectedCategoryFilter == null,
            ),
            ...EventCategory.values.map(
              (category) => ListTile(
                title: Text(category.displayName),
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = category;
                  });
                  Navigator.pop(context);
                },
                selected: _selectedCategoryFilter == category,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Modes'),
              onTap: () {
                setState(() {
                  _selectedModeFilter = null;
                });
                Navigator.pop(context);
              },
              selected: _selectedModeFilter == null,
            ),
            ...EventMode.values.map(
              (mode) => ListTile(
                title: Text(mode.displayName),
                leading: Icon(mode.icon, size: 20),
                onTap: () {
                  setState(() {
                    _selectedModeFilter = mode;
                  });
                  Navigator.pop(context);
                },
                selected: _selectedModeFilter == mode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
