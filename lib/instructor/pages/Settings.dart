import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

String to12Hour(String time24h) {
  // Trim the input to remove any extra spaces
  time24h = time24h.trim();

  // Check if the input already contains AM/PM
  if (time24h.toUpperCase().contains("AM") ||
      time24h.toUpperCase().contains("PM")) {
    final parts = time24h.split(":");
    if (parts.length >= 2) {
      final timePart = parts[0];
      final minutePart = parts[1].split(" ")[0].padLeft(2, '0');
      final period = parts[1].toUpperCase().contains("AM") ? "AM" : "PM";
      int hour = int.parse(timePart);
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12)
        hour -= 12;
      return "$hour:$minutePart $period";
    }
    return time24h;
  }

  // Convert 24-hour format to 12-hour
  final parts = time24h.split(":");
  int hour = int.parse(parts[0]);
  final minute = parts[1].padLeft(2, '0');
  final period = hour >= 12 ? "PM" : "AM";
  if (hour == 0) {
    hour = 12;
  } else if (hour > 12)
    hour -= 12;
  return "$hour:$minute $period";
}

extension StringCasingExtension on String {
  String capitalize() {
    return length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  bool _isLoading = false;

  // final List<String> _tabs = ["Availability", "Notifications", "Profile"];
  final List<String> _tabs = ["Availability", "Notifications"];

  List<Map<String, dynamic>> _availabilitySlots = [];

  final String baseUrl = "http://54.82.53.11:5001/api/instructor";

  // Notification preferences
  bool _sessionReminders = true;
  bool _studentMessages = true;
  bool _feedbackNotifications = true;
  bool _newEnrollments = true;
  bool _reviews = true;

  // Profile controllers with validation
  // final TextEditingController _nameCtrl = TextEditingController(
  //   text: "Rohit Instructor",
  // );
  // final TextEditingController _emailCtrl = TextEditingController(
  //   text: "rohit@example.com",
  // );
  // final TextEditingController _bioCtrl = TextEditingController(
  //   text: "Passionate instructor. Love teaching Flutter!",
  // );

  // Password controllers
  // final TextEditingController _currentPassCtrl = TextEditingController();
  // final TextEditingController _newPassCtrl = TextEditingController();
  // final TextEditingController _confirmPassCtrl = TextEditingController();

  // // Form keys for validation
  // final _profileFormKey = GlobalKey<FormState>();
  // final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
    _fetchInitialData();
  }

