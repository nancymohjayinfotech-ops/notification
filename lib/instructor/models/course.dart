class Course {
  final String title;
  final String author;
  final String imageAsset;
  final double progress;
  final String progressText;
  final String price;
  final double rating;
  final String students;
  final String duration;
  final String description;

  Course({
    required this.title,
    required this.author,
    required this.imageAsset,
    this.progress = 0.0,
    this.progressText = '0% completed',
    this.price = '\$99.00',
    this.rating = 4.8,
    this.students = '2.5k',
    this.duration = '90 days access',
    this.description = '',
  });

  // Convert Course to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'imageAsset': imageAsset,
      'progress': progress,
      'progressText': progressText,
      'price': price,
      'rating': rating,
      'students': students,
      'duration': duration,
      'description': description,
    };
  }

  // Create Course from Map
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      imageAsset: map['imageAsset'] ?? '',
      progress: map['progress']?.toDouble() ?? 0.0,
      progressText: map['progressText'] ?? '0% completed',
      price: map['price'] ?? '\$99.00',
      rating: map['rating']?.toDouble() ?? 4.8,
      students: map['students'] ?? '2.5k',
      duration: map['duration'] ?? '90 days access',
      description: map['description'] ?? '',
    );
  }

  // Create a copy with updated fields
  Course copyWith({
    String? title,
    String? author,
    String? imageAsset,
    double? progress,
    String? progressText,
    String? price,
    double? rating,
    String? students,
    String? duration,
    String? description,
  }) {
    return Course(
      title: title ?? this.title,
      author: author ?? this.author,
      imageAsset: imageAsset ?? this.imageAsset,
      progress: progress ?? this.progress,
      progressText: progressText ?? this.progressText,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      students: students ?? this.students,
      duration: duration ?? this.duration,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course &&
        other.title == title &&
        other.author == author;
  }

  @override
  int get hashCode => title.hashCode ^ author.hashCode;
}
