import 'package:flutter/material.dart';
import '../../services/event_service.dart';
import '../../models/event.dart';
import 'event_details_page.dart';

class EnrolledEventsPage extends StatefulWidget {
  const EnrolledEventsPage({super.key});

  @override
  _EnrolledEventsPageState createState() => _EnrolledEventsPageState();
}

class _EnrolledEventsPageState extends State<EnrolledEventsPage> {
  final EventService _eventService = EventService();
  
  @override
  void initState() {
    super.initState();
    _eventService.addListener(_onEventServiceChanged);
    _loadEnrolledEvents();
  }

  @override
  void dispose() {
    _eventService.removeListener(_onEventServiceChanged);
    super.dispose();
  }

  void _onEventServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadEnrolledEvents() async {
    await _eventService.getEnrolledEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1B69),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F299E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5F299E)),
            onPressed: _loadEnrolledEvents,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F4FB),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_eventService.isLoadingEnrolled) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F299E)),
        ),
      );
    }

    if (_eventService.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _eventService.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEnrolledEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_eventService.enrolledEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF5F299E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.event_busy,
                size: 64,
                color: Color(0xFF5F299E),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Enrolled Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t enrolled in any events yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Browse Events'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEnrolledEvents,
      color: const Color(0xFF5F299E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_eventService.enrolledEvents.length} Event${_eventService.enrolledEvents.length != 1 ? 's' : ''} Enrolled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _eventService.enrolledEvents.length,
              itemBuilder: (context, index) {
                final event = _eventService.enrolledEvents[index];
                return _buildEventCard(event);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(
                eventId: event.id,
                eventTitle: event.title,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFF5F299E).withOpacity(0.1),
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.event,
                            size: 64,
                            color: Color(0xFF5F299E),
                          );
                        },
                      )
                    : const Icon(
                        Icons.event,
                        size: 64,
                        color: Color(0xFF5F299E),
                      ),
              ),
            ),
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1B69),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Event Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F299E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5F299E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Event Date and Time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF5F299E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_formatDate(event.date)} at ${event.time}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Event Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF5F299E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Enrollment Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Enrolled',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        event.price == 0 ? 'FREE' : '₹${event.price?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: event.price == 0 ? Colors.green : const Color(0xFF5F299E),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0 && difference <= 7) {
      return 'In $difference day${difference > 1 ? 's' : ''}';
    } else if (difference < 0 && difference >= -7) {
      return '${difference.abs()} day${difference.abs() > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