  Future<void> _deleteAvailabilitySlot(String slotId) async {
    final url = Uri.parse("$baseUrl/slots/$slotId");
    final token = await InstructorAuthService.getAccessToken();
    if (token == null) {
      print("user not loged in ");
    }
    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _availabilitySlots.removeWhere((slot) => slot["_id"] == slotId);
      });
      _showSuccessSnackBar("Slot deleted successfully");
    } else {
      _showErrorSnackBar("Failed to delete slot");
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAvailabilitySlots(),
        _fetchNotificationPreferences(),
      ]);
    } catch (e) {
      _showErrorSnackBar("Failed to load data");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailabilitySlots() async {
    final url = Uri.parse("$baseUrl/slots");
    final token = await InstructorAuthService.getAccessToken();
    if (token == null) {
      print("user not loged in");
    }
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>.");
    print(response.statusCode);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final slots = data['data']['instructor']['availabilitySlots'] as List;
      print(">>>>>>>>>>>>>>>>>>>>>>>");
      print(slots);
      setState(() {
        _availabilitySlots = List<Map<String, dynamic>>.from(slots);
      });
    } else {
      _showErrorSnackBar("Failed to fetch availability slots");
    }
  }

  Future<void> _updateAvailabilitySlots() async {
    final url = Uri.parse("$baseUrl/slots");

    String to24Hour(String time12h) {
      final parts = time12h.trim().split(" ");
      if (parts.length < 2) return time12h; // safeguard

      final hm = parts[0].split(":");
      int hour = int.parse(hm[0]);
      final minute = hm[1];
      final period = parts[1].toUpperCase();

      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;

      return "${hour.toString().padLeft(2, '0')}:$minute";
    }

    final body = {
      "availabilitySlots": _availabilitySlots.map((slot) {
        try {
          // Convert 12-hour format to 24-hour for API
          String to24Hour(String time12h) {
            final parts = time12h.trim().split(" ");
            if (parts.length < 2) return time12h;

            final hm = parts[0].split(":");
            int hour = int.parse(hm[0]);
            final minute = hm[1];
            final period = parts[1].toUpperCase();

            if (period == "PM" && hour != 12) hour += 12;
            if (period == "AM" && hour == 12) hour = 0;

            return "${hour.toString().padLeft(2, '0')}:$minute";
          }

          return {
            "dayOfWeek": slot["dayOfWeek"],
            "startTime": to24Hour(slot["startTime"]),
            "endTime": to24Hour(slot["endTime"]),
          };
        } catch (e) {
          print("Error parsing slot: $slot → $e");
          return {};
        }
      }).toList(),
    };

    print("><<<<<<<<<<<>>>>>>>>>>>");
    print(body);
    final token = await InstructorAuthService.getAccessToken();
    if (token == null) {
      print("user not loged in");
    }
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      _showSuccessSnackBar("Availability slots updated successfully");
    } else {
      _showErrorSnackBar("Failed to update availability slots");
    }
  }

  Future<void> _fetchNotificationPreferences() async {
    final url = Uri.parse("$baseUrl/notifications/preferences");
    final token = await InstructorAuthService.getAccessToken();
    if (token == null) {
      print("user not loged in");
    }
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      print(">>>>>>>>>>>>>>>>>>>>>>>........");
      final data = jsonDecode(response.body);
      final prefs = data['data']['user']['notificationPreferences'];
      print(prefs);
      setState(() {
        _sessionReminders = prefs['session'] ?? false;
        _studentMessages = prefs['messages'] ?? true;
        _feedbackNotifications = prefs['feedBack'] ?? true;
        _newEnrollments = prefs['newEnrollments'] ?? true;
        _reviews = prefs['reviews'] ?? true;
      });
    } else {
      _showErrorSnackBar("Failed to fetch notification preferences");
    }
  }

  Future<void> _updateNotificationPreferences() async {
    final url = Uri.parse("$baseUrl/notifications");
    final body = {
      "notificationPreferences": {
        "session": _sessionReminders,
        "messages": _studentMessages,
        "feedBack": _feedbackNotifications,
        "newEnrollments": _newEnrollments,
        "reviews": _reviews,
      },
    };
    final token = await InstructorAuthService.getAccessToken();
    if (token == null) {
      print("user not loged in");
    }
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print(">>><><><<<");
      _showSuccessSnackBar("Notification preferences updated");
    } else {
      _showErrorSnackBar("Failed to update preferences");
    }
  }

  // @override
  // void dispose() {
  //   _tabController.dispose();
  //   _nameCtrl.dispose();
  //   _emailCtrl.dispose();
  //   _bioCtrl.dispose();
  //   _currentPassCtrl.dispose();
  //   _newPassCtrl.dispose();
  //   _confirmPassCtrl.dispose();
  //   super.dispose();
  // }

  // Load saved notification preferences with loading state
  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _sessionReminders = prefs.getBool("sessionReminders") ?? true;
        _studentMessages = prefs.getBool("studentMessages") ?? true;
        _feedbackNotifications = prefs.getBool("feedbackNotifications") ?? true;
      });
    } catch (e) {
      _showErrorSnackBar("Failed to load preferences");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save a preference with user feedback
  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      _showSuccessSnackBar("Preference saved");
    } catch (e) {
      _showErrorSnackBar("Failed to save preference");
    }
  }

  // Enhanced date time picker with validation
  Future<void> _pickDateTimeSlot() async {
    try {
      // Pick Date
      DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 7)),
        helpText: "Select availability date",
        confirmText: "NEXT",
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: const Color(0xFF5F299E)),
            ),
            child: child!,
          );
        },
      );

      if (date == null) return;

      // Pick From Time
      TimeOfDay? fromTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode: TimePickerEntryMode.dial,
        helpText: "Select start time",

        confirmText: "NEXT",
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: const Color(0xFF5F299E)),
              ),
              child: child!,
            ),
          );
        },
      );

      if (fromTime == null) return;

      // Pick To Time with validation
      TimeOfDay? toTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: (fromTime.hour + 1) % 24,
          minute: fromTime.minute,
        ),
        initialEntryMode: TimePickerEntryMode.dial,
        helpText: "Select end time",
        confirmText: "DONE",
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: const Color(0xFF5F299E)),
              ),
              child: child!,
            ),
          );
        },
      );

      if (toTime == null) return;

      // Validate time range
      if (_isTimeAfter(fromTime, toTime)) {
        _showErrorSnackBar("End time must be after start time");
        return;
      }

      // Format and save slot
      final slot = _formatTimeSlot(date, fromTime, toTime);

      // Check for duplicates
      if (_availabilitySlots.contains(slot)) {
        _showErrorSnackBar("This time slot already exists");
        return;
      }

      setState(() {
        _availabilitySlots.add(slot);
      });
      await _updateAvailabilitySlots();

      _showSuccessSnackBar("Time slot added successfully");
    } catch (e) {
      _showErrorSnackBar("Failed to add time slot");
    }
  }

  bool _isTimeAfter(TimeOfDay start, TimeOfDay end) {
    return start.hour > end.hour ||
        (start.hour == end.hour && start.minute >= end.minute);
  }

  Map<String, String> _formatTimeSlot(
    DateTime date,
    TimeOfDay fromTime,
    TimeOfDay toTime,
  ) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    String formatTime12h(TimeOfDay t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? "AM" : "PM";
      return "$hour:$minute $period";
    }

    final dayName = days[date.weekday - 1]; // e.g. "monday"

    return {
      "dayOfWeek": dayName,
      "startTime": formatTime12h(fromTime),
      "endTime": formatTime12h(toTime),
    };
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          appBar: AppBar(
            title: const Text(
              "Settings & Preferences",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF5F299E),
            automaticallyImplyLeading: !kIsWeb,
            elevation: 0,
            leading: kIsWeb
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    tooltip: "Go back",
                  ),
            bottom: isDesktop
                ? null
                : TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: _tabs.asMap().entries.map((entry) {
                      final icons = [
                        Icons.schedule,
                        Icons.notifications,
                        Icons.person,
                      ];
                      return Tab(
                        icon: Icon(icons[entry.key], size: 20),
                        text: entry.value,
                      );
                    }).toList(),
                  ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF5F299E),
                    ),
                  ),
                )
              : isDesktop
              ? Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                            _tabController.index = index;
                          });
                        },
                        backgroundColor: const Color(0xFF5F299E),
                        selectedIconTheme: const IconThemeData(
                          color: Colors.white,
                          size: 24,
                        ),
                        unselectedIconTheme: const IconThemeData(
                          color: Colors.white70,
                          size: 22,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.schedule_outlined),
                            selectedIcon: Icon(Icons.schedule),
                            label: Text("Availability"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.notifications_outlined),
                            selectedIcon: Icon(Icons.notifications),
                            label: Text("Notifications"),
                          ),
                          // NavigationRailDestination(
                          //   icon: Icon(Icons.person_outline),
                          //   selectedIcon: Icon(Icons.person),
                          //   label: Text("Profile"),
                          // ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Container(
                          // color: Colors.grey[50],
                          child: _buildPage(_selectedIndex, isDesktop),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  // color: Colors.grey[50],
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.grey[50],
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailabilityPage(false),
                      _buildNotificationsPage(false),
                      // _buildProfilePage(false),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPage(int index, bool isDesktop) {
    switch (index) {
      case 0:
        return _buildAvailabilityPage(isDesktop);
      case 1:
        return _buildNotificationsPage(isDesktop);
      // case 2:
      //   return _buildProfilePage(isDesktop);
      default:
        return const SizedBox();
    }
  }

  Widget _buildAvailabilityPage(bool isDesktop) {
    return SingleChildScrollView(
      child: _buildCard(
        title: "Manage Your Availability",
        subtitle: "Set your available time slots for student bookings",
        isDesktop: isDesktop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5F299E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF5F299E).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF5F299E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Add your available time slots. Students can book sessions during these times.",
                      style: TextStyle(
                        color: const Color(0xFF5F299E),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickDateTimeSlot,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  "Add Time Slot",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F299E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Slots label
            Text(
              "Your Available Slots (${_availabilitySlots.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Slots list
            _availabilitySlots.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No availability slots added yet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Click 'Add Time Slot' to set your availability",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availabilitySlots.length,
                    itemBuilder: (context, index) {
                      final slot = _availabilitySlots[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5F299E,
                              ).withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Color(0xFF5F299E),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            "${slot["dayOfWeek"].toString().capitalize()} | From: ${to12Hour(slot["startTime"])} → To: ${to12Hour(slot["endTime"])}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _confirmDeleteSlot(index, slot),
                            tooltip: "Remove this slot",
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSlot(int index, Map slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Time Slot"),
        content: Text(
          "Are you sure you want to remove this slot?\n\n"
          "${slot["dayOfWeek"]} | From: ${slot["startTime"]} → To: ${slot["endTime"]}",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAvailabilitySlot(slot["_id"]);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage(bool isDesktop) {
    return SingleChildScrollView(
      child: _buildCard(
        title: "Notification Preferences",
        subtitle: "Choose what notifications you want to receive",
        isDesktop: isDesktop,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNotificationTile(
                title: "Session Reminders",
                subtitle: "Get notified before your scheduled sessions",
                icon: Icons.alarm,
                value: _sessionReminders,
                onChanged: (value) {
                  setState(() => _sessionReminders = value);
                  _savePreference("sessionReminders", value);
                  _updateNotificationPreferences();
                },
              ),
              const Divider(),
              _buildNotificationTile(
                title: "Student Messages",
                subtitle: "Receive notifications for new student messages",
                icon: Icons.message,
                value: _studentMessages,
                onChanged: (value) {
                  setState(() => _studentMessages = value);
                  _savePreference("studentMessages", value);
                  _updateNotificationPreferences();
                },
              ),
              const Divider(),
              _buildNotificationTile(
                title: "Review Notifications",
                subtitle: "Get notified when students leave reviews",
                icon: Icons.star,
                value: _reviews,
                onChanged: (value) {
                  setState(() => _reviews = value);
                  _savePreference("reviews", value);
                  _updateNotificationPreferences();
                },
              ),
              const Divider(),
              _buildNotificationTile(
                title: "New Enrollments",
                subtitle:
                    "Get notified when new students enroll in your courses",
                icon: Icons.star,
                value: _newEnrollments,
                onChanged: (value) {
                  setState(() => _newEnrollments = value);
                  _savePreference("newEnrollments", value);
                  _updateNotificationPreferences();
                },
              ),
              const Divider(),
              _buildNotificationTile(
                title: "Feedback Notifications",
                subtitle: "Get notified when students leave feedback",
                icon: Icons.star,
                value: _feedbackNotifications,
                onChanged: (value) {
                  setState(() => _feedbackNotifications = value);
                  _savePreference("feedbackNotifications", value);
                  _updateNotificationPreferences();
                },
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5F299E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF5F299E), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF5F299E),
          ),
        ],
      ),
    );
  }

  // Enhanced Profile page
  // Widget _buildProfilePage(bool isDesktop) {
  //   return _buildCard(
  //     title: "Profile Settings",
  //     subtitle: "Manage your profile information and security",
  //     isDesktop: isDesktop,
  //     child: Expanded(
  //       key: _profileFormKey,
  //       child: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Profile picture section
  //             Center(
  //               child: Stack(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 50,
  //                     backgroundColor: Colors.grey[300],
  //                     child: const Icon(
  //                       Icons.person,
  //                       size: 60,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                   Positioned(
  //                     bottom: 0,
  //                     right: 0,
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFF5F299E),
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: IconButton(
  //                         icon: const Icon(
  //                           Icons.camera_alt,
  //                           color: Colors.white,
  //                           size: 20,
  //                         ),
  //                         onPressed: () {
  //                           _showSuccessSnackBar("Photo upload coming soon!");
  //                         },
  //                         tooltip: "Change profile picture",
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 32),

  //             // Profile form
  //             TextFormField(
  //               controller: _nameCtrl,
  //               decoration: const InputDecoration(
  //                 labelText: "Full Name",
  //                 hintText: "Enter your full name",
  //                 border: OutlineInputBorder(),
  //                 prefixIcon: Icon(Icons.person_outline),
  //               ),
  //               validator: (value) {
  //                 if (value == null || value.trim().isEmpty) {
  //                   return "Name is required";
  //                 }
  //                 return null;
  //               },
  //             ),
  //             const SizedBox(height: 16),

  //             TextFormField(
  //               controller: _emailCtrl,
  //               decoration: const InputDecoration(
  //                 labelText: "Email Address",
  //                 hintText: "Enter your email",
  //                 border: OutlineInputBorder(),
  //                 prefixIcon: Icon(Icons.email_outlined),
  //               ),
  //               keyboardType: TextInputType.emailAddress,
  //               validator: (value) {
  //                 if (value == null || value.trim().isEmpty) {
  //                   return "Email is required";
  //                 }
  //                 if (!RegExp(
  //                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  //                 ).hasMatch(value)) {
  //                   return "Enter a valid email address";
  //                 }
  //                 return null;
  //               },
  //             ),
  //             const SizedBox(height: 16),

  //             TextFormField(
  //               controller: _bioCtrl,
  //               maxLines: 4,
  //               maxLength: 500,
  //               decoration: const InputDecoration(
  //                 labelText: "Bio",
  //                 hintText: "Tell students about yourself...",
  //                 border: OutlineInputBorder(),
  //                 prefixIcon: Icon(Icons.description_outlined),
  //                 alignLabelWithHint: true,
  //               ),
  //             ),
  //             const SizedBox(height: 24),

  //             // Save profile button
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton.icon(
  //                 onPressed: () {
  //                   if (_profileFormKey.currentState!.validate()) {
  //                     _showSuccessSnackBar("Profile updated successfully!");
  //                   }
  //                 },
  //                 icon: const Icon(Icons.save),
  //                 label: const Text("Save Profile Changes"),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color(0xFF5F299E),
  //                   foregroundColor: Colors.white,
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //               ),
  //             ),

  //             const SizedBox(height: 32),
  //             const Divider(),
  //             const SizedBox(height: 16),

  // Security section
  // Row(
  //   children: [
  //     Icon(Icons.security, color: Colors.grey[600]),
  //     const SizedBox(width: 8),
  //     Text(
  //       "Security",
  //       style: TextStyle(
  //         fontSize: 18,
  //         fontWeight: FontWeight.w600,
  //         color: Colors.grey[800],
  //       ),
  //     ),
  //   ],
  // ),
  // const SizedBox(height: 16),

  // SizedBox(
  //   width: double.infinity,
  //   child: OutlinedButton.icon(
  //     onPressed: _showChangePasswordDialog,
  //     icon: const Icon(Icons.lock_outline),
  //     label: const Text("Change Password"),
  //     style: OutlinedButton.styleFrom(
  //       foregroundColor: Colors.red,
  //       side: const BorderSide(color: Colors.red),
  //       padding: const EdgeInsets.symmetric(vertical: 16),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //     ),
  //   ),
  // ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Enhanced password change dialog
  // void _showChangePasswordDialog() {
  //   _currentPassCtrl.clear();
  //   _newPassCtrl.clear();
  //   _confirmPassCtrl.clear();

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Row(
  //           children: [
  //             Icon(Icons.lock, color: Colors.red),
  //             const SizedBox(width: 4),
  //             const Text("Change Password"),
  //           ],
  //         ),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         content: Form(
  //           key: _passwordFormKey,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextFormField(
  //                 controller: _currentPassCtrl,
  //                 obscureText: true,
  //                 decoration: const InputDecoration(
  //                   labelText: "Current Password",
  //                   border: OutlineInputBorder(),
  //                   prefixIcon: Icon(Icons.lock_outline),
  //                 ),
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return "Current password is required";
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               TextFormField(
  //                 controller: _newPassCtrl,
  //                 obscureText: true,
  //                 decoration: const InputDecoration(
  //                   labelText: "New Password",
  //                   border: OutlineInputBorder(),
  //                   prefixIcon: Icon(Icons.lock),
  //                   hintText: "At least 8 characters",
  //                 ),
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return "New password is required";
  //                   }
  //                   if (value.length < 8) {
  //                     return "Password must be at least 8 characters";
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               TextFormField(
  //                 controller: _confirmPassCtrl,
  //                 obscureText: true,
  //                 decoration: const InputDecoration(
  //                   labelText: "Confirm New Password",
  //                   border: OutlineInputBorder(),
  //                   prefixIcon: Icon(Icons.lock),
  //                 ),
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return "Please confirm your password";
  //                   }
  //                   if (value != _newPassCtrl.text) {
  //                     return "Passwords do not match";
  //                   }
  //                   return null;
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               if (_passwordFormKey.currentState!.validate()) {
  //                 _showSuccessSnackBar("Password updated successfully!");
  //                 Navigator.pop(context);
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text("Update Password"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildCard({
    required String title,
    String? subtitle,
    required Widget child,
    required bool isDesktop,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      // color: Colors.red,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(isDesktop ? 16 : 16),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
