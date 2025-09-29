class CourseProgress {
  final double percentage;
  final int completedSections;
  final int totalSections;
  final int completedVideos;
  final int totalVideos;
  final DateTime? lastAccessed;

  CourseProgress({
    required this.percentage,
    required this.completedSections,
    required this.totalSections,
    required this.completedVideos,
    required this.totalVideos,
    this.lastAccessed,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      percentage: (json['percentage'] ?? 0).toDouble(),
      completedSections: json['completedSections'] ?? 0,
      totalSections: json['totalSections'] ?? 0,
      completedVideos: json['completedVideos'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
      lastAccessed: json['lastAccessed'] != null 
          ? DateTime.parse(json['lastAccessed']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'percentage': percentage,
      'completedSections': completedSections,
      'totalSections': totalSections,
      'completedVideos': completedVideos,
      'totalVideos': totalVideos,
      'lastAccessed': lastAccessed?.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedProgress => '${percentage.toInt()}%';
  
  String get sectionsProgress => '$completedSections/$totalSections sections';
  
  String get videosProgress => '$completedVideos/$totalVideos videos';
  
  bool get isCompleted => percentage >= 100;
  
  bool get isStarted => percentage > 0;
}


