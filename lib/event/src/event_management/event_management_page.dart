import 'package:flutter/material.dart';
import 'package:fluttertest/event/src/features/presentation/event_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'event.dart';
import 'create_edit_event_page.dart';
import '../core/api/api_client.dart';
import '../core/services/event_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventManagementPage extends StatefulWidget {
  const EventManagementPage({super.key});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  // API services
  EventApiService? _eventApiService;

  // State variables
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      await _loadEvents();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    if (_eventApiService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _eventApiService!.getAllEvents();
      setState(() {
        _events = response.events;
        _filteredEvents = List.from(response.events);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF8FAFF),
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
                      colors: [
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Event Management',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width < 360
                                        ? 18
                                        : 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Text(
                              'Create and manage your events',
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
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventStats(isDark),
                    const SizedBox(height: 20),
                    _buildEventsList(isDark),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateEvent,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Event',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
        onChanged: (value) {
          _searchEvents(value);
        },
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchEvents('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEventStats(bool isDark) {
    final totalEvents = _events.length;
    final upcomingEvents = _events
        .where((event) => event.dateTime?.isAfter(DateTime.now()) ?? false)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Events',
                  totalEvents.toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  'Upcoming',
                  upcomingEvents.toString(),
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(bool isDark) {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Icon(
              Icons.event_busy,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first event to get started',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Events (${_filteredEvents.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredEvents.length,
          itemBuilder: (context, index) {
            return _buildEventCard(_filteredEvents[index], isDark);
          },
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToEventDetail(event),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleEventAction(value, event),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • HH:mm',
                    ).format(event.dateTime ?? DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    event.mode == EventMode.online
                        ? Icons.videocam
                        : Icons.location_on,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.venue ?? 'TBD',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  void _handleEventAction(String action, Event event) {
    switch (action) {
      case 'edit':
        _navigateToEditEvent(event);
        break;
      case 'delete':
        _showDeleteConfirmation(event);
        break;
    }
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEvent(event.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateEvent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEditEventPage()),
    );
    await _loadEvents(); // Reload events after returning
  }

  void _navigateToEditEvent(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditEventPage(event: event),
      ),
    );
    await _loadEvents(); // Reload events after returning
  }

  void _navigateToEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event.toJson()),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: Colors.red[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadEvents(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _eventApiService?.deleteEvent(eventId);
      await _loadEvents(); // Reload events after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Local helpers to replace EventProvider for display only
Color _getCategoryColor(EventCategory category) {
  switch (category) {
    case EventCategory.academic:
      return Colors.indigo;
    case EventCategory.cultural:
      return Colors.pink;
    case EventCategory.technical:
      return Colors.blue;
    case EventCategory.workshop:
      return Colors.orange;
    case EventCategory.seminar:
      return Colors.green;
    case EventCategory.webinar:
      return Colors.teal;
    case EventCategory.conference:
      return Colors.purple;
    case EventCategory.sports:
      return Colors.red;
    case EventCategory.social:
      return Colors.brown;
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
