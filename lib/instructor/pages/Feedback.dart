import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'courses_page.dart';
import 'student_page.dart';
import 'groups_page.dart';

import 'dart:convert';

class InstructorCard extends StatelessWidget {
  final String name;
  final String bio;
  final String imageUrl;
  final double rating;
  final bool isDesktop;
  final int sessions;
  final int students;
  final int reviewsCount;

  const InstructorCard({
    super.key,
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.rating,
    this.sessions = 0,
    this.students = 0,
    this.reviewsCount = 0,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.black : Colors.white;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.35),
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: isDesktop ? 60 : 40,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: const Color(0xFF5F299E),
            ),
            SizedBox(height: isDesktop ? 20 : 12),
            Text(
              name,
              style: TextStyle(
                fontSize: isDesktop ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 12 : 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            SizedBox(height: isDesktop ? 20 : 12),
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: isDesktop ? 32 : 24,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: 8),
            Text(
              "$rating / 5.0",
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F299E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "Quick Stats",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF5F299E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("Total Courses", sessions.toString()),
                        _buildStatItem(
                          "Enrolled Students",
                          students.toString(),
                        ),
                        _buildStatItem(
                          "Total Reviews",
                          reviewsCount.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5F299E),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<Map<String, dynamic>> reviews = [];
  int sessions = 0;
  int students = 0;
  int reviewsCount = 0;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final int limit = 10;

  final ScrollController _scrollController = ScrollController();

  String name = "";
  String bio = "";
  String imageUrl = "";
  double rating = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        fetchMoreReviews();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final token = await InstructorAuthService.getAccessToken();

    if (token != null) {
      await fetchInstructorData(token, page: 1);
      await fetchInstructorStats(token);
    } else {
      print("⚠️ No token found, user not logged in.");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchInstructorData(String token, {int page = 1}) async {
    final String url =
        "http://54.82.53.11:5001/api/instructor/reviews?page=$page&limit=$limit";

    if (page == 1) {
      setState(() => isLoading = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final instructor = jsonData["data"]["instructor"];
        final reviewList = jsonData["data"]["reviews"] as List;

        final newReviews = reviewList.map<Map<String, dynamic>>((r) {
          return {
            "student": r["user"]?['name'] ?? "Anonymous",
            "reviewid": r['reviewId'] ?? "",
            "courseId": r['courseId'] ?? "",
            "courseTitle": r['courseTitle'] ?? "No title",
            "rating": (r["rating"] ?? 0).toDouble(),
            "comment": r["review"] ?? "",
            "date": r["createdAt"]?.substring(0, 10) ?? "",
            "avatar": r["user"]?['avatar'] ?? "https://i.pravatar.cc/150",
            "helpful": 0,
            "isHelpful": false,
          };
        }).toList();

        setState(() {
          if (page == 1) {
            name = instructor["name"] ?? "";
            bio = instructor["bio"] ?? "";
            imageUrl = instructor["avatar"] ?? "https://i.pravatar.cc/150";
            rating = (instructor["averageRating"] ?? 0).toDouble();
            reviews = newReviews;
          } else {
            reviews.addAll(newReviews);
          }

          hasMore = newReviews.length == limit;
          currentPage = page;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      print("Exception: $e");
    }
  }

  Future<void> fetchInstructorStats(String token) async {
    const String url = "http://54.82.53.11:5001/api/instructor/courses/stats";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final stats = jsonData["data"];
        setState(() {
          sessions = stats["totalCourses"] ?? 0;
          students = stats["totalEnrolledStudents"] ?? 0;
          reviewsCount = stats["ratingCount"] ?? 0;
        });
      } else {
        print("Error fetching stats: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  Future<void> fetchMoreReviews() async {
    final token = await InstructorAuthService.getAccessToken();
    if (token != null && hasMore) {
      await fetchInstructorData(token, page: currentPage + 1);
    }
  }

  void _replyToReview(BuildContext context, String student) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Reply to $student"),
          content: const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your reply here...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Reply sent to $student")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
              ),
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> review,
    bool isDesktop,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final bubbleColor = isDark ? Colors.grey[700] : Colors.grey[50];
    final textColor = isDark ? Colors.black : Colors.white;

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isDesktop ? 28 : 20,
                  backgroundColor: const Color(0xFF5F299E),
                  backgroundImage: NetworkImage(
                    review["avatar"] ?? "https://i.pravatar.cc/150",
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review["student"] as String,
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 6 : 4),
                      Text(
                        review["date"] as String,
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review["rating"] as double,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: isDesktop ? 24 : 20,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 20 : 16),
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review["comment"] as String,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 14,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review["courseTitle"] ?? "No course title",
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _replyToReview(context, review["student"] as String),
                  icon: Icon(Icons.reply, size: isDesktop ? 20 : 18),
                  label: Text(
                    "Reply",
                    style: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5F299E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 1200;
        bool isTablet =
            constraints.maxWidth > 800 && constraints.maxWidth <= 1200;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Feedback & Reviews",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF5F299E),
            automaticallyImplyLeading: !kIsWeb,
          ),
          bottomNavigationBar: (isDesktop || isTablet)
              ? null
              : BottomNavigationBar(
                  selectedItemColor: const Color(0xFF5F299E),
                  unselectedItemColor: Colors.grey,
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CoursesPage(),
                        ),
                      );
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentPage(),
                        ),
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupsPage(),
                        ),
                      );
                    } else if (index == 3) {
                      Navigator.pushNamed(context, '/analytics');
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.school),
                      label: 'Courses',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'Students',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.groups),
                      label: 'Groups',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics),
                      label: 'Analytics',
                    ),
                  ],
                ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: isDesktop || isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.35,
                              child: InstructorCard(
                                name: name.isNotEmpty ? name : "Unknown",
                                bio: bio ?? "No bio available",
                                imageUrl: imageUrl.isNotEmpty
                                    ? imageUrl
                                    : "https://i.pravatar.cc/150",
                                rating: rating ?? 0.0,
                                isDesktop: isDesktop,
                                sessions: sessions,
                                students: students,
                                reviewsCount: reviewsCount,
                              ),
                            ),
                            SizedBox(width: constraints.maxWidth * 0.04),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Student Reviews",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "$reviewsCount total reviews",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount:
                                          reviews.length +
                                          (isLoadingMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index < reviews.length) {
                                          return _buildReviewCard(
                                            reviews[index],
                                            true,
                                            context,
                                          );
                                        } else {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              2 + reviews.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return InstructorCard(
                                name: name.isNotEmpty ? name : "Unknown",
                                bio: bio ?? "No bio available",
                                imageUrl: imageUrl.isNotEmpty
                                    ? imageUrl
                                    : "https://i.pravatar.cc/150",
                                rating: rating ?? 0.0,
                                isDesktop: false,
                              );
                            } else if (index == 1) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    "Student Reviews",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "$reviewsCount total reviews",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            } else {
                              final reviewIndex = index - 2;
                              if (reviewIndex < reviews.length) {
                                return _buildReviewCard(
                                  reviews[reviewIndex],
                                  false,
                                  context,
                                );
                              } else {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                ),
        );
      },
    );
  }
}
