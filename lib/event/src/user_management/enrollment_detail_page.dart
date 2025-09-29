import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'enrollment_api_service.dart';

class EnrollmentDetailPage extends StatefulWidget {
  final Enrollment enrollment;
  final String eventTitle;

  const EnrollmentDetailPage({
    super.key,
    required this.enrollment,
    required this.eventTitle,
  });

  @override
  State<EnrollmentDetailPage> createState() => _EnrollmentDetailPageState();
}

class _EnrollmentDetailPageState extends State<EnrollmentDetailPage> {
  bool _isUpdating = false;
  late Enrollment _enrollment;

  @override
  void initState() {
    super.initState();
    _enrollment = widget.enrollment;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enrollment Details',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              if (_enrollment.status.toLowerCase() == 'pending') ...[
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Approve'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'decline',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Decline'),
                    ],
                  ),
                ),
              ] else if (_enrollment.status.toLowerCase() == 'approved') ...[
                const PopupMenuItem(
                  value: 'decline',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Decline'),
                    ],
                  ),
                ),
              ] else if (_enrollment.status.toLowerCase() == 'declined') ...[
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Approve'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventInfoCard(isDark),
            const SizedBox(height: 20),
            _buildUserInfoCard(isDark),
            const SizedBox(height: 20),
            _buildEnrollmentInfoCard(isDark),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfoCard(bool isDark) {
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
          Row(
            children: [
              Icon(
                Icons.event,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Event Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.eventTitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Event ID: ${_enrollment.eventId}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(bool isDark) {
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
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                backgroundImage: _enrollment.userAvatar != null
                    ? NetworkImage(_enrollment.userAvatar!)
                    : null,
                child: _enrollment.userAvatar == null
                    ? Text(
                        _enrollment.userName.isNotEmpty
                            ? _enrollment.userName[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _enrollment.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _enrollment.userEmail,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_enrollment.college != null &&
              _enrollment.college!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.school,
              'Organization',
              _enrollment.college!,
              isDark,
            ),
          ],
          if (_enrollment.phoneNumber != null &&
              _enrollment.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              _enrollment.phoneNumber!,
              isDark,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, 'User ID', _enrollment.userId, isDark),
        ],
      ),
    );
  }

  Widget _buildEnrollmentInfoCard(bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (_enrollment.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

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
          Row(
            children: [
              Icon(
                Icons.assignment,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Enrollment Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Status: ',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      _enrollment.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Enrolled At',
            DateFormat('MMM dd, yyyy - hh:mm a').format(_enrollment.enrolledAt),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.fingerprint,
            'Enrollment ID',
            _enrollment.id,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, [
    bool isDark = false,
  ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_enrollment.status.toLowerCase() == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Decline',
              Icons.cancel,
              Colors.red,
              () => _updateEnrollmentStatus('declined'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Approve',
              Icons.check_circle,
              Colors.green,
              () => _updateEnrollmentStatus('approved'),
            ),
          ),
        ],
      );
    } else if (_enrollment.status.toLowerCase() == 'approved') {
      return _buildActionButton(
        'Decline',
        Icons.cancel,
        Colors.red,
        () => _updateEnrollmentStatus('declined'),
      );
    } else if (_enrollment.status.toLowerCase() == 'declined') {
      return _buildActionButton(
        'Approve',
        Icons.check_circle,
        Colors.green,
        () => _updateEnrollmentStatus('approved'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isUpdating ? null : onPressed,
      icon: _isUpdating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        _isUpdating ? 'Updating...' : text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );
  }

  void _handleMenuAction(String action) {
    if (action == 'approve') {
      _updateEnrollmentStatus('approved');
    } else if (action == 'decline') {
      _updateEnrollmentStatus('declined');
    }
  }

  Future<void> _updateEnrollmentStatus(String newStatus) async {
    if (_isUpdating) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(newStatus);
    if (!confirmed) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Mock API call - replace with actual enrollment status update
      await Future.delayed(const Duration(milliseconds: 500));

      // Update local enrollment status by creating a new Enrollment object
      setState(() {
        _enrollment = Enrollment(
          id: _enrollment.id,
          userId: _enrollment.userId,
          eventId: _enrollment.eventId,
          userName: _enrollment.userName,
          userEmail: _enrollment.userEmail,
          userAvatar: _enrollment.userAvatar,
          status: newStatus,
          enrolledAt: _enrollment.enrolledAt,
          college: _enrollment.college,
          phoneNumber: _enrollment.phoneNumber,
        );
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enrollment ${newStatus.toLowerCase()} successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to refresh the list
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update enrollment: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog(String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              '${action == 'approved' ? 'Approve' : 'Decline'} Enrollment',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to ${action == 'approved' ? 'approve' : 'decline'} ${_enrollment.userName}\'s enrollment for "${widget.eventTitle}"?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'approved'
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  action == 'approved' ? 'Approve' : 'Decline',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
