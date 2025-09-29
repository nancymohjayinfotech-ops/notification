import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart';
import '../core/api/api_client.dart';
import '../core/services/event_api_service.dart';

class EventDetailPage extends StatefulWidget {
  final Event? event;
  final String? slug;

  const EventDetailPage({super.key, this.event, this.slug});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _event;
  bool _isLoading = false;
  String? _errorMessage;
  EventApiService? _eventApiService;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _initializeServices();

    // If slug is provided, load event by slug
    if (widget.slug != null && widget.event == null) {
      _loadEventBySlug();
    }
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      _eventApiService = EventApiService(apiClient);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
      });
    }
  }

  Future<void> _loadEventBySlug() async {
    if (widget.slug == null || _eventApiService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _eventApiService!.getEventBySlug(widget.slug!);

      setState(() {
        _isLoading = false;
        _event = result;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load event: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEventBySlug,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(title: const Text('Event Not Found')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final event = _event!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(event),
                  const SizedBox(height: 20),
                  _buildEventInfo(event),
                  const SizedBox(height: 20),
                  _buildDescription(event),
                  const SizedBox(height: 20),
                  _buildLocationInfo(event),
                  const SizedBox(height: 20),
                  if (event.images.isNotEmpty) ...[
                    _buildImagesSection(event),
                    const SizedBox(height: 20),
                  ],
                  if (event.videos.isNotEmpty) ...[
                    _buildVideosSection(event),
                    const SizedBox(height: 20),
                  ],
                  // _buildContactInfo(event),
                  const SizedBox(height: 20),
                  // _buildActionButtons(context, event),
                  // const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final event = _event!;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                event.category == 'Technology'
                    ? Colors.blue.shade400
                    : event.category == 'Business'
                    ? Colors.green.shade400
                    : event.category == 'Health'
                    ? Colors.red.shade400
                    : Colors.purple.shade400,
                event.category == 'Technology'
                    ? Colors.blue.shade600
                    : event.category == 'Business'
                    ? Colors.green.shade600
                    : event.category == 'Health'
                    ? Colors.red.shade600
                    : Colors.purple.shade600,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 100,
                right: -50,
                child: Icon(
                  Icons.event,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          event.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildEventModeChip(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _getCategoryDisplayName(
                  event.category ?? EventCategory.technical,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (event.price != null) ...[
                Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                Text(
                  '\$${event.price!.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'FREE',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventModeChip() {
    final event = _event!;
    Color chipColor;
    IconData chipIcon;

    switch (event.mode ?? EventMode.online) {
      case EventMode.online:
        chipColor = Colors.blue;
        chipIcon = Icons.videocam;
        break;
      case EventMode.offline:
        chipColor = Colors.green;
        chipIcon = Icons.location_on;
        break;
      case EventMode.hybrid:
        chipColor = Colors.orange;
        chipIcon = Icons.merge_type;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            _getEventModeDisplayName(event.mode ?? EventMode.online),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Event Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (event.startDate != null || event.startTime != null) ...[
            _buildInfoRow(
              Icons.calendar_today,
              'Start',
              _formatDateTimeDisplay(event.startDate, event.startTime),
            ),
            const Divider(height: 30),
          ],
          if (event.endDate != null || event.endTime != null) ...[
            _buildInfoRow(
              Icons.event,
              'End',
              _formatDateTimeDisplay(event.endDate, event.endTime),
            ),
            const Divider(height: 30),
          ],
          _buildInfoRow(
            Icons.category,
            'Category',
            _getCategoryDisplayName(event.category ?? EventCategory.other),
          ),
          const Divider(height: 30),
          _buildInfoRow(
            Icons.computer,
            'Mode',
            _getEventModeDisplayName(event.mode ?? EventMode.offline),
          ),
          const Divider(height: 30),
          _buildInfoRow(Icons.people, 'Capacity', '${event.maxAttendees}'),
          const Divider(height: 30),
          _buildInfoRow(
            Icons.person,
            'Organizer',
            event.organizerName ?? 'Unknown',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'About This Event',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Icon(
                event.mode == EventMode.online
                    ? Icons.videocam
                    : Icons.location_on,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                event.mode == EventMode.online ? 'Online Event' : 'Venue',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.venue ?? 'TBD',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          if (event.meetingLink != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchUrl(event.meetingLink!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Join Meeting',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: Colors.blue[600]),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesSection(Event event) {
    if (event.images.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Icon(Icons.image, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Images (${event.images.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (event.images.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: event.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: event.images[index].isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[500],
                                    size: 40,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[500],
                              size: 40,
                            ),
                          ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                'No images available',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideosSection(Event event) {
    if (event.videos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Icon(Icons.videocam, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Videos (${event.videos.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (event.videos.isNotEmpty) ...[
            Column(
              children: event.videos.map((videoUrl) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _launchUrl(videoUrl),
                    child: Container(
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
                                  : 'Video ${event.videos.indexOf(videoUrl) + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: Colors.blue[500],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                'No videos available',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget _buildContactInfo(Event event) {
  //   if (event.contactEmail == null && event.contactPhone == null) {
  //     return const SizedBox.shrink();
  //   }

  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(15),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.contact_support, size: 20, color: Colors.grey[600]),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Contact Information',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 15),
  //         if (event.contactEmail != null) ...[
  //           InkWell(
  //             onTap: () => _launchUrl('mailto:${event.contactEmail}'),
  //             child: Row(
  //               children: [
  //                 Icon(Icons.email, size: 18, color: Colors.grey[600]),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Text(
  //                     event.contactEmail!,
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 14,
  //                       color: Colors.blue[600],
  //                       decoration: TextDecoration.underline,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           if (event.contactPhone != null) const SizedBox(height: 12),
  //         ],
  //         if (event.contactPhone != null) ...[
  //           InkWell(
  //             onTap: () => _launchUrl('tel:${event.contactPhone}'),
  //             child: Row(
  //               children: [
  //                 Icon(Icons.phone, size: 18, color: Colors.grey[600]),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Text(
  //                     event.contactPhone!,
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 14,
  //                       color: Colors.blue[600],
  //                       decoration: TextDecoration.underline,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildActionButtons(BuildContext context, Event event) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: ElevatedButton.icon(
  //           onPressed: () => _editEvent(context),
  //           icon: const Icon(Icons.edit, size: 18),
  //           label: Text(
  //             'Edit Event',
  //             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
  //           ),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Theme.of(context).primaryColor,
  //             foregroundColor: Colors.white,
  //             padding: const EdgeInsets.symmetric(vertical: 15),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 15),
  //       Expanded(
  //         child: OutlinedButton.icon(
  //           onPressed: () => _deleteEvent(context),
  //           icon: const Icon(Icons.delete, size: 18, color: Colors.red),
  //           label: Text(
  //             'Delete Event',
  //             style: GoogleFonts.poppins(
  //               fontWeight: FontWeight.w600,
  //               color: Colors.red,
  //             ),
  //           ),
  //           style: OutlinedButton.styleFrom(
  //             side: const BorderSide(color: Colors.red),
  //             padding: const EdgeInsets.symmetric(vertical: 15),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // void _editEvent(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => CreateEditEventPage(event: _event!),
  //     ),
  //   );
  // }

  // void _deleteEvent(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(
  //         'Delete Event',
  //         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
  //       ),
  //       content: Text(
  //         'Are you sure you want to delete "${_event!.title}"? This action cannot be undone.',
  //         style: GoogleFonts.poppins(),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(
  //             'Cancel',
  //             style: GoogleFonts.poppins(),
  //           ),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             final success = await context.read<EventProvider>().deleteEvent(_event!.id);
  //             if (success && context.mounted) {
  //               Navigator.pop(context);
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Event deleted successfully'),
  //                   backgroundColor: Colors.green,
  //                 ),
  //               );
  //             } else if (context.mounted) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Failed to delete event'),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //             }
  //           },
  //           child: Text(
  //             'Delete',
  //             style: GoogleFonts.poppins(color: Colors.red),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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

  String _getEventModeDisplayName(EventMode mode) {
    switch (mode) {
      case EventMode.online:
        return 'Online';
      case EventMode.offline:
        return 'In-Person';
      case EventMode.hybrid:
        return 'Hybrid';
    }
  }

  String _formatDateTimeDisplay(DateTime? date, String? time) {
    String result = '';

    // Add date part if available
    if (date != null) {
      result = DateFormat('MMM dd, yyyy').format(date);
    }

    // Add time part if available
    if (time != null && time.isNotEmpty) {
      final formattedTime = _formatTime12Hour(time);
      if (result.isNotEmpty) {
        result += ' • $formattedTime';
      } else {
        result = formattedTime;
      }
    }

    return result.isNotEmpty ? result : 'TBD';
  }

  String _formatTime12Hour(String time24) {
    try {
      final timeParts = time24.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

        return '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // If parsing fails, return original time
      return time24;
    }
    return time24;
  }
}
