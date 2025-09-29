import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event_page.dart';
import 'event_detail_page.dart';
import '../../event_management/services/event_service.dart';
import '../../event_management/models/dashboard_response.dart';
import '../../core/api/api_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // API integration
  EventService? _eventService;
  bool _isLoading = true;
  String? _errorMessage;

  // Dynamic data from API
  List<Map<String, dynamic>> _todayEvents = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _pastEvents = [];
  EventSummary? _summary;

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEventService();
    });
  }

  List<Map<String, dynamic>> _fixEventImages(
    List<Map<String, dynamic>> events,
  ) {
    const String baseUrl = 'http://54.82.53.11:5001';

    return events.map((event) {
      // Fix single image
      final dynamic image = event['image'];
      String? fixedImage;

      if (image is String && image.isNotEmpty) {
        if (image.startsWith('http')) {
          fixedImage = image;
        } else if (image.startsWith('/')) {
          fixedImage = baseUrl + image;
        } else {
          fixedImage = baseUrl + '/' + image;
        }
      }

      // Fix images array
      final dynamic images = event['images'];
      List<String> fixedImages = [];

      if (images is List<dynamic>) {
        fixedImages = images.map((img) {
          if (img is String && img.isNotEmpty) {
            if (img.startsWith('http')) {
              return img;
            } else if (img.startsWith('/')) {
              return baseUrl + img;
            } else {
              return baseUrl + '/' + img;
            }
          }
          return 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400';
        }).toList();
      }

      // Return event with fixed images
      return {
        ...event,
        'image':
            fixedImage ??
            'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
        'images': fixedImages.isNotEmpty
            ? fixedImages
            : ['https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400'],
      };
    }).toList();
  }

  Future<void> _initializeEventService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      _eventService = EventService(apiClient);
      await _loadEvents();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    if (_eventService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _eventService!.getFormattedEvents();
      final summary = await _eventService!.getSummary();

      final todayEvents = events['today'] ?? [];
      final upcomingEvents = events['upcoming'] ?? [];
      final pastEvents = events['past'] ?? [];

      setState(() {
        _todayEvents = _fixEventImages(todayEvents);
        _upcomingEvents = _fixEventImages(upcomingEvents);
        _pastEvents = _fixEventImages(pastEvents);
        _summary = summary;
        _isLoading = false;
      });

      // Provider removed - app works with local state only
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
      });

      // Error handled in local state only
    }
  }

  Future<void> _refreshEvents() async {
    await _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _refreshEvents,
              child: _buildResponsiveContent(),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading events...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading events',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 8.0 : 20.0; // Reduced for mobile
    final verticalPadding = screenWidth < 600 ? 8.0 : 20.0; // Reduced for mobile

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: screenWidth < 600 ? 12.0 : 16.0, // Reduced for mobile
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Today',
              _summary!.todayCount.toString(),
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Upcoming',
              _summary!.upcomingCount.toString(),
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Past',
              _summary!.pastCount.toString(),
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Total',
              _summary!.totalActiveEvents.toString(),
              screenWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String count, double screenWidth) {
    double countFontSize = _getResponsiveFontSize(screenWidth, 24, 20, 16);
    double labelFontSize = _getResponsiveFontSize(screenWidth, 12, 11, 10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: countFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: labelFontSize,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Reduced padding for mobile
    final horizontalPadding = screenWidth < 600 ? 16.0 : screenWidth * 0.1;
    final verticalPadding = screenWidth < 600 ? 12.0 : MediaQuery.of(context).size.height * 0.02;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGradientHeader(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenWidth < 600 ? 8.0 : MediaQuery.of(context).size.height * 0.01),
                _buildSummaryCard(),
                SizedBox(height: screenWidth < 600 ? 16.0 : MediaQuery.of(context).size.height * 0.03),
                _buildTodaySection(),
                SizedBox(height: screenWidth < 600 ? 16.0 : MediaQuery.of(context).size.height * 0.03),
                _buildUpcomingSection(),
                SizedBox(height: screenWidth < 600 ? 16.0 : MediaQuery.of(context).size.height * 0.03),
                _buildPastEventsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reduced height and padding for mobile
    final headerHeight = screenWidth < 600 ? screenHeight * 0.14 : screenHeight * 0.18;
    final horizontalPadding = screenWidth < 600 ? 16.0 : screenWidth * 0.1;
    final topPadding = screenWidth < 600 
        ? MediaQuery.of(context).padding.top + screenHeight * 0.02 
        : MediaQuery.of(context).padding.top + screenHeight * 0.03;

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        screenWidth < 600 ? 16.0 : screenHeight * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Discover Event',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 32, 28, 22), // Reduced mobile size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get responsive font sizes
  double _getResponsiveFontSize(
    double screenWidth,
    double webSize,
    double tabletSize,
    double mobileSize,
  ) {
    if (screenWidth > 900) return webSize;
    if (screenWidth > 600) return tabletSize;
    return mobileSize;
  }

  // Helper method to get responsive sizes
  double _getResponsiveSize(
    double screenWidth,
    double webSize,
    double tabletSize,
    double mobileSize,
  ) {
    if (screenWidth > 900) return webSize;
    if (screenWidth > 600) return tabletSize;
    return mobileSize;
  }

  Widget _buildTodaySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = _getResponsiveSize(screenWidth, 340, 260, 220);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 24, 20, 18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventPage(events: _todayEvents, eventType: 'Today'),
                  ),
                );
              },
              child: Text(
                'View more',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
                  color: const Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _todayEvents.isEmpty
            ? _buildEmptyState('No events today')
            : SizedBox(
                height: cardHeight,
                width: double.infinity,
                child:
                    (kIsWeb ||
                        Theme.of(context).platform == TargetPlatform.windows ||
                        Theme.of(context).platform == TargetPlatform.macOS ||
                        Theme.of(context).platform == TargetPlatform.linux)
                    ? Row(
                        children: _todayEvents
                            .take(2)
                            .map(
                              (e) => Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: screenWidth < 600 ? 12.0 : 20.0, // Reduced for mobile
                                  ),
                                  child: _buildTodayEventCard(e, cardHeight),
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _todayEvents.length,
                        itemBuilder: (context, index) {
                          final event = _todayEvents[index];
                          return Container(
                            margin: EdgeInsets.only(
                              right: screenWidth < 600 ? 12.0 : 20.0, // Reduced for mobile
                            ),
                            width: screenWidth * (screenWidth < 600 ? 0.8 : 0.7), // Wider on mobile
                            child: _buildTodayEventCard(event, cardHeight),
                          );
                        },
                      ),
              ),
      ],
    );
  }

  Widget _buildTodayEventCard(Map<String, dynamic> event, double imageHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * (screenWidth < 600 ? 0.8 : 0.7);

    String formatDayMonth(Map<String, dynamic> e) =>
        (e['startDate'] is DateTime || e['date'] is DateTime)
        ? (() {
            final d = e['startDate'] is DateTime ? e['startDate'] : e['date'];
            const months = [
              'JAN',
              'FEB',
              'MAR',
              'APR',
              'MAY',
              'JUN',
              'JUL',
              'AUG',
              'SEP',
              'OCT',
              'NOV',
              'DEC',
            ];
            return '${d.day.toString().padLeft(2, '0')}\n${months[d.month - 1]}';
          })()
        : ((e['date'] ?? '').toString().contains(' ')
              ? (() {
                  final parts = (e['date'] ?? '').toString().split(' ');
                  return parts.length >= 2
                      ? '${parts[0]}\n${parts[1]}'
                      : 'TBD\nTBD';
                })()
              : 'TBD\nTBD');

    return GestureDetector(
      onTap: () {
        final slug = event['slug'] ?? event['id']?.toString() ?? '';
        if (slug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(slug: slug),
            ),
          );
        }
      },
      child: Container(
        width: cardWidth,
        height: imageHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(
              event['image'] ??
                  'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
            ),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.all(_getResponsiveSize(screenWidth, 24, 20, 14)), // Reduced mobile padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(screenWidth, 14, 12, 8), // Reduced mobile
                    vertical: _getResponsiveSize(screenWidth, 8, 6, 4), // Reduced mobile
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formatDayMonth(event),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(screenWidth, 14, 12, 10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_border, 
                    color: Colors.white,
                    size: _getResponsiveSize(screenWidth, 24, 20, 18), // Smaller on mobile
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              event['title'],
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(screenWidth, 20, 18, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event['time'],
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // People icons row
                Row(
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: _getResponsiveSize(screenWidth, 28, 24, 20),
                      height: _getResponsiveSize(screenWidth, 28, 24, 20),
                      decoration: BoxDecoration(
                        color: event['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: _getResponsiveSize(screenWidth, 14, 12, 10),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                // Attending text
                Text(
                  '+${event['attendees'] ?? '120'} Attending',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: _getResponsiveFontSize(screenWidth, 14, 12, 10),
                  ),
                ),
                const SizedBox(height: 8),
                // Join button
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(screenWidth, 18, 16, 12), // Reduced mobile
                    vertical: _getResponsiveSize(screenWidth, 10, 8, 6), // Reduced mobile
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Join',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(screenWidth, 14, 12, 10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 24, 20, 18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventPage(
                      events: _upcomingEvents,
                      eventType: 'Upcoming',
                    ),
                  ),
                );
              },
              child: Text(
                'View more',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
                  color: const Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _upcomingEvents.isEmpty
            ? _buildEmptyState('No upcoming events found')
            : SizedBox(
                height: 180,
                width: double.infinity,
                child:
                    (kIsWeb ||
                        Theme.of(context).platform == TargetPlatform.windows ||
                        Theme.of(context).platform == TargetPlatform.macOS ||
                        Theme.of(context).platform == TargetPlatform.linux)
                    ? Row(
                        children: _upcomingEvents
                            .take(2)
                            .map(
                              (e) => Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: screenWidth < 600 ? 12.0 : 20.0, // Reduced for mobile
                                  ),
                                  child: _buildUpcomingEventCard(e),
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _upcomingEvents.length,
                        padding: const EdgeInsets.only(left: 0, right: 24),
                        itemBuilder: (context, index) {
                          final event = _upcomingEvents[index];
                          return Container(
                            margin: EdgeInsets.only(
                              right: screenWidth < 600 ? 12.0 : 20.0, // Reduced for mobile
                            ),
                            width: screenWidth * (screenWidth < 600 ? 0.8 : 0.7), // Wider on mobile
                            child: _buildUpcomingEventCard(event),
                          );
                        },
                      ),
              ),
      ],
    );
  }

  Widget _buildUpcomingEventCard(Map<String, dynamic> event) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        final slug = event['slug'] ?? event['id']?.toString() ?? '';
        if (slug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(slug: slug),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Container(
                height: 180,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      event['image'] ??
                          'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(
                    _getResponsiveSize(screenWidth, 16, 14, 10), // Reduced mobile padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveSize(screenWidth, 10, 8, 6),
                          vertical: _getResponsiveSize(screenWidth, 6, 5, 4),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event['date'] ?? '20 AUG',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: _getResponsiveFontSize(
                              screenWidth,
                              12,
                              10,
                              8,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['title'] ?? 'Event Title',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            18,
                            16,
                            14,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['time'] ?? '2:00 PM - 6:00 PM',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            14,
                            12,
                            10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white.withOpacity(0.8),
                            size: _getResponsiveSize(screenWidth, 16, 14, 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event['attendees'] ?? '95'} attending',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                12,
                                10,
                                8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastEventsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final pastEvents = _pastEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Past Events',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 24, 20, 18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventPage(events: _pastEvents, eventType: 'Past'),
                  ),
                );
              },
              child: Text(
                'View more',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        pastEvents.isEmpty
            ? _buildEmptyState('No past events found')
            : SizedBox(
                height: 180,
                width: double.infinity,
                child:
                    (kIsWeb ||
                        Theme.of(context).platform == TargetPlatform.windows ||
                        Theme.of(context).platform == TargetPlatform.macOS ||
                        Theme.of(context).platform == TargetPlatform.linux)
                    ? Row(
                        children: pastEvents
                            .take(2)
                            .map(
                              (e) => Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: screenWidth < 600 ? 12.0 : 20.0, // Reduced for mobile
                                  ),
                                  child: _buildPastEventCard(e),
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pastEvents.length,
                        padding: const EdgeInsets.only(left: 0, right: 24),
                        itemBuilder: (context, index) {
                          final event = pastEvents[index];
                          return Container(
                            margin: EdgeInsets.only(
                              right: screenWidth < 600 ? 12.0 : 20.0, // Reduced for mobile
                            ),
                            width: screenWidth * (screenWidth < 600 ? 0.8 : 0.7), // Wider on mobile
                            child: _buildPastEventCard(event),
                          );
                        },
                      ),
              ),
      ],
    );
  }

  Widget _buildPastEventCard(Map<String, dynamic> event) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        final slug = event['slug'] ?? event['id']?.toString() ?? '';
        if (slug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(slug: slug),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Container(
                height: 180,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      event['image'] ??
                          'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(
                    _getResponsiveSize(screenWidth, 16, 14, 10), // Reduced mobile padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveSize(screenWidth, 10, 8, 6),
                          vertical: _getResponsiveSize(screenWidth, 6, 5, 4),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event['date'] ?? '20 AUG',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: _getResponsiveFontSize(
                              screenWidth,
                              12,
                              10,
                              8,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['title'] ?? 'Event Title',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            18,
                            16,
                            14,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['time'] ?? '2:00 PM - 6:00 PM',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            14,
                            12,
                            10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white.withOpacity(0.8),
                            size: _getResponsiveSize(screenWidth, 16, 14, 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event['attendees'] ?? '85'} attended',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: _getResponsiveFontSize(
                                screenWidth,
                                12,
                                10,
                                8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
