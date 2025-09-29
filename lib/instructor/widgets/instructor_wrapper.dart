import 'package:flutter/material.dart';
import '../pages/instructor_dashboard.dart';

class InstructorWrapper extends StatelessWidget {
  final String instructorName;

  const InstructorWrapper({
    super.key,
    required this.instructorName,
  });

  @override
  Widget build(BuildContext context) {
    return InstructorDashboard(instructorName: instructorName);
  }
}
