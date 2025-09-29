import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Course details
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedLevel = 'beginner';
  String _selectedCategory = '';
  final List<String> _categories = [
    'Web Development',
    'Mobile Development',
    'Data Science',
    'Design',
    'AI & Machine Learning',
  ];

  // Course content sections
  List<CourseSection> _sections = [];

  @override
  void initState() {
    super.initState();
    // Initialize with empty welcome section
    _sections = [
      CourseSection(
        title: 'Welcome',
        lectures: [Lecture(title: 'Introduction', duration: 1)],
      ),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sections.add(
        CourseSection(
          title: 'New Section',
          lectures: [Lecture(title: 'New Lecture', duration: 5)],
        ),
      );
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _addLecture(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].lectures.add(
        Lecture(title: 'New Lecture', duration: 5),
      );
    });
  }

  void _removeLecture(int sectionIndex, int lectureIndex) {
    setState(() {
      _sections[sectionIndex].lectures.removeAt(lectureIndex);
    });
  }

  int _getTotalLectures() {
    int total = 0;
    for (var section in _sections) {
      total += section.lectures.length;
    }
    return total;
  }

  String _getTotalDuration() {
    int minutes = 0;
    for (var section in _sections) {
      for (var lecture in section.lectures) {
        minutes += lecture.duration;
      }
    }

    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    }
  }

  // Theme-aware color helpers
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF8F9FA);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  Color _getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF8F9FA);
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1A1A);
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]!
        : Colors.grey[600]!;
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE5E7EB);
  }

  LinearGradient _getPurpleGradient() {
    return const LinearGradient(
      colors: [Color(0xFF5F299E), Color(0xFF7B3FB3)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        title: const Text(
          'Create New Course',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            double horizontalPadding = _getHorizontalPadding(sizingInformation);
            bool isMobile = sizingInformation.deviceScreenType == DeviceScreenType.mobile;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark 
                      ? [const Color(0xFF121212), const Color(0xFF0F0F0F)]
                      : [const Color(0xFFF8F9FA), const Color(0xFFF1F3F4)],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: const Color(0xFF5F299E),
                      ),
                    ),
                    child: Stepper(
                      type: isMobile ? StepperType.vertical : StepperType.horizontal,
                      currentStep: _currentStep,
                      onStepTapped: (step) => setState(() => _currentStep = step),
                      physics: const ClampingScrollPhysics(),
                      margin: EdgeInsets.zero,
                      controlsBuilder: (context, details) {
                        return _buildStepControls(details, isMobile);
                      },
                      onStepContinue: () {
                        if (_currentStep < 2) {
                          if (_currentStep == 0) {
                            if (_formKey.currentState?.validate() == true) {
                              setState(() => _currentStep += 1);
                            }
                          } else {
                            setState(() => _currentStep += 1);
                          }
                        } else {
                          _submitForm();
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep -= 1);
                        }
                      },
                      steps: [
                        Step(
                          title: Text(
                            'Basic Info',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: _getTextColor(context),
                            ),
                          ),
                          isActive: _currentStep >= 0,
                          content: _buildBasicInfoStep(isMobile),
                          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                        ),
                        Step(
                          title: Text(
                            'Content',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: _getTextColor(context),
                            ),
                          ),
                          isActive: _currentStep >= 1,
                          content: _buildContentStep(isMobile),
                          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                        ),
                        Step(
                          title: Text(
                            'Preview & Publish',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: _getTextColor(context),
                            ),
                          ),
                          isActive: _currentStep >= 2,
                          content: _buildSettingsStep(isMobile),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getHorizontalPadding(SizingInformation sizingInformation) {
    switch (sizingInformation.deviceScreenType) {
      case DeviceScreenType.desktop:
        return MediaQuery.of(context).size.width * 0.2;
      case DeviceScreenType.tablet:
        return 32.0;
      case DeviceScreenType.mobile:
      default:
        return 16.0;
    }
  }

  Widget _buildStepControls(ControlsDetails details, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: isMobile ? 1 : 0,
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: details.onStepCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCardColor(context),
                    foregroundColor: const Color(0xFF5F299E),
                    elevation: 1,
                    side: const BorderSide(color: Color(0xFF5F299E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: isMobile ? 2 : 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: _getPurpleGradient(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5F299E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  _currentStep == 2 ? Icons.publish : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(
                  _currentStep == 2 ? 'Create Course' : 'Continue',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Information',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your course to help students understand what they\'ll learn',
            style: TextStyle(
              color: _getSubtitleColor(context),
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          const SizedBox(height: 32),

          // Course Title
          _buildInputField(
            controller: _titleController,
            label: 'Course Title',
            hint: 'Enter a clear and engaging title',
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a course title';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Course Description
          _buildInputField(
            controller: _descriptionController,
            label: 'Course Description',
            hint: 'Describe what students will learn and achieve',
            icon: Icons.description,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a course description';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Category and Price Row
          if (isMobile)
            Column(
              children: [
                _buildCategoryDropdown(),
                const SizedBox(height: 24),
                _buildPriceField(),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildCategoryDropdown()),
                const SizedBox(width: 24),
                Expanded(child: _buildPriceField()),
              ],
            ),
          const SizedBox(height: 32),

          // Course Level
          _buildLevelSelection(isMobile),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: _getTextColor(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _getSubtitleColor(context)),
            prefixIcon: Icon(icon, color: const Color(0xFF5F299E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5F299E), width: 2),
            ),
            filled: true,
            fillColor: _getSurfaceColor(context),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: _getCardColor(context),
          style: TextStyle(color: _getTextColor(context)),
          decoration: InputDecoration(
            hintText: 'Select a category',
            hintStyle: TextStyle(color: _getSubtitleColor(context)),
            prefixIcon: const Icon(Icons.category, color: Color(0xFF5F299E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5F299E), width: 2),
            ),
            filled: true,
            fillColor: _getSurfaceColor(context),
            contentPadding: const EdgeInsets.all(16),
          ),
          initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _getTextColor(context)),
          decoration: InputDecoration(
            hintText: 'Enter course price',
            hintStyle: TextStyle(color: _getSubtitleColor(context)),
            prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF5F299E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5F299E), width: 2),
            ),
            filled: true,
            fillColor: _getSurfaceColor(context),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLevelSelection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile)
          Column(
            children: [
              _buildLevelRadio('Beginner', 'beginner'),
              _buildLevelRadio('Intermediate', 'intermediate'),
              _buildLevelRadio('Advanced', 'advanced'),
            ],
          )
        else
          Row(
            children: [
              _buildLevelRadio('Beginner', 'beginner'),
              _buildLevelRadio('Intermediate', 'intermediate'),
              _buildLevelRadio('Advanced', 'advanced'),
            ],
          ),
      ],
    );
  }

  Widget _buildLevelRadio(String title, String value) {
    final isSelected = _selectedLevel == value;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF5F299E).withOpacity(0.1) 
              : _getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF5F299E) 
                : _getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: RadioListTile<String>(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected 
                  ? const Color(0xFF5F299E) 
                  : _getTextColor(context),
            ),
          ),
          value: value,
          groupValue: _selectedLevel,
          activeColor: const Color(0xFF5F299E),
          onChanged: (String? value) {
            setState(() {
              _selectedLevel = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildContentStep(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Content',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Structure your course with sections and lectures',
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _getPurpleGradient(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_getTotalLectures()} lectures',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _getTotalDuration(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // List of Sections
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, sectionIndex) {
              return _buildSectionCard(sectionIndex, isMobile);
            },
          ),

          // Add Section Button
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _getPurpleGradient(),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5F299E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _addSection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Add New Section',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(int sectionIndex, bool isMobile) {
    final section = _sections[sectionIndex];
    return Container(
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: section.lectures.length <= 2,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: _getTextColor(context),
          collapsedIconColor: _getTextColor(context),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _getPurpleGradient(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${sectionIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: TextFormField(
            initialValue: section.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _getTextColor(context),
            ),
            decoration: const InputDecoration(
              hintText: 'Section Title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() {
                _sections[sectionIndex].title = value;
              });
            },
          ),
          subtitle: Text(
            '${section.lectures.length} lecture${section.lectures.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: _getSubtitleColor(context),
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeSection(sectionIndex),
              ),
            ],
          ),
          children: [
            // List of Lectures
            Column(
              children: List.generate(
                section.lectures.length,
                (lectureIndex) => _buildLectureItem(sectionIndex, lectureIndex, isMobile),
              ),
            ),

            // Add Lecture Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _addLecture(sectionIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSurfaceColor(context),
                  foregroundColor: const Color(0xFF5F299E),
                  elevation: 0,
                  side: BorderSide(color: _getBorderColor(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Add Lecture',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureItem(int sectionIndex, int lectureIndex, bool isMobile) {
    final lecture = _sections[sectionIndex].lectures[lectureIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5F299E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_circle_outline,
              color: Color(0xFF5F299E),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: lecture.title,
              style: TextStyle(
                fontSize: 14,
                color: _getTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: 'Lecture Title',
                hintStyle: TextStyle(color: _getSubtitleColor(context)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _sections[sectionIndex].lectures[lectureIndex].title = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: lecture.duration.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _getTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: 'Min',
                hintStyle: TextStyle(color: _getSubtitleColor(context)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                int? duration = int.tryParse(value);
                if (duration != null) {
                  setState(() {
                    _sections[sectionIndex].lectures[lectureIndex].duration = duration;
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            onPressed: () => _removeLecture(sectionIndex, lectureIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsStep(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Preview',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review how your course will appear to students',
            style: TextStyle(
              color: _getSubtitleColor(context),
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          const SizedBox(height: 24),

          // Course Preview Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF5F299E).withOpacity(0.1),
                        const Color(0xFF7B3FB3).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFF5F299E).withOpacity(0.05),
                        const Color(0xFF7B3FB3).withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image Placeholder
                Container(
                  height: isMobile ? 120 : 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _getPurpleGradient(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Course Thumbnail',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedLevel.capitalizeFirst(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Course Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.isEmpty
                            ? 'Your Course Title'
                            : _titleController.text,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 18 : 20,
                          color: _getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _descriptionController.text.isEmpty
                            ? 'Your course description will appear here to help students understand what they\'ll learn.'
                            : _descriptionController.text,
                        style: TextStyle(
                          color: _getSubtitleColor(context),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // Course Stats
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.play_circle_outline,
                            '${_getTotalLectures()} lectures',
                            const Color(0xFF5F299E),
                          ),
                          _buildInfoChip(
                            Icons.access_time,
                            _getTotalDuration(),
                            const Color(0xFF5F299E),
                          ),
                          _buildInfoChip(
                            Icons.category_outlined,
                            _selectedCategory.isEmpty ? 'Category' : _selectedCategory,
                            _getSubtitleColor(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getSubtitleColor(context),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: _getPurpleGradient(),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _priceController.text.isEmpty
                                  ? '\$0'
                                  : '\${_priceController.text}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Upload Cover Image Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _getSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getBorderColor(context)),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                // Image upload functionality would go here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFF5F299E),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text(
                'Upload Course Thumbnail',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Publish Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getBorderColor(context)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: _getPurpleGradient(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.publish,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publish Course',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _getTextColor(context),
                            ),
                          ),
                          Text(
                            'Make your course available to students immediately',
                            style: TextStyle(
                              color: _getSubtitleColor(context),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: true,
                      activeThumbColor: const Color(0xFF5F299E),
                      onChanged: (bool value) {
                        // Toggle publish state
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Course Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF5F299E).withOpacity(0.1),
                        const Color(0xFF7B3FB3).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFF5F299E).withOpacity(0.05),
                        const Color(0xFF7B3FB3).withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5F299E).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF5F299E),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Course Summary',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'ve created ${_sections.length} section${_sections.length != 1 ? 's' : ''} with ${_getTotalLectures()} lecture${_getTotalLectures() != 1 ? 's' : ''}. Total course duration: ${_getTotalDuration()}.',
                  style: TextStyle(
                    color: _getSubtitleColor(context),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() == true) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getCardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getBorderColor(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: _getPurpleGradient(),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Course Created Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your course "${_titleController.text}" has been created and is ready to be published to students.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getSubtitleColor(context),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _getPurpleGradient(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Return to courses page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

// Helper model classes
class CourseSection {
  String title;
  List<Lecture> lectures;

  CourseSection({required this.title, required this.lectures});
}

class Lecture {
  String title;
  int duration; // in minutes

  Lecture({required this.title, required this.duration});
}

// Extensions
extension StringExtension on String {
  String capitalizeFirst() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}