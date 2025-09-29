import 'package:flutter/material.dart';

class SessionLibraryScreen extends StatefulWidget {
  const SessionLibraryScreen({super.key});

  @override
  State<SessionLibraryScreen> createState() => _SessionLibraryScreenState();
}

class _SessionLibraryScreenState extends State<SessionLibraryScreen> {
  final List<SessionData> _sessions = [
    SessionData(
      title: 'Course Introduction',
      date: 'Aug 20, 2025',
      time: '10:00 AM - 11:30 AM',
      duration: '1h 30m',
      participants: 18,
      hasRecording: true,
      hasAttendanceReport: true,
      hasEngagementReport: true,
    ),
    SessionData(
      title: 'JavaScript Basics',
      date: 'Aug 18, 2025',
      time: '02:00 PM - 03:30 PM',
      duration: '1h 30m',
      participants: 14,
      hasRecording: true,
      hasAttendanceReport: true,
      hasEngagementReport: true,
    ),
    SessionData(
      title: 'Database Design',
      date: 'Aug 15, 2025',
      time: '11:00 AM - 12:30 PM',
      duration: '1h 30m',
      participants: 10,
      hasRecording: true,
      hasAttendanceReport: true,
      hasEngagementReport: false,
    ),
    SessionData(
      title: 'UI/UX Fundamentals',
      date: 'Aug 12, 2025',
      time: '09:30 AM - 11:00 AM',
      duration: '1h 30m',
      participants: 16,
      hasRecording: true,
      hasAttendanceReport: false,
      hasEngagementReport: false,
    ),
    SessionData(
      title: 'Project Planning',
      date: 'Aug 10, 2025',
      time: '03:00 PM - 04:00 PM',
      duration: '1h',
      participants: 12,
      hasRecording: false,
      hasAttendanceReport: true,
      hasEngagementReport: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Library'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F299E).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam, color: Color(0xFF5F299E)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  session.date,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  session.time,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
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

                // Session details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Details section
                      Row(
                        children: [
                          _buildDetailItem(
                            icon: Icons.timer,
                            label: 'Duration',
                            value: session.duration,
                          ),
                          const SizedBox(width: 24),
                          _buildDetailItem(
                            icon: Icons.people,
                            label: 'Participants',
                            value: '${session.participants}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Available resources section
                      const Text(
                        'Available Resources',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (session.hasRecording)
                            _buildResourceChip(
                              icon: Icons.videocam,
                              label: 'Recording',
                            ),
                          if (session.hasAttendanceReport)
                            _buildResourceChip(
                              icon: Icons.people,
                              label: 'Attendance Report',
                            ),
                          if (session.hasEngagementReport)
                            _buildResourceChip(
                              icon: Icons.insights,
                              label: 'Engagement Report',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Actions section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (session.hasRecording)
                            OutlinedButton.icon(
                              onPressed: () {
                                // Play recording
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play Recording'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5F299E),
                                side: const BorderSide(
                                  color: Color(0xFF5F299E),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Reuse session plan
                              _showReuseSessionDialog(context, session);
                            },
                            icon: const Icon(Icons.content_copy),
                            label: const Text('Reuse Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5F299E),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF5F299E)),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFF5F299E).withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showReuseSessionDialog(BuildContext context, SessionData session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reuse Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a new meeting using the plan from:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              session.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'New Meeting Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter title for the new meeting',
              ),
              controller: TextEditingController(
                text: '${session.title} (Copy)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.access_time),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F299E),
            ),
            onPressed: () {
              // Create a new meeting with this session plan
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New meeting created successfully'),
                ),
              );
            },
            child: const Text('Create Meeting'),
          ),
        ],
      ),
    );
  }
}

class SessionData {
  final String title;
  final String date;
  final String time;
  final String duration;
  final int participants;
  final bool hasRecording;
  final bool hasAttendanceReport;
  final bool hasEngagementReport;

  SessionData({
    required this.title,
    required this.date,
    required this.time,
    required this.duration,
    required this.participants,
    required this.hasRecording,
    required this.hasAttendanceReport,
    required this.hasEngagementReport,
  });
}
