import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';

class SubcategoryPage extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;

  const SubcategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  List<Map<String, dynamic>> _getSubcategories(String categoryName) {
    switch (categoryName) {
      case 'Digital Marketing':
        return [
          {
            'name': 'SEO Optimization',
            'courses': '15 courses',
            'color': Color(0xFFFF6B6B),
            'icon': '🔍',
          },
          {
            'name': 'Social Media Marketing',
            'courses': '12 courses',
            'color': Color(0xFF4ECDC4),
            'icon': '📱',
          },
          {
            'name': 'Email Marketing',
            'courses': '8 courses',
            'color': Color(0xFF45B7D1),
            'icon': '📧',
          },
          {
            'name': 'Content Marketing',
            'courses': '10 courses',
            'color': Color(0xFF96CEB4),
            'icon': '📝',
          },
          {
            'name': 'PPC Advertising',
            'courses': '6 courses',
            'color': Color(0xFFFECA57),
            'icon': '💰',
          },
        ];
      case 'UI/UX Design':
        return [
          {
            'name': 'User Interface Design',
            'courses': '12 courses',
            'color': Color(0xFF6C5CE7),
            'icon': '🎨',
          },
          {
            'name': 'User Experience Research',
            'courses': '8 courses',
            'color': Color(0xFFA29BFE),
            'icon': '🔬',
          },
          {
            'name': 'Prototyping',
            'courses': '10 courses',
            'color': Color(0xFF74B9FF),
            'icon': '🛠️',
          },
          {
            'name': 'Design Systems',
            'courses': '6 courses',
            'color': Color(0xFF00B894),
            'icon': '📐',
          },
          {
            'name': 'Mobile App Design',
            'courses': '9 courses',
            'color': Color(0xFFE17055),
            'icon': '📱',
          },
        ];
      case 'Flutter Development':
        return [
          {
            'name': 'Flutter Basics',
            'courses': '8 courses',
            'color': Color(0xFF0984E3),
            'icon': '📱',
          },
          {
            'name': 'State Management',
            'courses': '6 courses',
            'color': Color(0xFF6C5CE7),
            'icon': '⚡',
          },
          {
            'name': 'Firebase Integration',
            'courses': '5 courses',
            'color': Color(0xFFE17055),
            'icon': '🔥',
          },
          {
            'name': 'Advanced Widgets',
            'courses': '7 courses',
            'color': Color(0xFF00B894),
            'icon': '🧩',
          },
          {
            'name': 'App Deployment',
            'courses': '4 courses',
            'color': Color(0xFFFECA57),
            'icon': '🚀',
          },
        ];
      case 'DevOps':
        return [
          {
            'name': 'Docker & Containers',
            'courses': '8 courses',
            'color': Color(0xFF0984E3),
            'icon': '🐳',
          },
          {
            'name': 'Kubernetes',
            'courses': '6 courses',
            'color': Color(0xFF6C5CE7),
            'icon': '☸️',
          },
          {
            'name': 'CI/CD Pipelines',
            'courses': '7 courses',
            'color': Color(0xFF00B894),
            'icon': '🔄',
          },
          {
            'name': 'AWS Cloud',
            'courses': '9 courses',
            'color': Color(0xFFE17055),
            'icon': '☁️',
          },
          {
            'name': 'Monitoring & Logging',
            'courses': '5 courses',
            'color': Color(0xFFFECA57),
            'icon': '📊',
          },
        ];
      case 'Data Science':
        return [
          {
            'name': 'Python for Data Science',
            'courses': '10 courses',
            'color': Color(0xFF0984E3),
            'icon': '🐍',
          },
          {
            'name': 'Machine Learning',
            'courses': '8 courses',
            'color': Color(0xFF6C5CE7),
            'icon': '🤖',
          },
          {
            'name': 'Data Visualization',
            'courses': '6 courses',
            'color': Color(0xFF00B894),
            'icon': '📊',
          },
          {
            'name': 'Statistics',
            'courses': '7 courses',
            'color': Color(0xFFE17055),
            'icon': '📈',
          },
          {
            'name': 'Big Data Analytics',
            'courses': '5 courses',
            'color': Color(0xFFFECA57),
            'icon': '💾',
          },
        ];
      case 'Software Testing':
        return [
          {
            'name': 'Manual Testing',
            'courses': '8 courses',
            'color': Color(0xFF0984E3),
            'icon': '🧪',
          },
          {
            'name': 'Automation Testing',
            'courses': '6 courses',
            'color': Color(0xFF6C5CE7),
            'icon': '🤖',
          },
          {
            'name': 'Performance Testing',
            'courses': '5 courses',
            'color': Color(0xFF00B894),
            'icon': '⚡',
          },
          {
            'name': 'API Testing',
            'courses': '7 courses',
            'color': Color(0xFFE17055),
            'icon': '🔗',
          },
          {
            'name': 'Mobile Testing',
            'courses': '4 courses',
            'color': Color(0xFFFECA57),
            'icon': '📱',
          },
        ];
      default:
        return [
          {
            'name': 'Basic Course',
            'courses': '5 courses',
            'color': Color(0xFF0984E3),
            'icon': '📚',
          },
          {
            'name': 'Intermediate Course',
            'courses': '8 courses',
            'color': Color(0xFF6C5CE7),
            'icon': '📖',
          },
          {
            'name': 'Advanced Course',
            'courses': '6 courses',
            'color': Color(0xFF00B894),
            'icon': '🎓',
          },
        ];
    }
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: subcategory['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(subcategory['icon'], style: TextStyle(fontSize: 24)),
            ),
          ),
          SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subcategory['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subcategory['courses'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _getSubcategories(categoryName);

    return AppLayout(
      title: categoryName,
      currentIndex: 1, // Categories tab
      showBackButton: true,
      showBottomNavigation: false, // Hide bottom navigation
      showHeaderActions: false, // Hide header icons
      child: Column(
        children: [
          // Category header section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5F299E), Color(0xFF7B68EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Category title
                Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // Toggle buttons
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Courses',
                          style: TextStyle(
                            color: Color(0xFF5F299E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          'Quizzes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Progress indicator
                Row(
                  children: [
                    Text(
                      'Learn 50% left',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Spacer(),
                    Text(
                      'Next 50% left',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [Colors.pink, Colors.blue],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subcategories list
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  return _buildSubcategoryCard(subcategories[index]);
                },
              ),
            ),
          ),
        ],
      ),
      // Same bottom navigation as other pages
      // bottomNavigationBar: Container(
      //   height: 90,
      //   decoration: BoxDecoration(
      //     gradient: LinearGradient(
      //       colors: [Color(0xFF5F299E), Color(0xFF5F299E), Color(0xFF5F299E)],
      //       begin: Alignment.topLeft,
      //       end: Alignment.bottomRight,
      //     ),
      //     borderRadius: BorderRadius.only(
      //       topLeft: Radius.circular(30),
      //       topRight: Radius.circular(30),
      //     ),
      //   ),
      //   child: SafeArea(
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 20),
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceAround,
      //         children: [
      //           _buildNavItem(Icons.home_outlined, 0, context),
      //           _buildNavItem(Icons.search_outlined, 1, context),
      //           _buildNavItem(Icons.play_circle_outline, 2, context),
      //           _buildNavItem(Icons.bookmark_border, 3, context),
      //           _buildNavItem(Icons.person_outline, 4, context),
      //         ],
      //       ),
      //     ),
      //   ),
    );
  }
}
