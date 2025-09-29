import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report_model.dart';
import 'reporting_analytics_service.dart';
import '../core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportRepository {
  ReportingAnalyticsService? _service;

  Future<void> _ensureService() async {
    if (_service != null) return;
    final prefs = await SharedPreferences.getInstance();
    final apiClient = ApiClient(prefs);
    _service = ReportingAnalyticsService(apiClient);
  }

  Future<List<EventReport>> getReports() async {
    await _ensureService();
    return await _service!.listReports(page: 1, limit: 50);
  }

  Future<EventReport?> getReportById(String id) async {
    await _ensureService();
    try {
      return await _service!.getReport(id);
    } catch (_) {
      return null;
    }
  }

  // Generate Excel report
  Future<Uint8List> generateExcelReport(EventReport report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow([
      'Event Name',
      'Date',
      'Total Attendees',
      'Checked In',
      'Check-in Rate',
    ]);

    // Add data
    sheet.appendRow([
      report.eventName,
      report.date.toString().split(' ')[0],
      report.totalAttendees,
      report.checkedInAttendees,
      '${report.attendanceRate.toStringAsFixed(1)}%',
    ]);

    // Add summary rows
    sheet.appendRow(['']);
    sheet.appendRow(['Summary']);
    sheet.appendRow(['Total Attendees', report.totalAttendees]);
    sheet.appendRow(['Checked In', report.checkedInAttendees]);
    sheet.appendRow([
      'Attendance Rate',
      '${report.attendanceRate.toStringAsFixed(1)}%',
    ]);

    // Generate the Excel file and convert to Uint8List
    final excelBytes = excel.encode();
    if (excelBytes == null) {
      throw Exception('Failed to generate Excel file');
    }
    return Uint8List.fromList(excelBytes);
  }

  // Generate PDF report
  Future<Uint8List> generatePdfReport(EventReport report) async {
    final pdf = pw.Document();

    // Load a font
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Event Report: ${report.eventName}'),
          ),
          pw.Header(level: 1, child: pw.Text('Attendance Summary')),
          pw.Paragraph(text: 'Date: ${report.date.toString().split(' ')[0]}'),
          pw.Paragraph(text: 'Total Attendees: ${report.totalAttendees}'),
          pw.Paragraph(text: 'Checked In: ${report.checkedInAttendees}'),
          pw.Paragraph(
            text:
                'Attendance Rate: ${report.attendanceRate.toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Attendance List')),
          pw.Table.fromTextArray(
            headers: ['Name', 'Email', 'Checked In', 'Check-in Time'],
            data: report.attendanceData
                .map(
                  (a) => [
                    a['name'],
                    a['email'],
                    (a['checkedIn'] as bool) ? 'Yes' : 'No',
                    a['checkInTime']?.toString() ?? 'N/A',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
