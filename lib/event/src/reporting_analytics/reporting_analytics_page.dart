import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'report_model.dart';
import 'report_repository.dart';

class ReportingAnalyticsPage extends StatefulWidget {
  const ReportingAnalyticsPage({super.key});

  @override
  State<ReportingAnalyticsPage> createState() => _ReportingAnalyticsPageState();
}

class _ReportingAnalyticsPageState extends State<ReportingAnalyticsPage> {
  final ReportRepository _repository = ReportRepository();
  late Future<List<EventReport>> _reportsFuture;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _reportsFuture = _repository.getReports();
  }

  // Future<void> _exportReport(EventReport report, String format) async {
  //   try {
  //     Uint8List fileBytes;
  //     String fileName;
  //     String fileExtension;

  //     if (format == 'excel') {
  //       fileBytes = await _repository.generateExcelReport(report);
  //       fileName = '${report.eventName.replaceAll(' ', '_')}_report.xlsx';
  //       fileExtension = 'xlsx';
  //     } else {
  //       fileBytes = await _repository.generatePdfReport(report);
  //       fileName = '${report.eventName.replaceAll(' ', '_')}_report.pdf';
  //       fileExtension = 'pdf';
  //     }

  //     if (kIsWeb) {
  //       // For web - show message that web download is not implemented
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Web download not implemented yet'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //       return;
  //     }

  //     // For mobile and desktop
  //     final directory = await getApplicationDocumentsDirectory();
  //     final file = File('${directory.path}/$fileName');
  //     await file.writeAsBytes(fileBytes);
      
  //     if (Platform.isAndroid || Platform.isIOS) {
  //       // On mobile, use the share dialog
  //       await Share.shareXFiles(
  //         [XFile(file.path, mimeType: 'application/$fileExtension')],
  //         sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
  //       );
  //     } else {
  //       // On desktop, just show a success message
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Report saved to ${file.path}'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Report exported as $format'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error exporting report: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporting & Analytics'),
        elevation: 0,
      ),
      body: FutureBuilder<List<EventReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(child: Text('No reports available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(EventReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.eventName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _dateFormat.format(report.date),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatistic('Total', '${report.totalAttendees}'),
                _buildStatistic('Checked In', '${report.checkedInAttendees}'),
                _buildStatistic('Attendance', '${report.attendanceRate.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     TextButton.icon(
            //       onPressed: () => _exportReport(report, 'excel'),
            //       icon: const Icon(Icons.table_chart, size: 20),
            //       label: const Text('Export as Excel'),
            //       style: TextButton.styleFrom(
            //         foregroundColor: Colors.green,
            //       ),
            //     ),
            //     const SizedBox(width: 8),
            //     TextButton.icon(
            //       onPressed: () => _exportReport(report, 'pdf'),
            //       icon: const Icon(Icons.picture_as_pdf, size: 20),
            //       label: const Text('Export as PDF'),
            //       style: TextButton.styleFrom(
            //         foregroundColor: Colors.red,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
