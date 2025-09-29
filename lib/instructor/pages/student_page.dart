import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertest/instructor/pages/instructor_login_page.dart';

class StudentPage extends StatefulWidget {
  final bool isInDashboard;

  const StudentPage({super.key, this.isInDashboard = false});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class Student {
  final String name;
  final String id; // MongoDB _id (internal use only)
  final String studentId; // shown in UI
  final String enrolledCourse;
  final String email;
  final String phone;
  String status;

  Student(
    this.name,
    this.id,
    this.studentId,
    this.enrolledCourse,
    this.email,
    this.phone,
    this.status,
  );

  factory Student.fromJson(Map<String, dynamic> json) {
    String status = (json['isActive'] == true) ? "Active" : "Inactive";

    String enrolledCourse = "N/A";
    if (json['courses'] != null &&
        json['courses'] is List &&
        json['courses'].isNotEmpty) {
      enrolledCourse = json['courses'][0]['title'] ?? "N/A";
    }

    return Student(
      json['name'] ?? "Unknown",
      json['_id'] ?? "N/A",
      json['studentId'] ?? "N/A",
      enrolledCourse,
      json['email'] ?? "N/A",
      json['phone'] ?? "N/A",
      status,
    );
  }
}

class _StudentPageState extends State<StudentPage> {
  List<Student> students = [];
  String searchQuery = '';
  String selectedStatus = 'All';
  bool isLoading = true;

  final String apiUrl =
      "http://54.82.53.11:5001/api/instructor/students?page=1&limit=10";

  String accessToken = "";
  String refreshToken = "";

  @override
  void initState() {
    super.initState();
    _loadTokensAndFetch();
  }

  Future<void> _loadTokensAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString("access_token") ?? "";
    refreshToken = prefs.getString("refresh_token") ?? "";

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      debugPrint("⚠️ No tokens found. Redirecting to login...");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InstructorLoginPage()),
        );
      }
      return;
    }

    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> studentList = data["data"]["students"] ?? [];

        setState(() {
          students = studentList.map((json) => Student.fromJson(json)).toList();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        debugPrint("🔄 Access token expired. Refreshing...");
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          fetchStudents();
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InstructorLoginPage()),
            );
          }
        }
      } else {
        setState(() => isLoading = false);
        debugPrint("Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Fetch error: $e");
    }
  }

  Future<bool> refreshAccessToken() async {
    try {
      const refreshUrl = "http://54.82.53.11:5001/api/auth/refresh-token";

      final response = await http.post(
        Uri.parse(refreshUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        accessToken = data["access_token"];
        refreshToken = data["refresh_token"];

        await prefs.setString("refresh_token", refreshToken);

        debugPrint("✅ Token refreshed successfully!");
        return true;
      } else {
        debugPrint("❌ Failed to refresh token: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Refresh error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredStudents = students.where((student) {
      final query = searchQuery.toLowerCase();
      final matchesNameOrStudentId =
          student.name.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query);
      final matchesStatus =
          selectedStatus == 'All' ||
          student.status.toLowerCase() == selectedStatus.toLowerCase();
      return matchesNameOrStudentId && matchesStatus;
    }).toList();

    return Scaffold(
      // appBar: AppBar(
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: const Color(0xFF5F299E),
      //   foregroundColor: Colors.white,
      //   title: const Text("Students"),
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1024;
                final isTablet =
                    constraints.maxWidth > 600 && constraints.maxWidth <= 1024;

                final dataSource = StudentDataSource(
                  filteredStudents,
                  context,
                  isDesktop,
                  isTablet,
                );

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Students',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: isDesktop
                                ? 300
                                : isTablet
                                ? 220
                                : 200,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by name or Student ID',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              style: TextStyle(fontSize: isDesktop ? 16 : 14),
                              onChanged: (value) {
                                setState(() => searchQuery = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isDesktop || isTablet)
                            DropdownButton<String>(
                              value: selectedStatus,
                              items: const [
                                DropdownMenuItem(
                                  value: 'All',
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: 'Active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'Inactive',
                                  child: Text('Inactive'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedStatus = value);
                                }
                              },
                            )
                          else
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.filter_list),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'All',
                                  child: Text('Status: All'),
                                ),
                                PopupMenuItem(
                                  value: 'Active',
                                  child: Text('Active'),
                                ),
                                PopupMenuItem(
                                  value: 'Inactive',
                                  child: Text('Inactive'),
                                ),
                              ],
                              onSelected: (value) {
                                setState(() => selectedStatus = value);
                              },
                            ),
                          if (isDesktop) const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: PaginatedDataTable(
                            rowsPerPage: isDesktop
                                ? 8
                                : isTablet
                                ? 6
                                : 5,
                            availableRowsPerPage: const [5, 6, 8, 10],
                            onRowsPerPageChanged: (value) {},
                            columns: [
                              const DataColumn(label: Text("Users")),
                              if (isDesktop)
                                const DataColumn(label: Text("Course")),
                              if (isDesktop)
                                const DataColumn(label: Text("Email")),
                              if (isDesktop)
                                const DataColumn(label: Text("Phone")),
                              if (isTablet)
                                const DataColumn(
                                  label: Text("Enrolled Course"),
                                ),
                              if (isTablet)
                                const DataColumn(label: Text("Email")),
                              const DataColumn(label: Text("Status")),
                              if (!isDesktop && !isTablet)
                                const DataColumn(label: Text("Actions")),
                            ],
                            source: dataSource,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class StudentDataSource extends DataTableSource {
  final List<Student> students;
  final BuildContext context;
  final bool isDesktop;
  final bool isTablet;

  StudentDataSource(this.students, this.context, this.isDesktop, this.isTablet);

  @override
  DataRow? getRow(int index) {
    if (index >= students.length) return null;
    final student = students[index];
    final theme = Theme.of(context);

    Color statusColor;
    switch (student.status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'inactive':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = theme.colorScheme.outline;
    }

    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(student.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                "Student ID: ${student.studentId}",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          DataCell(Text(student.enrolledCourse)),
          DataCell(Text(student.email)),
          DataCell(Text(student.phone)),
        ] else if (isTablet) ...[
          DataCell(Text(student.enrolledCourse)),
          DataCell(Text(student.email)),
        ],
        DataCell(
          Text(
            student.status,
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
        if (!isDesktop && !isTablet)
          DataCell(
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          child: Text(
                            student.name[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            student.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Student ID', student.studentId),
                        _infoRow('Course', student.enrolledCourse),
                        _infoRow('Email', student.email),
                        _infoRow('Phone', student.phone),
                        _infoRow('Status', student.status, color: statusColor),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => students.length;
  @override
  int get selectedRowCount => 0;
}

Widget _infoRow(String label, String value, {Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}
