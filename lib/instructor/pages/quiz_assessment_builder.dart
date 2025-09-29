import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizAssessmentBuilderPage extends StatefulWidget {
  final String? courseId;

  const QuizAssessmentBuilderPage({super.key, this.courseId});

  @override
  State<QuizAssessmentBuilderPage> createState() =>
      _QuizAssessmentBuilderPageState();
}

class _QuizAssessmentBuilderPageState extends State<QuizAssessmentBuilderPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<_Quiz> _quizzes = <_Quiz>[];
  final List<_Assessment> _assessments = <_Assessment>[];

  final TextEditingController _quizTitleCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls =
      List<TextEditingController>.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;
  bool _isLoading = false;

  final TextEditingController _assTitleCtrl = TextEditingController();
  final TextEditingController _assDescCtrl = TextEditingController();

  int? _editingQuizIndex;
  int? _editingAssessmentIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      print("Refreshing data for courseId: ${widget.courseId}");
      _fetchQuizzes();
      _fetchAssessments();
    } else {
      print("No courseId provided, clearing data");
      setState(() {
        _quizzes.clear();
        _assessments.clear();
      });
    }
  }

  @override
  void didUpdateWidget(covariant QuizAssessmentBuilderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.courseId != oldWidget.courseId) {
      print(
        "CourseId changed from ${oldWidget.courseId} to ${widget.courseId}",
      );
      _refreshData();
    }
  }

  Future<void> _fetchQuizzes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.get(
        Uri.parse(
          'http://54.82.53.11:5001/api/instructor/quizzes?page=1&limit=10',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> quizData = responseData['quizzes'] ?? [];
        setState(() {
          _quizzes.clear();
          _quizzes.addAll(
            quizData
                .where(
                  (q) => q != null && q['course']['_id'] == widget.courseId,
                )
                .map((q) {
                  final questions = q['questions'] as List<dynamic>? ?? [];
                  final firstQuestion = questions.isNotEmpty
                      ? questions[0]
                      : null;
                  return _Quiz(
                    id: (q['_id'] ?? '').toString(),
                    title: q['title'] ?? 'Untitled Quiz',
                    options:
                        firstQuestion != null &&
                            firstQuestion['options'] != null
                        ? List<String>.from(firstQuestion['options'])
                        : ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
                    correctIndex:
                        firstQuestion != null &&
                            firstQuestion['rightAnswer'] != null
                        ? firstQuestion['rightAnswer'] as int
                        : 0,
                  );
                })
                .toList(),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch quizzes (Code: ${response.statusCode})',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching quizzes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAssessments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.get(
        Uri.parse(
          'http://54.82.53.11:5001/api/instructor/assessments?page=1&limit=10',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> assessmentData = responseData['assessments'] ?? [];
        setState(() {
          _assessments.clear();
          _assessments.addAll(
            assessmentData
                .where(
                  (a) => a != null && a['course']['_id'] == widget.courseId,
                )
                .map((a) {
                  return _Assessment(
                    id: (a['_id'] ?? '').toString(),
                    title: a['title'] ?? 'Untitled Assessment',
                    description: a['description'] ?? 'No description',
                  );
                })
                .toList(),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch assessments (Code: ${response.statusCode})',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching assessments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quizTitleCtrl.dispose();
    for (final TextEditingController c in _optionCtrls) {
      c.dispose();
    }
    _assTitleCtrl.dispose();
    _assDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;
    final EdgeInsets pagePadding = EdgeInsets.symmetric(
      horizontal: isWide ? 24 : 12,
      vertical: isWide ? 16 : 12,
    );

    final bool hasCourse =
        widget.courseId != null && widget.courseId!.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Quiz & Assessment Builder'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const <Tab>[
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Quiz'),
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Assessment'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: hasCourse
                  ? TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        _buildQuizTab(isWide: isWide),
                        _buildAssessmentTab(isWide: isWide),
                      ],
                    )
                  : Center(
                      child: Card(
                        color: Colors.red[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No course selected.\nPlease select or create a course first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF5F299E)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF5F299E)),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.grey[50],
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF5F299E), width: 2),
      ),
    );
  }

  InputDecoration _optionDecoration(String hint) {
    return const InputDecoration(
      hintText: '',
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ).copyWith(hintText: hint);
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5F299E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(icon, color: const Color(0xFF5F299E)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5F299E),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        ],
      ],
    );
  }

  String _optionLabel(int index) => String.fromCharCode(65 + index);

  Widget _buildOptionField(int i) {
    final bool selected = _correctIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _correctIndex = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF5F299E) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? const Color(0xFF5F299E) : Colors.white,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _optionLabel(i),
                style: TextStyle(
                  color: selected ? const Color(0xFF5F299E) : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _optionCtrls[i],
                decoration: _optionDecoration('Option ${i + 1}'),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTab({required bool isWide}) {
    final Widget form = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _sectionHeader(
              icon: Icons.quiz_outlined,
              title: _editingQuizIndex != null ? 'Edit Quiz' : 'Create Quiz',
              subtitle:
                  'Add a title, four options, and select the correct one.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quizTitleCtrl,
              decoration: _inputDecoration('Quiz Title'),
              style: TextStyle(
                color: Colors.black,
                fontWeight: _quizTitleCtrl.text.isNotEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Options (tap to select correct one):'),
            const SizedBox(height: 8),
            for (int i = 0; i < 4; i++) _buildOptionField(i),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _editingQuizIndex != null ? 'Update Quiz' : 'Save Quiz',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F299E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : _editingQuizIndex != null
                    ? () => _updateQuiz(_editingQuizIndex!)
                    : _saveQuiz,
              ),
            ),
            if (_editingQuizIndex != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _cancelQuizEdit,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final Widget list = _isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF5F299E)),
            ),
          )
        : _quizzes.isEmpty
        ? Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No quizzes available.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        : Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchQuizzes,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _quizzes.length,
                itemBuilder: (BuildContext context, int index) {
                  final _Quiz q = _quizzes[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.quiz_outlined,
                        color: Color(0xFF5F299E),
                        size: 30,
                      ),
                      title: Text(
                        q.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          for (int i = 0; i < q.options.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '${_optionLabel(i)}.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: i == q.correctIndex
                                          ? const Color(0xFF5F299E)
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(q.options[i])),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF5F299E),
                          size: 24,
                        ),
                        onPressed: () => _editQuiz(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          );

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(flex: 1, child: form),
              const SizedBox(width: 16),
              Flexible(flex: 2, child: list),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              form,
              const SizedBox(height: 16),
              Expanded(child: list),
            ],
          );
  }

  Widget _buildAssessmentTab({required bool isWide}) {
    final FocusNode assTitleFocus = FocusNode();
    final FocusNode assDescFocus = FocusNode();

    final Widget form = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _sectionHeader(
              icon: Icons.assignment_turned_in,
              title: _editingAssessmentIndex != null
                  ? 'Edit Assessment'
                  : 'Create Assessment',
              subtitle: 'Add a title and description for the assessment.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assTitleCtrl,
              decoration: _inputDecoration('Title'),
              style: TextStyle(
                color: Colors.black,
                fontWeight: _assTitleCtrl.text.isNotEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assDescCtrl,
              focusNode: assDescFocus,
              maxLines: 5,
              style: TextStyle(
                color: Colors.black,
                fontWeight: _assDescCtrl.text.isNotEmpty
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              decoration: _inputDecoration(
                'Description',
              ).copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _editingAssessmentIndex != null
                      ? 'Update Assessment'
                      : 'Save Assessment',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F299E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : _editingAssessmentIndex != null
                    ? () => _updateAssessment(_editingAssessmentIndex!)
                    : _saveAssessment,
              ),
            ),
            if (_editingAssessmentIndex != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _cancelAssessmentEdit,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final Widget list = _isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF5F299E)),
            ),
          )
        : _assessments.isEmpty
        ? Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No assessments available.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        : Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAssessments,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _assessments.length,
                itemBuilder: (BuildContext context, int index) {
                  final _Assessment a = _assessments[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.assignment_turned_in,
                        color: Color(0xFF5F299E),
                        size: 30,
                      ),
                      title: Text(
                        a.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        a.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF5F299E),
                          size: 24,
                        ),
                        onPressed: () => _editAssessment(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          );

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(flex: 1, child: form),
              const SizedBox(width: 16),
              Flexible(flex: 2, child: list),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              form,
              const SizedBox(height: 16),
              Expanded(child: list),
            ],
          );
  }

  void _editQuiz(int index) {
    final _Quiz quiz = _quizzes[index];
    setState(() {
      _editingQuizIndex = index;
      _quizTitleCtrl.text = quiz.title;
      for (int i = 0; i < quiz.options.length && i < _optionCtrls.length; i++) {
        _optionCtrls[i].text = quiz.options[i];
      }
      _correctIndex = quiz.correctIndex;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Editing quiz. Update the form and save to apply changes.',
        ),
        backgroundColor: Color(0xFF5F299E),
      ),
    );
  }

  void _cancelQuizEdit() {
    setState(() {
      _editingQuizIndex = null;
      _quizTitleCtrl.clear();
      for (final TextEditingController c in _optionCtrls) {
        c.clear();
      }
      _correctIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz edit cancelled'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _editAssessment(int index) {
    final _Assessment assessment = _assessments[index];
    setState(() {
      _editingAssessmentIndex = index;
      _assTitleCtrl.text = assessment.title;
      _assDescCtrl.text = assessment.description;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Editing assessment. Update the form and save to apply changes.',
        ),
        backgroundColor: Color(0xFF5F299E),
      ),
    );
  }

  void _cancelAssessmentEdit() {
    setState(() {
      _editingAssessmentIndex = null;
      _assTitleCtrl.clear();
      _assDescCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assessment edit cancelled'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Future<void> _updateQuiz(int index) async {
    final String title = _quizTitleCtrl.text.trim();
    final List<String> options = _optionCtrls
        .map((e) => e.text.trim())
        .toList();
    if (title.isEmpty || options.any((String o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final _Quiz editingQuiz = _quizzes[index];
      final Map<String, dynamic> requestData = {
        "title": title,
        "course": widget.courseId,
        "questions": [
          {
            "question": "Which of the following is correct?",
            "options": options,
            "rightAnswer": _correctIndex,
          },
        ],
        "timeLimit": 15,
        "active": true,
      };
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.put(
        Uri.parse('http://54.82.53.11:5001/api/quizzes/${editingQuiz.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchQuizzes();
        setState(() {
          _quizzes[index] = _Quiz(
            id: editingQuiz.id,
            title: title,
            options: options,
            correctIndex: _correctIndex,
          );
          _editingQuizIndex = null;
        });
        _quizTitleCtrl.clear();
        for (final TextEditingController c in _optionCtrls) {
          c.clear();
        }
        _correctIndex = 0;
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${responseData['message'] ?? 'Failed to update quiz'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveQuiz() async {
    final String title = _quizTitleCtrl.text.trim();
    final List<String> options = _optionCtrls
        .map((e) => e.text.trim())
        .toList();
    if (title.isEmpty || options.any((String o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (widget.courseId == null || widget.courseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course ID is missing. Cannot create quiz.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final Map<String, dynamic> requestData = {
        "title": title,
        "course": widget.courseId,
        "questions": [
          {
            "question": "Which of the following is correct?",
            "options": options,
            "rightAnswer": _correctIndex,
          },
        ],
        "timeLimit": 15,
        "active": true,
      };
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.post(
        Uri.parse('http://54.82.53.11:5001/api/quizzes/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchQuizzes(); // Refresh the quiz list from the server
        _quizTitleCtrl.clear();
        for (final TextEditingController c in _optionCtrls) {
          c.clear();
        }
        _correctIndex = 0;
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${responseData['message'] ?? 'Failed to create quiz'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAssessment(int index) async {
    final String title = _assTitleCtrl.text.trim();
    final String description = _assDescCtrl.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final _Assessment editingAssessment = _assessments[index];
      final Map<String, dynamic> requestData = {
        "title": title,
        "description": description,
        "course": widget.courseId,
        "dueDate": DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        "totalPoints": 100,
        "active": true,
      };
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.put(
        Uri.parse(
          'http://54.82.53.11:5001/api/assessments/${editingAssessment.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchAssessments();
        setState(() {
          _assessments[index] = _Assessment(
            id: editingAssessment.id,
            title: title,
            description: description,
          );
          _editingAssessmentIndex = null;
        });
        _assTitleCtrl.clear();
        _assDescCtrl.clear();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${responseData['message'] ?? 'Failed to update assessment'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveAssessment() async {
    final String title = _assTitleCtrl.text.trim();
    final String description = _assDescCtrl.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (widget.courseId == null || widget.courseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course ID is missing. Cannot create assessment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final Map<String, dynamic> requestData = {
        "title": title,
        "description": description,
        "course": widget.courseId,
        "dueDate": DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        "totalPoints": 100,
        "active": true,
      };
      final token = await InstructorAuthService.getAccessToken();
      final response = await http.post(
        Uri.parse('http://54.82.53.11:5001/api/assessments/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchAssessments(); // Refresh the assessment list from the server
        _assTitleCtrl.clear();
        _assDescCtrl.clear();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${responseData['message'] ?? 'Failed to create assessment'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _Quiz {
  _Quiz({
    required this.id,
    required this.title,
    required this.options,
    required this.correctIndex,
  });
  final String id;
  final String title;
  final List<String> options;
  final int correctIndex;
}

class _Assessment {
  _Assessment({
    required this.id,
    required this.title,
    required this.description,
  });
  final String id;
  final String title;
  final String description;
}
