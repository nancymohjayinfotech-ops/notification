// ignore_for_file: unused_field, unused_element
import 'package:flutter/material.dart';
import 'package:fluttertest/event/src/user_management/enrollment_detail_page.dart'
    show EnrollmentDetailPage;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../event_management/event.dart';
import '../core/api/api_client.dart';
import '../core/services/event_api_service.dart';
import 'enrollment_api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  // API services
  EventApiService? _eventApiService;
  EnrollmentApiService? _enrollmentApiService;

  // State variables
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedEventId;
  List<Map<String, dynamic>> _enrollments = [];
  bool _isLoadingEnrollments = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      _eventApiService = EventApiService(apiClient);
      _enrollmentApiService = EnrollmentApiService(apiClient);
      await _loadEvents();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    try {
      setState(() => _isLoading = true);
      if (_eventApiService == null) {
        throw Exception('Event service not initialized');
      }
      final response = await _eventApiService!.getAllEvents(page: 1, limit: 50);
      setState(() {
        _events = response.events;
        _filteredEvents = List.from(response.events);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEnrollments(String eventId) async {
    try {
      setState(() {
        _isLoadingEnrollments = true;
        _selectedEventId = eventId;
      });
      if (_enrollmentApiService == null) {
        throw Exception('Enrollment service not initialized');
      }
      final response = await _enrollmentApiService!.getEventEnrollments(
        eventId,
      );
      final mapped = response.enrollments
          .map(
            (e) => {
              'id': e.id,
              'userName': e.userName,
              'userEmail': e.userEmail,
              'status': e.status,
              'enrolledAt': e.enrolledAt,
              'phoneNumber': e.phoneNumber,
              'college': e.college,
            },
          )
          .toList();
      setState(() {
        _enrollments = mapped;
        _isLoadingEnrollments = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load enrollments: $e';
        _isLoadingEnrollments = false;
      });
    }
  }

  void _searchEvents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = List.from(_events);
      } else {
        _filteredEvents = _events
            .where(
              (event) =>
                  event.title.toLowerCase().contains(query.toLowerCase()) ||
                  event.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final initialDate = initial ?? now;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        initialDate.hour,
        initialDate.minute,
      );
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8FAFF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.grey[900]!, Colors.grey[800]!]
                          : [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 30.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'User Management',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 30.0),
                          child: Text(
                            'View and manage user enrollments',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: _buildSearchBar(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorWidget(isDark)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildEventsSection(isDark)],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search events by title',
        hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  _searchController.clear();
                  _searchEvents('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: _searchEvents,
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.red[400] : Colors.red[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEventsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
        border: isDark ? Border.all(color: Colors.grey[800]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Events',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (_filteredEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 40,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No events available',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                return _buildEventCard(event, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, bool isDark) {
    return GestureDetector(
      onTap: () => _showEnrollmentDetails(event, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      event.category ?? EventCategory.other,
                    ).withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getCategoryDisplayName(
                      event.category ?? EventCategory.other,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(
                        event.category ?? EventCategory.other,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (event.dateTime != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(event.dateTime!),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (event.mode != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getModeColor(
                        event.mode!,
                      ).withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getModeDisplayName(event.mode!),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getModeColor(event.mode!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return Colors.blue;
      case EventCategory.cultural:
        return Colors.purple;
      case EventCategory.technical:
        return Colors.green;
      case EventCategory.workshop:
        return Colors.orange;
      case EventCategory.seminar:
        return Colors.red;
      case EventCategory.webinar:
        return Colors.teal;
      case EventCategory.conference:
        return Colors.indigo;
      case EventCategory.sports:
        return Colors.amber;
      case EventCategory.social:
        return Colors.pink;
      case EventCategory.other:
        return Colors.grey;
    }
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.technical:
        return 'Technical';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.webinar:
        return 'Webinar';
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.social:
        return 'Social';
      case EventCategory.other:
        return 'Other';
    }
  }

  Color _getModeColor(EventMode mode) {
    switch (mode) {
      case EventMode.online:
        return Colors.blue;
      case EventMode.offline:
        return Colors.green;
      case EventMode.hybrid:
        return Colors.orange;
    }
  }

  String _getModeDisplayName(EventMode mode) {
    switch (mode) {
      case EventMode.online:
        return 'Online';
      case EventMode.offline:
        return 'Offline';
      case EventMode.hybrid:
        return 'Hybrid';
    }
  }

  void _showEnrollmentDetails(Event event, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEnrollmentBottomSheet(event, isDark),
    );
  }

  Widget _buildEnrollmentBottomSheet(Event event, bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Event Enrollments',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Content - Using FutureBuilder for direct API calls
              Expanded(
                child: FutureBuilder<EnrollmentResponse>(
                  future: _loadEnrollmentsForBottomSheet(event.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading enrollments...'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load enrollments',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Refresh the future
                                setState(() {});
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.enrollments.isEmpty) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Show stats even when no enrollments
                            if (snapshot.data?.stats != null) ...[
                              _buildEnrollmentStats(
                                snapshot.data!.stats,
                                snapshot.data!.event,
                                isDark,
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Empty state
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No enrollments yet',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final response = snapshot.data!;
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics
                          _buildEnrollmentStats(
                            response.stats,
                            response.event,
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          // Enrollments list
                          Text(
                            'Enrolled Users (${response.enrollments.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: response.enrollments.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final enrollment = response.enrollments[index];
                              return _buildEnrollmentCard(
                                enrollment,
                                event,
                                isDark,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<EnrollmentResponse> _loadEnrollmentsForBottomSheet(
    String eventId,
  ) async {
    if (_enrollmentApiService == null) {
      throw Exception('Enrollment service not initialized');
    }

    return await _enrollmentApiService!.getEventEnrollments(eventId);
  }

  Widget _buildEnrollmentStats(
    EnrollmentStats stats,
    EventInfo? eventInfo,
    bool isDark,
  ) {
    final maxParticipants = eventInfo?.maxParticipants ?? 0;
    final availableSpots = maxParticipants > 0
        ? maxParticipants - stats.totalEnrollments
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue[800]! : Colors.blue[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrollment Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (eventInfo != null) ...[
            const SizedBox(height: 8),
            Text(
              '${eventInfo.title} (${eventInfo.category.toUpperCase()})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Max Capacity: $maxParticipants participants',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                stats.totalEnrollments.toString(),
                Colors.blue,
                isDark,
              ),
              _buildStatItem(
                'Approved',
                stats.approvedEnrollments.toString(),
                Colors.green,
                isDark,
              ),
              _buildStatItem(
                'Pending',
                stats.pendingEnrollments.toString(),
                Colors.orange,
                isDark,
              ),
              _buildStatItem(
                'Declined',
                stats.declinedEnrollments.toString(),
                Colors.red,
                isDark,
              ),
            ],
          ),
          if (maxParticipants > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: availableSpots > 0
                    ? (isDark
                          ? Colors.green[900]!.withOpacity(0.3)
                          : Colors.green[100])
                    : (isDark
                          ? Colors.red[900]!.withOpacity(0.3)
                          : Colors.red[100]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    availableSpots > 0 ? Icons.event_seat : Icons.event_busy,
                    size: 16,
                    color: availableSpots > 0
                        ? (isDark ? Colors.green[300] : Colors.green[700])
                        : (isDark ? Colors.red[300] : Colors.red[700]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    availableSpots > 0
                        ? '$availableSpots spots available'
                        : 'Event is full',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: availableSpots > 0
                          ? (isDark ? Colors.green[300] : Colors.green[700])
                          : (isDark ? Colors.red[300] : Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentCard(Enrollment enrollment, Event event, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (enrollment.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return GestureDetector(
      onTap: () => _navigateToEnrollmentDetail(enrollment, event.id, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: enrollment.userAvatar != null
                  ? NetworkImage(enrollment.userAvatar!)
                  : null,
              child: enrollment.userAvatar == null
                  ? Text(
                      enrollment.userName.isNotEmpty
                          ? enrollment.userName[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.userName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    enrollment.userEmail,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (enrollment.college != null &&
                      enrollment.college!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            enrollment.college!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (enrollment.phoneNumber != null &&
                      enrollment.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          enrollment.phoneNumber!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Requested: ${DateFormat('MMM dd, yyyy').format(enrollment.enrolledAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status and actions
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Three-dot menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onSelected: (value) => _handleEnrollmentAction(
                    enrollment,
                    value,
                    event.id,
                    isDark,
                  ),
                  itemBuilder: (context) =>
                      _buildMenuItems(enrollment.status, isDark),
                ),
                const SizedBox(height: 4),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        enrollment.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    String currentStatus,
    bool isDark,
  ) {
    List<PopupMenuEntry<String>> items = [];

    switch (currentStatus.toLowerCase()) {
      case 'pending':
        items.addAll([
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Approve',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'decline',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Decline',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ]);
        break;
      case 'approved':
        items.add(
          PopupMenuItem(
            value: 'decline',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Decline',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 'declined':
        items.add(
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Approve',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }

    // Add view details option
    if (items.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }
    items.add(
      PopupMenuItem(
        value: 'view_details',
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Text(
              'View Details',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );

    return items;
  }

  Future<void> _handleEnrollmentAction(
    Enrollment enrollment,
    String action,
    String eventId,
    bool isDark,
  ) async {
    switch (action) {
      case 'approve':
        await _updateEnrollmentStatus(enrollment, 'approved', eventId, isDark);
        break;
      case 'decline':
        await _updateEnrollmentStatus(enrollment, 'declined', eventId, isDark);
        break;
      case 'view_details':
        _navigateToEnrollmentDetail(enrollment, eventId, isDark);
        break;
    }
  }

  Future<void> _updateEnrollmentStatus(
    Enrollment enrollment,
    String newStatus,
    String eventId,
    bool isDark,
  ) async {
    // Show confirmation dialog
    final confirmed = await _showStatusConfirmationDialog(
      enrollment,
      newStatus,
    );
    if (!confirmed) return;

    try {
      if (_enrollmentApiService == null) {
        throw Exception('Enrollment service not initialized');
      }

      final success = await _enrollmentApiService!.updateEnrollmentStatus(
        eventId,
        enrollment.id,
        newStatus,
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${enrollment.userName} ${newStatus.toLowerCase()} successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh the bottom sheet by closing and reopening
        Navigator.pop(context); // Close current bottom sheet
        _showEnrollmentDetails(
          _events.firstWhere((e) => e.id == eventId),
          isDark,
        ); // Reopen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update enrollment: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _showStatusConfirmationDialog(
    Enrollment enrollment,
    String action,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              '${action == 'approved' ? 'Approve' : 'Decline'} Enrollment',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to ${action == 'approved' ? 'approve' : 'decline'} this enrollment?',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Text(
                          enrollment.userName.isNotEmpty
                              ? enrollment.userName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enrollment.userName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              enrollment.userEmail,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'approved'
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  action == 'approved' ? 'Approve' : 'Decline',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _navigateToEnrollmentDetail(
    Enrollment enrollment,
    String eventId,
    bool isDark,
  ) async {
    // Get the event from the events list
    final event = _events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => Event.empty(),
    );
    final eventTitle = event.title;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EnrollmentDetailPage(
          enrollment: enrollment,
          eventTitle: eventTitle,
        ),
      ),
    );
    if (result == true) {
      Navigator.pop(context);
      _showEnrollmentDetails(event, isDark);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
