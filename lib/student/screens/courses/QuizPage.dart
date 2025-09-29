import 'package:flutter/material.dart';
import '../../widgets/app_layout.dart';

class QuizPage extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  final String categoryIcon;
  final Color categoryColor;

  const QuizPage({
    super.key,
    required this.categoryName,
    this.categoryId,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final bool _isLoading = false;

  // Quizzes data
  List<Map<String, dynamic>> _getQuizzes(String categoryName) {
    return [
      {
        'name': '$categoryName Basics Quiz',
        'quizzes': '5 quizzes',
        'color': const Color(0xFF6C5CE7),
        'icon': '❓',
        'difficulty': 'Beginner',
        'duration': '15 min',
        'questions': 10,
      },
      {
        'name': 'Intermediate $categoryName Quiz',
        'quizzes': '4 quizzes',
        'color': const Color(0xFFE17055),
        'icon': '📝',
        'difficulty': 'Intermediate',
        'duration': '20 min',
        'questions': 15,
      },
      {
        'name': 'Advanced $categoryName Quiz',
        'quizzes': '3 quizzes',
        'color': const Color(0xFF00B894),
        'icon': '🏆',
        'difficulty': 'Advanced',
        'duration': '30 min',
        'questions': 20,
      },
      {
        'name': '$categoryName Mock Test',
        'quizzes': '2 quizzes',
        'color': const Color(0xFFFF6B6B),
        'icon': '🧪',
        'difficulty': 'Expert',
        'duration': '45 min',
        'questions': 25,
      },
      {
        'name': '$categoryName Final Exam',
        'quizzes': '1 quiz',
        'color': const Color(0xFF45B7D1),
        'icon': '📊',
        'difficulty': 'Master',
        'duration': '60 min',
        'questions': 50,
      },
    ];
  }

  // Quiz card builder
  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Handle quiz tap - navigate to quiz details or start quiz
          _showQuizDialog(quiz);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Quiz icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: quiz['color'].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      quiz['icon'],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Quiz info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: quiz['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quiz['difficulty'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: quiz['color'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quiz details
            Row(
              children: [
                _buildQuizDetail(
                  Icons.quiz_outlined,
                  '${quiz['questions']} Questions',
                  quiz['color'],
                ),
                const SizedBox(width: 20),
                _buildQuizDetail(
                  Icons.access_time_rounded,
                  quiz['duration'],
                  quiz['color'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizDetail(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showQuizDialog(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Text(
                quiz['icon'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quiz['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Details:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _buildDialogDetail('Difficulty', quiz['difficulty']),
              _buildDialogDetail('Duration', quiz['duration']),
              _buildDialogDetail('Questions', '${quiz['questions']} questions'),
              const SizedBox(height: 16),
              Text(
                'Are you ready to start this quiz?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to quiz taking screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting ${quiz['name']}...'),
                    backgroundColor: quiz['color'],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: quiz['color'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Quiz'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _getQuizzes(widget.categoryName);

    return AppLayout(
      title: '${widget.categoryName} Quizzes',
      currentIndex: 1, // Categories tab
      showBackButton: true,
      showBottomNavigation: false, // Hide bottom navigation
      showHeaderActions: false, // Hide header icons
      child: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
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
                        '${widget.categoryName} Quizzes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Test your knowledge with ${quizzes.length} available quizzes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quizzes list
                Expanded(
                  child: quizzes.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            itemCount: quizzes.length,
                            itemBuilder: (context, index) {
                              return _buildQuizCard(quizzes[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF5F299E)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading quizzes...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No quizzes available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quizzes for this category will be available soon',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
