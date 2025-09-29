import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_header.dart';
import '../../event_management/event.dart';
import '../../core/api/api_client.dart';
import '../../core/services/event_api_service.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic>? event;
  final String? slug;

  const EventDetailPage({super.key, this.event, this.slug});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _apiEvent;
  bool _isLoading = false;
  String? _errorMessage;
  EventApiService? _eventApiService;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      _eventApiService = EventApiService(apiClient);

      if (widget.event != null) {
        // If event map is provided, use it directly
        setState(() {
          _isLoading = false;
        });
      } else if (widget.slug != null && widget.slug!.isNotEmpty) {
        await _loadEventData();
      } else {
        setState(() {
          _errorMessage = "No event data provided.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEventData() async {
    if (widget.slug != null &&
        widget.slug!.isNotEmpty &&
        _eventApiService != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // You must implement getEventBySlug in your EventApiService
        final event = await _eventApiService!.getEventBySlug(widget.slug!);

        setState(() {
          _apiEvent = event;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to get event: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<String> get eventImages {
    final event = currentEvent;
    final apiImages = event['images'] as List<dynamic>? ?? [];
    const String baseUrl = 'http://54.82.53.11:5001';
    print('DEBUG: Raw images from API: $apiImages');
    final List<String> fixedImages = apiImages.map((img) {
      if (img is String && img.isNotEmpty) {
        if (img.startsWith('http')) {
          return img;
        } else if (img.startsWith('/')) {
          final fullUrl = baseUrl + img;
          print('DEBUG: Generated image URL: $fullUrl');
          return fullUrl;
        } else {
          final fullUrl = baseUrl + '/' + img;
          print('DEBUG: Generated image URL: $fullUrl');
          return fullUrl;
        }
      }
      return 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400';
    }).toList();
    print('DEBUG: Final image URLs: $fixedImages');
    return fixedImages.isNotEmpty
        ? fixedImages
        : ['https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400'];
  }

  Map<String, dynamic> get currentEvent {
    if (_apiEvent != null) {
      // Format time properly
      String formatTime(String? time) {
        if (time == null || time.isEmpty) return 'TBD';
        try {
          final parts = time.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
          }
        } catch (e) {
          return time;
        }
        return time;
      }

      // Format date properly
      String formatDate(DateTime? date) {
        if (date == null) return 'TBD';
        return '${date.day}/${date.month}/${date.year}';
      }

      // Fix images to be absolute URLs
      const String baseUrl = 'http://54.82.53.11:5001';

      final List<String> fixedImages = (_apiEvent!.images).map((img) {
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

      return {
        // Basic Info
        'id': _apiEvent!.id,
        'title': _apiEvent!.title,
        'description': _apiEvent!.description,
        'location': _apiEvent!.location,
        'slug': _apiEvent!.slug,

        // Timing
        'startTime': formatTime(_apiEvent!.startTime),
        'endTime': formatTime(_apiEvent!.endTime),
        'time':
            '${formatTime(_apiEvent!.startTime)} - ${formatTime(_apiEvent!.endTime)}',
        'startDate': _apiEvent!.startDate,
        'endDate': _apiEvent!.endDate,
        'startDateFormatted': formatDate(_apiEvent!.startDate),
        'endDateFormatted': formatDate(_apiEvent!.endDate),
        'registrationDeadline': _apiEvent!.registrationDeadline,
        'registrationDeadlineFormatted': formatDate(
          _apiEvent!.registrationDeadline,
        ),

        // Event Details
        'eventType': _apiEvent!.mode?.name ?? 'offline',
        'category': _apiEvent!.category?.name ?? 'other',
        'price': _apiEvent!.price ?? 0.0,
        'maxParticipants': _apiEvent!.maxAttendees ?? 0,
        'currentAttendees': _apiEvent!.currentAttendees ?? 0,
        'isActive': _apiEvent!.isActive,

        // Media (fixed)
        'image': fixedImages.isNotEmpty ? fixedImages.first : null,
        'images': fixedImages,
        'videos': _apiEvent!.videos,
        'imageUrl': _apiEvent!.imageUrl,

        // Organizer Info
        'organizerName': _apiEvent!.createdBy.name,
        'organizerEmail': _apiEvent!.createdBy.email,
        'organizerId': _apiEvent!.createdBy.id,
        'contactEmail': _apiEvent!.contactEmail,
        'contactPhone': _apiEvent!.contactPhone,

        // Participant Stats
        'totalEnrollments': _apiEvent!.participantStats?.totalEnrollments ?? 0,
        'approvedParticipants':
            _apiEvent!.participantStats?.approvedParticipants ?? 0,
        'pendingRequests': _apiEvent!.participantStats?.pendingRequests ?? 0,
        'declinedRequests': _apiEvent!.participantStats?.declinedRequests ?? 0,
        'availableSpots': _apiEvent!.participantStats?.availableSpots ?? 0,
        'attendees':
            _apiEvent!.participantStats?.totalEnrollments.toString() ?? '0',

        // Additional Info
        'tags': _apiEvent!.tags,
        'resources': _apiEvent!.resources,
        'meetingLink': _apiEvent!.meetingLink,
        'venue': _apiEvent!.venue,

        // Timestamps
        'createdAt': _apiEvent!.createdAt,
        'updatedAt': _apiEvent!.updatedAt,
        'createdAtFormatted': formatDate(_apiEvent!.createdAt),
        'updatedAtFormatted': formatDate(_apiEvent!.updatedAt),
      };
    }
    // If using widget.event directly (from API response)
    if (widget.event != null) {
      final event = widget.event!;
      final apiImages = event['images'] as List<dynamic>? ?? [];
      const String baseUrl = 'http://54.82.53.11:5001';

      final List<String> fixedImages = apiImages.map((img) {
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
      return {
        ...event,
        'image': fixedImages.isNotEmpty ? fixedImages.first : null,
        'images': fixedImages,
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Loading...',
          showBackButton: true,
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Error',
          showBackButton: true,
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEventData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final event = currentEvent;

    return Scaffold(
      appBar: AppHeader(
        title: event['title'] ?? 'Event Details',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Main Image
            _buildEventMainImage(screenWidth, screenHeight, event),

            // Event Content
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title and Price
                  _buildEventHeader(screenWidth, event),

                  SizedBox(height: screenHeight * 0.02),

                  // Event Status and Basic Info
                  _buildEventStatusSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // Event Timing Details
                  _buildTimingSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // About Event Section
                  _buildAboutSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // Organizer Information
                  _buildOrganizerSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // Participant Statistics
                  _buildParticipantStatsSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // Event Details (Location, Contact)
                  _buildEventDetails(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // Tags Section
                  if (event['tags'] != null &&
                      (event['tags'] as List).isNotEmpty)
                    _buildTagsSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.03),

                  // Event Images Section
                  _buildEventImagesSection(screenWidth, screenHeight, event),

                  // Videos Section (if available)
                  if (event['videos'] != null &&
                      (event['videos'] as List).isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.03),
                    _buildVideosSection(screenWidth, event),
                  ],

                  // Resources Section (if available)
                  if (event['resources'] != null &&
                      (event['resources'] as List).isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.03),
                    _buildResourcesSection(screenWidth, event),
                  ],

                  SizedBox(height: screenHeight * 0.03),

                  // Meeting Link Section (if available)
                  if (event['meetingLink'] != null &&
                      event['meetingLink'].toString().isNotEmpty) ...[
                    _buildMeetingLinkSection(screenWidth, event),
                    SizedBox(height: screenHeight * 0.03),
                  ],

                  // Event Metadata
                  _buildMetadataSection(screenWidth, event),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventMainImage(
    double screenWidth,
    double screenHeight,
    Map<String, dynamic> event,
  ) {
    final imageUrl =
        event['image'] ??
        'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600';
    print('DEBUG: Main event image URL: $imageUrl');

    return Container(
      width: double.infinity,
      height: screenHeight * 0.3,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildEventHeader(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'] ?? 'Event Title',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 24, 20, 18),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event['location'] ?? 'Event Location',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 14, 12, 10),
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Start: ${event['startTime'] ?? '9:00 AM'}',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 12, 10, 8),
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'End: ${event['endTime'] ?? '11:00 AM'}',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 12, 10, 8),
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventStatusSection(
    double screenWidth,
    Map<String, dynamic> event,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Status',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (event['isActive'] == true)
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (event['isActive'] == true)
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: (event['isActive'] == true)
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (event['isActive'] == true) ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: (event['isActive'] == true)
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event['eventType']?.toString().toUpperCase() ?? 'OFFLINE',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event['category']?.toString().toUpperCase() ?? 'OTHER',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Timing',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimingRow(
            'Start Date',
            event['startDateFormatted'] ?? 'TBD',
            Icons.calendar_today,
          ),
          if (event['endDateFormatted'] != null &&
              event['endDateFormatted'] != 'TBD')
            _buildTimingRow(
              'End Date',
              event['endDateFormatted'],
              Icons.calendar_today,
            ),
          _buildTimingRow(
            'Start Time',
            event['startTime'] ?? 'TBD',
            Icons.access_time,
          ),
          _buildTimingRow(
            'End Time',
            event['endTime'] ?? 'TBD',
            Icons.access_time,
          ),
          if (event['registrationDeadlineFormatted'] != null &&
              event['registrationDeadlineFormatted'] != 'TBD')
            _buildTimingRow(
              'Registration Deadline',
              event['registrationDeadlineFormatted'],
              Icons.schedule,
            ),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerSection(
    double screenWidth,
    Map<String, dynamic> event,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizer Information',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange[200],
                child: Icon(Icons.person, color: Colors.orange[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['organizerName'] ?? 'Unknown Organizer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (event['organizerEmail'] != null)
                      Text(
                        event['organizerEmail'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantStatsSection(
    double screenWidth,
    Map<String, dynamic> event,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participant Statistics',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Enrollments',
                  '${event['totalEnrollments'] ?? 0}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Approved',
                  '${event['approvedParticipants'] ?? 0}',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '${event['pendingRequests'] ?? 0}',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Available Spots',
                  '${event['availableSpots'] ?? 0}',
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (event['maxParticipants'] != null &&
              event['maxParticipants'] > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Capacity: ${event['currentAttendees'] ?? 0} / ${event['maxParticipants']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value:
                  (event['currentAttendees'] ?? 0) / event['maxParticipants'],
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: color[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tags = event['tags'] as List? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(
    double screenWidth,
    Map<String, dynamic> event,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resources = event['resources'] as List? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resource.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingLinkSection(
    double screenWidth,
    Map<String, dynamic> event,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meeting Link',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.video_call, color: Colors.cyan[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event['meetingLink'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.cyan[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Launch URL
                },
                icon: Icon(Icons.open_in_new, color: Colors.cyan[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Metadata',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('Event ID', event['id'] ?? 'N/A'),
          _buildMetadataRow('Slug', event['slug'] ?? 'N/A'),
          _buildMetadataRow('Created', event['createdAtFormatted'] ?? 'N/A'),
          _buildMetadataRow(
            'Last Updated',
            event['updatedAtFormatted'] ?? 'N/A',
          ),
          if (event['venue'] != null)
            _buildMetadataRow('Venue', event['venue']),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white :Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Event',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          event['description'] ??
              'Planning an event can be a daunting task. Especially when you\'re not sure where to start. This comprehensive guide will help you plan and execute a successful event from start to finish.',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 14, 12, 10),
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetails(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Participants Row
        // Row(
        //   children: [
        //     // Profile images
        //     SizedBox(
        //       width: 80,
        //       height: 30,
        //       child: Stack(
        //         children: [
        //           Positioned(
        //             left: 0,
        //             child: CircleAvatar(
        //               radius: 15,
        //               backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100'),
        //             ),
        //           ),
        //           Positioned(
        //             left: 20,
        //             child: CircleAvatar(
        //               radius: 15,
        //               backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
        //             ),
        //           ),
        //           Positioned(
        //             left: 40,
        //             child: CircleAvatar(
        //               radius: 15,
        //               backgroundImage: NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100'),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     // Text(
        //     //   '+20 Participants',
        //     //   style: GoogleFonts.poppins(
        //     //     fontSize: _getResponsiveFontSize(screenWidth, 12, 10, 8),
        //     //     color: Colors.grey[600],
        //     //   ),
        //     // ),
        //   ],
        // ),
        // const SizedBox(height: 16),

        // Location
        Text(
          'Location',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: const Color(0xFF8B5CF6),
              size: _getResponsiveSize(screenWidth, 20, 18, 16),
            ),
            const SizedBox(width: 8),
            Text(
              event['location'] ?? 'California, USA',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 14, 12, 10),
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventImagesSection(
    double screenWidth,
    double screenHeight,
    Map<String, dynamic> event,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category buttons
        Row(
          children: [
            Text(
              'Top Picks 🔥',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Images display
        eventImages.isNotEmpty
            ? SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: eventImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          eventImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            : Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No images available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildVideosSection(double screenWidth, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videos = event['videos'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.videocam,
              color: const Color(0xFF8B5CF6),
              size: _getResponsiveSize(screenWidth, 20, 18, 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Event Videos (${videos.length})',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Videos list
        Column(
          children: videos.map((videoUrl) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      videoUrl.isNotEmpty
                          ? videoUrl.split('/').last
                          : 'Video ${videos.indexOf(videoUrl) + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(
                          screenWidth,
                          14,
                          12,
                          10,
                        ),
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new, color: Colors.blue[500], size: 20),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildParticipantEngagementSection(
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: const Color(0xFF3B82F6),
              size: _getResponsiveSize(screenWidth, 24, 22, 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Participant Engagement',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(screenWidth, 20, 18, 16),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Track participant engagement (Q&A, polls).',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 16, 14, 12),
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Q&A Sessions Section
        Text(
          'Q&A Sessions',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildQACard(index, screenWidth);
            },
          ),
        ),

        const SizedBox(height: 24),

        // Polls Section
        Text(
          'Live Polls',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 18, 16, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildPollCard(index, screenWidth);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQACard(int index, double screenWidth) {
    final qaData = [
      {
        'question': 'What are the latest trends in AI development?',
        'author': 'Sarah Chen',
        'time': '2 min ago',
        'answers': '5',
      },
      {
        'question': 'How to implement machine learning in mobile apps?',
        'author': 'Mike Johnson',
        'time': '5 min ago',
        'answers': '3',
      },
      {
        'question': 'Best practices for cloud architecture?',
        'author': 'Alex Rivera',
        'time': '8 min ago',
        'answers': '7',
      },
    ];

    final qa = qaData[index];
    return Container(
      width: screenWidth * 0.85,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.question_answer,
                color: const Color(0xFF3B82F6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Q&A',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 12, 11, 10),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${qa['answers']} answers',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(screenWidth, 10, 9, 8),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            qa['question']!,
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 14, 13, 12),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'by ${qa['author']}',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 12, 11, 10),
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                qa['time']!,
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 11, 10, 9),
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(int index, double screenWidth) {
    final pollData = [
      {
        'question': 'Which technology will dominate 2024?',
        'option1': 'AI/ML',
        'option2': 'Blockchain',
        'votes': '156',
        'percentage': '78%',
      },
      {
        'question': 'Preferred development framework?',
        'option1': 'React',
        'option2': 'Flutter',
        'votes': '89',
        'percentage': '65%',
      },
      {
        'question': 'Most important skill for developers?',
        'option1': 'Problem Solving',
        'option2': 'Communication',
        'votes': '203',
        'percentage': '82%',
      },
    ];

    final poll = pollData[index];
    return Container(
      width: screenWidth * 0.85,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, color: const Color(0xFFEC4899), size: 16),
              const SizedBox(width: 8),
              Text(
                'Live Poll',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 12, 11, 10),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEC4899),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${poll['votes']} votes',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(screenWidth, 10, 9, 8),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            poll['question']!,
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(screenWidth, 14, 13, 12),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    poll['option1']!,
                    style: GoogleFonts.poppins(
                      fontSize: _getResponsiveFontSize(screenWidth, 11, 10, 9),
                      color: const Color(0xFFEC4899),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                poll['percentage']!,
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(screenWidth, 12, 11, 10),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Map',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(screenWidth, 20, 18, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Google Maps with actual address
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://maps.googleapis.com/maps/api/staticmap?center=1600+Amphitheatre+Parkway,+Mountain+View,+CA&zoom=15&size=600x400&maptype=roadmap&markers=color:red%7Clabel:E%7C1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=AIzaSyBFw0Qbyq9zTFTd-tUY6dOWTgHz-TRU6Qg',
                      ),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Fallback to placeholder
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fallback content when map fails to load
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFFF8FAFC),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.map,
                          size: 32,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1600 Amphitheatre Parkway',
                        style: GoogleFonts.poppins(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            16,
                            14,
                            12,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mountain View, CA 94043',
                        style: GoogleFonts.poppins(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            14,
                            12,
                            10,
                          ),
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to open in Maps',
                        style: GoogleFonts.poppins(
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            12,
                            11,
                            10,
                          ),
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Location pin overlay
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: const Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCertificateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: const Color(0xFF8B5CF6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Certificate',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get a certificate of completion after attending this event. Perfect for your professional portfolio.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      const Color(0xFFEC4899).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CERTIFICATE OF COMPLETION',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8B5CF6),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This is to certify that',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'John Doe',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'has successfully completed',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentEvent['title'] ?? 'Tech Conference 2024',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 20,
                                color: const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MohJay Infotech',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8B5CF6),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add download functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Download',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper methods
  double _getResponsiveFontSize(
    double screenWidth,
    double webSize,
    double tabletSize,
    double mobileSize,
  ) {
    if (screenWidth > 900) return webSize;
    if (screenWidth > 600) return tabletSize;
    return mobileSize + 2; // Increased mobile font size for better visibility
  }

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
}
