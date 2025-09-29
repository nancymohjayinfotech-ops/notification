import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _event; // backend event
  Map<String, dynamic>? _stats; // stats block
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await ApiService.getEventById(widget.eventId);
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _event = data['event'] as Map<String, dynamic>?;
        _stats = data['stats'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res['message']?.toString() ?? 'Failed to load event details';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF181820) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF23232B) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : const Color(0xFF9C27B0),
                ),
              ),
            )
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: textColor)),
            )
          : _event == null
          ? Center(
              child: Text('No event found', style: TextStyle(color: textColor)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 16),
                  _buildMedia(
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  _buildMeta(
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  const SizedBox(height: 16),
                  if (_stats != null)
                    _buildStats(
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color cardColor,
  }) {
    final title = (_event?['title'] ?? '').toString();
    final category = (_event?['category'] ?? '').toString();
    final price = _event?['price'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(category, style: TextStyle(color: subtitleColor)),
            ],
          ),
        ),
        if (price != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '₹${(price as num).toDouble().toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FREE',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMedia({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final List rawImages = (_event?['images'] as List?) ?? const [];
    final List rawVideos = (_event?['videos'] as List?) ?? const [];

    // Debug: Print raw images format
    if (rawImages.isNotEmpty) {
      print('DEBUG: Raw images format: $rawImages');
      print('DEBUG: First image type: ${rawImages.first.runtimeType}');
    }

    // Parse image URLs from the new response format
    List<String> imageUrls = [];
    for (var item in rawImages) {
      if (item is Map<String, dynamic> && item['url'] != null) {
        // New format: {"url": "/uploads/events/...", "filename": "...", etc}
        imageUrls.add(item['url'].toString());
      } else if (item is String) {
        // Fallback for old format
        if (item.startsWith('http') || item.startsWith('/')) {
          // Direct URL
          imageUrls.add(item);
        } else {
          // Try regex parsing for old stringified format
          RegExp urlRegex = RegExp(r'url:\s*([^,}]+)');
          Match? match = urlRegex.firstMatch(item);
          if (match != null) {
            String url = match.group(1)!.trim();
            imageUrls.add(url);
          }
        }
      }
    }

    // Parse video URLs from the new response format
    List<String> videoUrls = [];
    for (var item in rawVideos) {
      if (item is Map<String, dynamic> && item['url'] != null) {
        // New format: {"url": "/uploads/events/...", "filename": "...", etc}
        videoUrls.add(item['url'].toString());
      } else if (item is String) {
        // Fallback for old format
        if (item.startsWith('http') || item.startsWith('/')) {
          // Direct URL
          videoUrls.add(item);
        } else {
          // Try regex parsing for old stringified format
          RegExp urlRegex = RegExp(r'url:\s*([^,}]+)');
          Match? match = urlRegex.firstMatch(item);
          if (match != null) {
            String url = match.group(1)!.trim();
            videoUrls.add(url);
          }
        }
      }
    }

    // Debug: Print parsed URLs
    if (imageUrls.isNotEmpty) {
      print('DEBUG: Parsed image URLs: $imageUrls');
      print(
        'DEBUG: Full URLs will be: ${imageUrls.map((url) => _fullUrl(url)).toList()}',
      );
    }

    if (imageUrls.isEmpty && videoUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrls.isNotEmpty) ...[
          Text(
            'Images (${imageUrls.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final String url = imageUrls[index];
                return GestureDetector(
                  onTap: () => _showImageDialog(context, _fullUrl(url)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _fullUrl(url),
                      width: 220,
                      height: 140,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 220,
                          height: 140,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) => Container(
                        width: 220,
                        height: 140,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(
                              'Failed to load',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (videoUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Videos (${videoUrls.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...videoUrls.map((v) {
            final String url = v.toString();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_library, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_fullUrl(url), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMeta({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final desc = (_event?['description'] ?? '').toString();
    final location = (_event?['location'] ?? '').toString();
    final eventType = (_event?['eventType'] ?? '').toString();
    final startDate = DateTime.tryParse(
      (_event?['startDate'] ?? '').toString(),
    );
    final endDate = DateTime.tryParse((_event?['endDate'] ?? '').toString());
    final startTime = (_event?['startTime'] ?? '').toString();
    final endTime = (_event?['endTime'] ?? '').toString();
    final registrationDeadline = DateTime.tryParse(
      (_event?['registrationDeadline'] ?? '').toString(),
    );
    final maxParticipants = _event?['maxParticipants'];
    final isActive = _event?['isActive'] ?? false;
    final slug = (_event?['slug'] ?? '').toString();
    final createdAt = DateTime.tryParse(
      (_event?['createdAt'] ?? '').toString(),
    );
    final updatedAt = DateTime.tryParse(
      (_event?['updatedAt'] ?? '').toString(),
    );
    final deletedAt = DateTime.tryParse(
      (_event?['deletedAt'] ?? '').toString(),
    );

    // Additional fields
    final contactEmail = (_event?['contactEmail'] ?? '').toString();
    final contactPhone = (_event?['contactPhone'] ?? '').toString();
    final meetingLink = (_event?['meetingLink'] ?? '').toString();
    final resources = (_event?['resources'] as List?) ?? [];
    final eventId = (_event?['_id'] ?? _event?['id'] ?? '').toString();
    final version = _event?['__v'];
    final venue = (_event?['venue'] ?? '').toString();
    final duration = _event?['duration'];
    final language = (_event?['language'] ?? '').toString();
    final requirements = (_event?['requirements'] ?? '').toString();
    final certificate = _event?['certificate'] ?? false;
    final featured = _event?['featured'] ?? false;

    String startDateDisplay = '';
    if (startDate != null) {
      startDateDisplay = DateFormat('MMM dd, yyyy').format(startDate);
      if (startTime.isNotEmpty) startDateDisplay += ' at $startTime';
    }

    String endDateDisplay = '';
    if (endDate != null) {
      endDateDisplay = DateFormat('MMM dd, yyyy').format(endDate);
      if (endTime.isNotEmpty) endDateDisplay += ' at $endTime';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Description
          if (desc.isNotEmpty) ...[
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 12),
          ],

          // Location
          if (location.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Color(0xFF9C27B0),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Location: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Venue
          if (venue.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.business, size: 18, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text(
                  'Venue: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    venue,
                    style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Event Type
          if (eventType.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.event_available,
                  size: 18,
                  color: Color(0xFF9C27B0),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Type: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: eventType.toLowerCase() == 'online'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    eventType.toUpperCase(),
                    style: TextStyle(
                      color: eventType.toLowerCase() == 'online'
                          ? Colors.green
                          : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Start Date & Time
          if (startDateDisplay.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text(
                  'Starts: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  startDateDisplay,
                  style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // End Date & Time
          if (endDateDisplay.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: Color(0xFF9C27B0),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Ends: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  endDateDisplay,
                  style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Registration Deadline
          if (registrationDeadline != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFFFF5722),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Registration Deadline: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(registrationDeadline),
                  style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Max Participants
          if (maxParticipants != null) ...[
            Row(
              children: [
                const Icon(Icons.people, size: 18, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text(
                  'Max Participants: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  maxParticipants.toString(),
                  style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Status
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF9C27B0),
              ),
              const SizedBox(width: 6),
              const Text(
                'Status: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Duration
          if (duration != null) ...[
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text(
                  'Duration: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$duration minutes',
                  style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Language
          if (language.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.language, size: 18, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text(
                  'Language: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(language, style: TextStyle(color: isDark ? Colors.white: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Contact Information
          if (contactEmail.isNotEmpty || contactPhone.isNotEmpty) ...[
            const Text(
              'Contact Information:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            if (contactEmail.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.email, size: 18, color: Color(0xFF9C27B0)),
                  const SizedBox(width: 6),
                  const Text(
                    'Email: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Text(
                      contactEmail,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (contactPhone.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Color(0xFF9C27B0)),
                  const SizedBox(width: 6),
                  const Text(
                    'Phone: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    contactPhone,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
          ],

          // Meeting Link
          if (meetingLink.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.video_call,
                  size: 18,
                  color: Color(0xFF9C27B0),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Meeting Link: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    meetingLink,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Requirements
          if (requirements.isNotEmpty) ...[
            const Text(
              'Requirements:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(requirements, style: TextStyle(color: isDark ? Colors.white: Colors.black87)),
            const SizedBox(height: 8),
          ],

          // Resources
          if (resources.isNotEmpty) ...[
            const Text(
              'Resources:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...resources.map(
              (resource) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        resource.toString(),
                        style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Additional Flags
          Row(
            children: [
              if (certificate) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Certificate',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (featured) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.purple),
                      SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Slug
          if (slug.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.link, size: 18, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text(
                  'Slug: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    slug,
                    style: TextStyle(color: isDark ? Colors.white: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Event ID and Version (for debugging/admin)
          if (eventId.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.fingerprint, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  'ID: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: Text(
                    eventId,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (version != null) ...[
            Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  'Version: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'v$version',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Created By
          if (_event?['createdBy'] != null) ...[
            const Text(
              'Created By:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            _buildCreatedBy(),
            const SizedBox(height: 12),
          ],

          // Timestamps
          const Text(
            'Timestamps:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          if (createdAt != null) ...[
            Text(
              'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}',
              style: TextStyle(color: isDark ? Colors.white: Colors.black87, fontSize: 13),
            ),
          ],
          if (updatedAt != null) ...[
            Text(
              'Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(updatedAt)}',
              style: TextStyle(color: isDark ? Colors.white: Colors.black87, fontSize: 13),
            ),
          ],
          if (deletedAt != null) ...[
            Text(
              'Deleted: ${DateFormat('MMM dd, yyyy HH:mm').format(deletedAt)}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],

          const SizedBox(height: 12),
          _buildTags(),
        ],
      ),
    );
  }

  Widget _buildCreatedBy() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createdBy = _event?['createdBy'] as Map<String, dynamic>?;
    if (createdBy == null) return const SizedBox.shrink();

    final name = (createdBy['name'] ?? '').toString();
    final email = (createdBy['email'] ?? '').toString();
    final avatar = createdBy['avatar'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF9C27B0),
            backgroundImage: avatar != null
                ? NetworkImage(_fullUrl(avatar.toString()))
                : null,
            child: avatar == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    final List tags = (_event?['tags'] as List?) ?? const [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((t) => Chip(label: Text(t.toString()))).toList(),
    );
  }

  Widget _buildStats({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _stats!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Statistics',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Enrollment Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enrollment Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                _statRow(
                  'Total Enrollments',
                  s['totalEnrollments'],
                  Icons.people,
                ),
                _statRow(
                  'Approved Enrollments',
                  s['approvedEnrollments'],
                  Icons.check_circle,
                  Colors.green,
                ),
                _statRow(
                  'Pending Enrollments',
                  s['pendingEnrollments'],
                  Icons.pending,
                  Colors.orange,
                ),
                _statRow(
                  'Declined Enrollments',
                  s['declinedEnrollments'],
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Capacity & Revenue Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Capacity & Revenue',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                _statRow(
                  'Available Slots',
                  s['availableSlots'],
                  Icons.event_seat,
                  Colors.green,
                ),
                _statRow(
                  'Total Revenue',
                  '₹${(s['revenue'] ?? 0).toString()}',
                  Icons.currency_rupee,
                  Colors.green,
                ),
              ],
            ),
          ),

          // Show enrollments if available
          if (_event?['enrollments'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Enrollments',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildEnrollments(),
          ],
        ],
      ),
    );
  }

  Widget _statRow(
    String label,
    Object? value, [
    IconData? icon,
    Color? iconColor,
  ]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.grey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(label, style: TextStyle(color: isDark ? Colors.black87 : Colors.white)),
          ),
          Text(
            value?.toString() ?? '-',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollments() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List enrollments = (_event?['enrollments'] as List?) ?? [];
    if (enrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'No enrollments yet',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      children: enrollments.map((enrollment) {
        final enrollmentData = enrollment as Map<String, dynamic>;

        // Debug: Print enrollment data structure
        print('DEBUG: Enrollment data: $enrollmentData');

        // Extract user data - try different possible structures
        String userName = 'Unknown User';
        String userEmail = '';
        String userPhone = '';
        String? userAvatar;

        // Try different possible data structures
        if (enrollmentData['student'] != null) {
          // Nested student object (correct structure from API)
          final student = enrollmentData['student'] as Map<String, dynamic>?;
          userName = student?['name']?.toString() ?? 'Unknown User';
          userEmail = student?['email']?.toString() ?? '';
          userPhone =
              student?['phoneNumber']?.toString() ??
              student?['phone']?.toString() ??
              '';
          userAvatar = student?['avatar']?.toString();
        } else if (enrollmentData['user'] != null) {
          // Nested user object (fallback)
          final user = enrollmentData['user'] as Map<String, dynamic>?;
          userName = user?['name']?.toString() ?? 'Unknown User';
          userEmail = user?['email']?.toString() ?? '';
          userPhone =
              user?['phoneNumber']?.toString() ??
              user?['phone']?.toString() ??
              '';
        } else {
          // Direct properties (fallback)
          userName =
              enrollmentData['name']?.toString() ??
              enrollmentData['userName']?.toString() ??
              enrollmentData['studentName']?.toString() ??
              'Unknown User';
          userEmail =
              enrollmentData['email']?.toString() ??
              enrollmentData['userEmail']?.toString() ??
              '';
          userPhone =
              enrollmentData['phoneNumber']?.toString() ??
              enrollmentData['phone']?.toString() ??
              '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF9C27B0),
                backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (userPhone.isNotEmpty)
                      Text(
                        userPhone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (enrollmentData['status'] != null)
                      Text(
                        'Status: ${enrollmentData['status']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.black54,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fullUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://'))
      return pathOrUrl;
    // join with baseUrl if relative
    return '${ApiService.baseUrl}$pathOrUrl';
  }
}
