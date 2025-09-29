import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import 'event_details_page.dart';

class StudentEventPage extends StatefulWidget {
  const StudentEventPage({super.key});

  @override
  State<StudentEventPage> createState() => _StudentEventPageState();
}

class _StudentEventPageState extends State<StudentEventPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Event> _filteredEvents = [];
  List<Event> _allEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadEvents();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _eventService.getAllEvents();
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
      _filterEvents();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load events: ${e.toString()}';
        _allEvents = [];
      });
      _filterEvents();
    }
  }

  void _filterEvents() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((event) {
          return event.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              event.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              event.category.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  List<Event> _getEventsByCategory(String category) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (category) {
      case 'Today':
        return _filteredEvents.where((event) {
          final eventDate = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          return eventDate.isAtSameMomentAs(today);
        }).toList();
      case 'Upcoming':
        return _filteredEvents.where((event) {
          final eventDate = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          return eventDate.isAfter(today);
        }).toList();
      case 'Past':
        return _filteredEvents.where((event) {
          final eventDate = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          return eventDate.isBefore(today);
        }).toList();
      default:
        return _filteredEvents;
    }
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : Colors.white,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.black : Colors.white,
        ), // Add this line for typed text color
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterEvents();
        },
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: TextStyle(color: isDark ? Colors.black : Colors.white),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.black : Colors.white,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _filterEvents();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : Colors.white,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5F299E), Color(0xFF8B5CF6), Color(0xFFB794F6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F299E).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Today'),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Upcoming'),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Past'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );

    final isToday = eventDay.isAtSameMomentAs(today);
    final isPast = event.date.isBefore(now);
    final isUpcoming = event.date.isAfter(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        await _navigateToEventDetails(event);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F299E).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image with Status Badge
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          event.imageUrl ?? 'assets/images/developer.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF5F299E).withOpacity(0.8),
                                    const Color(0xFF8B5CF6).withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.event,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        // Gradient overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.orange
                          : isUpcoming
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isToday
                          ? 'TODAY'
                          : isUpcoming
                          ? 'UPCOMING'
                          : 'PAST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Registration Badge
                if (event.isRegistered)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'REGISTERED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1B69),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F299E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Color(0xFF5F299E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    event.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Date and Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.date.day}/${event.date.month}/${event.date.year}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Participants Progress + Register Button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event.currentParticipants}/${event.maxParticipants} participants',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  event.currentParticipants /
                                  event.maxParticipants,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                event.currentParticipants /
                                            event.maxParticipants >
                                        0.8
                                    ? Colors.red
                                    : const Color(0xFF5F299E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Registration Button
                      if (!isPast)
                        ElevatedButton(
                          onPressed:
                              event.currentParticipants >= event.maxParticipants
                              ? null
                              : () => _registerForEvent(event),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.isRegistered
                                ? Colors.grey
                                : const Color(0xFF5F299E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            event.isRegistered
                                ? 'Registered'
                                : event.currentParticipants >=
                                      event.maxParticipants
                                ? 'Full'
                                : 'Register',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
  }

  Future<void> _navigateToEventDetails(Event event) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F299E)),
          ),
        );
      },
    );

    try {
      // Fetch event details before navigating
      final eventDetails = await _eventService.getEventDetails(event.title);

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to event details page with the fetched details
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(
              eventId: eventDetails.id,
              eventTitle: eventDetails.title,
            ),
          ),
        );

        // Refresh the events list when returning from details page
        await _loadEvents();
      }
    } catch (e) {
      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load event details: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _registerForEvent(Event event) async {
    HapticFeedback.lightImpact();

    if (event.isRegistered) {
      // Show message that unregistration is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already registered for this event'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Enrolling in event...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final success = await _eventService.enrollInEvent(event.id);
      if (success) {
        setState(() {
          // Update local state - note: this won't persist since we don't have unregister
          // In a real app, you'd refresh the events from API
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully enrolled in ${event.title}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enroll. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5F299E), Color(0xFF8B5CF6), Color(0xFFB794F6)],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Tab Bar
            _buildTabBar(),

            const SizedBox(height: 16),

            // Tab Bar View
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF5F299E),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading events...',
                            style: TextStyle(
                              color: Color(0xFF5F299E),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Events',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadEvents,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5F299E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventList('Today'),
                        _buildEventList('Upcoming'),
                        _buildEventList('Past'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(String category) {
    final events = _getEventsByCategory(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No ${category.toLowerCase()} events found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index]);
      },
    );
  }
}
