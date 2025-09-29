import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final String? eventTitle;

  const EventDetailsPage({super.key, required this.eventId, this.eventTitle});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventService _eventService = EventService();
  Event? _event;
  bool _isLoading = true;
  bool _isEnrolling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  @override
  void didUpdateWidget(EventDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId ||
        oldWidget.eventTitle != widget.eventTitle) {
      _loadEventDetails();
    }
  }

  Future<void> _loadEventDetails() async {
    if (widget.eventTitle == null || widget.eventTitle!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Event title is required to load details';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final event = await _eventService.getEventDetails(widget.eventTitle!);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load event details: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _enrollInEvent() async {
    if (_event == null) return;

    setState(() {
      _isEnrolling = true;
    });

    try {
      final success = await _eventService.enrollInEvent(_event!.id);
      if (success) {
        if (mounted) {
          setState(() {
            _event = _event!.copyWith(
              isRegistered: true,
              currentParticipants: _event!.currentParticipants + 1,
            );
            _isEnrolling = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully enrolled in ${_event!.title}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isEnrolling = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to enroll. The event might be full or you may already be enrolled.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.eventTitle ?? 'Event Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.black : Colors.white,
            fontSize: 20,
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
        iconTheme: IconThemeData(color: isDark ? Colors.black : Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F299E)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading event details...',
              style: TextStyle(
                color: Color(0xFF5F299E),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Event',
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
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEventDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return const Center(
        child: Text(
          'Event not found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          _buildEventImage(),

          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Category
                _buildTitleSection(),
                const SizedBox(height: 16),

                // Description
                _buildDescriptionSection(),
                const SizedBox(height: 16),

                // Event Info
                _buildEventInfoSection(),
                const SizedBox(height: 16),

                // Contact Information
                _buildContactSection(),
                const SizedBox(height: 16),

                // Price Information
                if (_event!.price != null) _buildPriceSection(),
                if (_event!.price != null) const SizedBox(height: 16),

                // Images Gallery
                if (_event!.images != null && _event!.images!.isNotEmpty)
                  _buildImagesSection(),
                if (_event!.images != null && _event!.images!.isNotEmpty)
                  const SizedBox(height: 16),

                // Videos Section
                if (_event!.videos != null && _event!.videos!.isNotEmpty)
                  _buildVideosSection(),
                if (_event!.videos != null && _event!.videos!.isNotEmpty)
                  const SizedBox(height: 16),

                // Participants Info
                _buildParticipantsSection(),
                const SizedBox(height: 24),

                // Enroll Button
                _buildEnrollButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventImage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _event!.imageUrl ?? 'assets/images/default_event.png',
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
                  child: Icon(
                    Icons.event,
                    size: 80,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                );
              },
            ),
            // Status Badges
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _event!.isToday
                          ? Colors.orange
                          : _event!.isUpcoming
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _event!.isToday
                          ? 'TODAY'
                          : _event!.isUpcoming
                          ? 'UPCOMING'
                          : 'PAST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_event!.isRegistered) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ENROLLED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Text(
            _event!.title,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2D1B69),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5F299E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _event!.category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Color(0xFF2D1B69),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _event!.description,
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEventInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            '${_event!.date.day}/${_event!.date.month}/${_event!.date.year}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Time', _event!.time),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Location', _event!.location),
          if (_event!.organizerName != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Organizer', _event!.organizerName!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF5F299E),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Color(0xFF2D1B69),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_event!.currentParticipants} / ${_event!.maxParticipants} enrolled',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _event!.participationPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _event!.participationPercentage > 0.8
                            ? Colors.red
                            : const Color(0xFF5F299E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(_event!.participationPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF5F299E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollButton() {
    if (_event!.isPast) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Event has ended',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (_event!.isRegistered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Already Enrolled',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (_event!.isFull) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Event is Full',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isEnrolling ? null : _enrollInEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5F299E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isEnrolling
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Enrolling...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text(
                'Enroll Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildContactSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 12),

          // Contact Phone
          if (_event!.contactPhone != null) ...[
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 20,
                  color: isDark ? Colors.white : Color(0xFF5F299E),
                ),
                const SizedBox(width: 8),
                Text(
                  _event!.contactPhone!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Contact Email
          if (_event!.contactEmail != null) ...[
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 20,
                  color: isDark ? Colors.white : Color(0xFF5F299E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _event!.contactEmail!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 20,
                color: isDark ? Colors.white : Color(0xFF5F299E),
              ),
              const SizedBox(width: 8),
              Text(
                _event!.price == 0
                    ? 'FREE'
                    : '₹${_event!.price!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _event!.price == 0 ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 12),

          // Images Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _event!.images!.length > 4 ? 4 : _event!.images!.length,
            itemBuilder: (context, index) {
              final image = _event!.images![index];
              String imageUrl = '';
              String imageName = 'Image ${index + 1}';

              // Try to extract image info if available
              if (image is Map<String, dynamic>) {
                imageUrl = image['url'] ?? image['filename'] ?? '';
                imageName =
                    image['originalName'] ?? image['filename'] ?? imageName;
              } else if (image is String) {
                imageUrl = image;
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey,
                ),
                child: Stack(
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          );
                        },
                      )
                    else
                      const Icon(Icons.image, size: 40, color: Colors.grey),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (_event!.images!.length > 4) ...[
            const SizedBox(height: 8),
            Text(
              '+${_event!.images!.length - 4} more images',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideosSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2e2d2f) : const Color(0xFFF6F4FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 12),

          // Videos List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _event!.videos!.length,
            itemBuilder: (context, index) {
              final video = _event!.videos![index];
              String videoTitle = 'Video ${index + 1}';
              String videoDescription = 'Tap to play';

              // Try to extract video info if available
              if (video is Map<String, dynamic>) {
                videoTitle = video['title'] ?? video['name'] ?? videoTitle;
                videoDescription = video['description'] ?? videoDescription;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      size: 40,
                      color: isDark ? Colors.white : Color(0xFF5F299E),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            videoTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            videoDescription,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
