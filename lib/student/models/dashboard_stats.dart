class DashboardStats {
  final int totalCourses;
  final double learningHours;
  final double averageRating;
  final double completionRate;
  final int enrolledCoursesCount;

  DashboardStats({
    required this.totalCourses,
    required this.learningHours,
    required this.averageRating,
    required this.completionRate,
    required this.enrolledCoursesCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCourses: json['totalCourses'] ?? 0,
      learningHours: (json['learningHours'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      enrolledCoursesCount: json['enrolledCoursesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCourses': totalCourses,
      'learningHours': learningHours,
      'averageRating': averageRating,
      'completionRate': completionRate,
      'enrolledCoursesCount': enrolledCoursesCount,
    };
  }

  // Helper method to format learning hours
  String get formattedLearningHours {
    if (learningHours < 1) {
      final minutes = (learningHours * 60).round();
      return '${minutes}m';
    } else if (learningHours < 10) {
      return '${learningHours.toStringAsFixed(1)}h';
    } else {
      return '${learningHours.round()}h';
    }
  }

  // Helper method to format rating
  String get formattedRating {
    return averageRating.toStringAsFixed(1);
  }
}
