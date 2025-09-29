import 'lib/student/models/course.dart';

void main() {
  // Test data from your API response
  final apiResponse = {
    "_id": "68a85831ce4b2dfa44c84843",
    "title": "Digital Marketing Strategy",
    "description": "Learn effective digital marketing strategies to grow your business online.",
    "price": 59.99,
    "instructor": {
      "_id": "68a85831ce4b2dfa44c84832",
      "name": "Default Instructor",
      "email": "instructor@test.com",
      "avatar": null
    },
    "thumbnail": "default-course.jpg",
    "category": {
      "_id": "68a84123b9e00283f4e0a2fc",
      "name": "test"
    },
    "level": "beginner",
    "published": true,
    "enrolledStudents": [],
    "averageRating": 4.4,
    "sections": [],
    "totalVideos": 28,
    "totalDuration": 1680, // 1680 minutes = 28 hours
    "ratings": [],
    "createdAt": "2025-08-22T11:44:49.991Z",
    "updatedAt": "2025-08-22T11:44:49.991Z",
    "slug": "digital-marketing-strategy",
    "__v": 0
  };

  // Create Course object from API response
  final course = Course.fromJson(apiResponse);

  print('=== Course Model Test ===');
  print('Title: ${course.title}');
  print('Price: \$${course.price.toStringAsFixed(2)}');
  print('Rating: ${course.averageRating}/5');
  print('Students: ${course.students}'); // Should show "0 students" since enrolledStudents is empty
  print('Duration: ${course.duration}'); // Should show "28h" since 1680 minutes = 28 hours
  print('Total Videos: ${course.totalVideos}');
  print('Instructor: ${course.author}');
  print('Image Asset: ${course.imageAsset}');
  print('Level: ${course.level}');
  
  print('\n=== Expected vs Actual ===');
  print('Expected Rating: 4.4 | Actual: ${course.averageRating}');
  print('Expected Students: 0 students | Actual: ${course.students}');
  print('Expected Duration: 28h | Actual: ${course.duration}');
  print('Expected Videos: 28 | Actual: ${course.totalVideos}');
  
  // Test with some enrolled students
  final apiResponseWithStudents = Map<String, dynamic>.from(apiResponse);
  apiResponseWithStudents['enrolledStudents'] = ['student1', 'student2', 'student3'];
  
  final courseWithStudents = Course.fromJson(apiResponseWithStudents);
  print('\n=== With 3 Students ===');
  print('Students: ${courseWithStudents.students}'); // Should show "3 students"
  
  // Test with many students
  final apiResponseManyStudents = Map<String, dynamic>.from(apiResponse);
  apiResponseManyStudents['enrolledStudents'] = List.generate(1500, (i) => 'student$i');
  
  final courseWithManyStudents = Course.fromJson(apiResponseManyStudents);
  print('\n=== With 1500 Students ===');
  print('Students: ${courseWithManyStudents.students}'); // Should show "1.5k students"
}
