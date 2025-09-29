import 'package:flutter/material.dart';

class MeetingDetailPage extends StatelessWidget {
  final MeetingDetailData meeting;

  const MeetingDetailPage({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Library'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
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
                              meeting.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meeting.date,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meeting.time,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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
                            value: meeting.duration,
                          ),
                          const SizedBox(width: 24),
                          _buildDetailItem(
                            icon: Icons.people,
                            label: 'Participants',
                            value: '${meeting.participants}',
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
                          if (meeting.hasRecording)
                            _buildResourceChip(
                              icon: Icons.videocam,
                              label: 'Recording',
                            ),
                          if (meeting.hasAttendanceReport)
                            _buildResourceChip(
                              icon: Icons.people,
                              label: 'Attendance Report',
                            ),
                          if (meeting.hasEngagementReport)
                            _buildResourceChip(
                              icon: Icons.insights,
                              label: 'Engagement Report',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Actions section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (meeting.hasRecording)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Play recording
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Playing recording...'),
                                    ),
                                  );
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
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Reuse session plan
                                _showReuseSessionDialog(context, meeting);
                              },
                              icon: const Icon(Icons.content_copy),
                              label: const Text('Reuse Session'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5F299E),
                                foregroundColor: Colors.white,
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
        ],
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

  void _showReuseSessionDialog(BuildContext context, MeetingDetailData meeting) {
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
              meeting.title,
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
                text: '${meeting.title} (Copy)',
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

class MeetingDetailData {
  final String title;
  final String date;
  final String time;
  final String duration;
  final int participants;
  final bool hasRecording;
  final bool hasAttendanceReport;
  final bool hasEngagementReport;

  MeetingDetailData({
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