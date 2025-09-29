import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> sessions;

  const CalendarPage({super.key, required this.sessions});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _filter = "Week";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        backgroundColor: const Color(0xFF5F299E),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(20),
              isSelected: [_filter == "Week", _filter == "Month"],
              onPressed: (index) {
                setState(() {
                  _filter = index == 0 ? "Week" : "Month";
                });
              },
              color: Theme.of(context).textTheme.bodyMedium?.color,
              selectedColor: const Color(0xFF5F299E),
              fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Week"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Month"),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat:
                _filter == "Week" ? CalendarFormat.week : CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return widget.sessions
                  .where((session) =>
                      session["date"].year == day.year &&
                      session["date"].month == day.month &&
                      session["date"].day == day.day)
                  .toList();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color:const Color(0xFF5F299E),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markersMaxCount: 1,
              defaultTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                if (_selectedDay != null && isSameDay(date, _selectedDay)) {
                  return null;
                }
                final session = events.first as Map<String, dynamic>;
                final sessionDate = session["date"] as DateTime;
                final isUpcoming = sessionDate.isAfter(DateTime.now());
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 35),
                  decoration: BoxDecoration(
                    color: isUpcoming ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Text(
                      "Select a date to view sessions",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: widget.sessions
                        .where((s) =>
                            s["date"].year == _selectedDay!.year &&
                            s["date"].month == _selectedDay!.month &&
                            s["date"].day == _selectedDay!.day)
                        .map((session) => _buildSessionCard(session))
                        .toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:_createSessionDialog,
        backgroundColor: const Color(0xFF5F299E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final date = session["date"] as DateTime;
    final duration = session["duration"] as Duration;
    final endTime = date.add(duration);
    final isPast = session["type"] == "past";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onLongPress: isPast ? null : () => _editSessionDialog(session),
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
                      session["title"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      isPast ? "Completed" : "Upcoming",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: isPast ? Colors.grey : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 20, color: Theme.of(context).iconTheme.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${DateFormat('EEE, d MMM yyyy').format(date)}\n"
                      "${DateFormat('h:mm a').format(date)} - ${DateFormat('h:mm a').format(endTime)}"
                      "  •  ${duration.inHours}h ${duration.inMinutes % 60}m",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSessionDialog(Map<String, dynamic> session) async {
    final titleController = TextEditingController(text: session["title"]);
    DateTime selectedDateTime = session["date"];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Session"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime.isBefore(DateTime.now())
                        ? DateTime.now()
                        : selectedDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (pickedTime != null) {
                      final newDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      if (newDateTime.isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("You cannot select past date/time")),
                        );
                      } else {
                        selectedDateTime = newDateTime;
                      }
                    }
                  }
                },
                child: const Text("Change Date & Time"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();

                if (selectedDateTime.isBefore(now)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("You cannot set a session in the past")),
                  );
                  return;
                }

                setState(() {
                  session["title"] = titleController.text;
                  session["date"] = selectedDateTime;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSessionDialog() async {
    final titleController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();
    Duration selectedDuration = const Duration(hours: 1);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Session"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: const Text("Pick Date & Time"),
              ),
              const SizedBox(height: 12),
              DropdownButton<Duration>(
                value: selectedDuration,
                items: const [
                  DropdownMenuItem(
                    value: Duration(hours: 1),
                    child: Text("1 Hour"),
                  ),
                  DropdownMenuItem(
                    value: Duration(hours: 2),
                    child: Text("2 Hours"),
                  ),
                  DropdownMenuItem(
                    value: Duration(hours: 3),
                    child: Text("3 Hours"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDuration = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();

                if (selectedDateTime.isBefore(now)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You cannot create a session in the past")),
                  );
                  return;
                }

                setState(() {
                  widget.sessions.add({
                    "title": titleController.text.isEmpty
                        ? "New Session"
                        : titleController.text,
                    "date": selectedDateTime,
                    "duration": selectedDuration,
                    "type": "upcoming",
                  });
                });

                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }
}