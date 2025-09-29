import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../models/course.dart';

class AddEditCourseScreen extends StatefulWidget {
  final Course? course;

  const AddEditCourseScreen({super.key, this.course});

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedLevel = 'beginner';
  bool _published = true;

  // Dropdown data
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _instructors = [];
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedInstructorId;
  
  // File uploads
  File? _selectedThumbnail;
  Uint8List? _selectedThumbnailBytes;
  File? _selectedIntroVideo;
  
  // Remove multiple file uploads - only single thumbnail and intro video needed
  
  bool _isUploading = false;
  bool _isCreating = false;

  // Uploaded URLs
  String? _uploadedThumbnailUrl;
  String? _uploadedIntroVideoUrl;
  
  // Intro video additional fields
  final _introVideoTitleController = TextEditingController();
  final _introVideoDescriptionController = TextEditingController();
  final _introVideoDurationController = TextEditingController();
  String? _uploadedIntroVideoThumbnailUrl;

  // Course sections
  final List<CourseSectionData> _sections = [];

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('DEBUG: Starting initialization, isEditing: $isEditing');
    await _loadCategories();
    await _loadInstructors();
    if (isEditing) {
      print('DEBUG: About to populate fields');
      _populateFields();
      print('DEBUG: Fields populated, sections count: ${_sections.length}');
    }
    // Don't automatically add a section - let user add manually
  }

  void _populateFields() {
    final course = widget.course!;
    print('DEBUG: Populating fields for course: ${course.title}');
    print('DEBUG: Course has ${course.sections.length} sections');
    for (var section in course.sections) {
      print('DEBUG: Section: ${section.title} with ${section.videos.length} videos');
    }
    
    _titleController.text = course.title;
    _descriptionController.text = course.description;
    _priceController.text = course.price.toString();
    _selectedLevel = course.level;
    _published = course.published;
    
    // Set dropdown values for editing
    _selectedCategoryId = course.category.id;
    _selectedSubcategoryId = course.subcategory.id;
    _selectedInstructorId = course.instructor.id;
    
    // Load existing thumbnail URL
    _uploadedThumbnailUrl = course.thumbnail;
    
    // Load existing intro video if available
    if (course.introVideo != null) {
      _uploadedIntroVideoUrl = course.introVideo!.url;
      _introVideoTitleController.text = course.introVideo!.title;
      _introVideoDescriptionController.text = course.introVideo!.description;
      _introVideoDurationController.text = course.introVideo!.durationSeconds.toString();
    }
    
    // Load existing sections and videos
    _sections.clear();
    print('DEBUG: Loading ${course.sections.length} sections for editing');
    
    for (var section in course.sections) {
      print('DEBUG: Loading section: ${section.title} with ${section.videos.length} videos');
      
      final sectionData = CourseSectionData(
        titleController: TextEditingController(text: section.title),
        descriptionController: TextEditingController(text: section.description),
        videos: [],
      );
      
      // Load existing videos in this section
      for (var video in section.videos) {
        print('DEBUG: Loading video: ${video.title}');
        sectionData.videos.add(CourseVideoData(
          file: null, // No file for existing videos
          bytes: null,
          titleController: TextEditingController(text: video.title),
          descriptionController: TextEditingController(text: video.description),
          durationController: TextEditingController(text: video.durationSeconds.toString()),
          orderController: TextEditingController(text: video.order.toString()),
          uploadedUrl: video.url, // Existing video URL
        ));
      }
      
      _sections.add(sectionData);
    }
    
    print('DEBUG: Total sections loaded: ${_sections.length}');
    setState(() {}); // Trigger rebuild to show sections
  }

  // Single Thumbnail Upload
  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        Map<String, dynamic> uploadResult;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          uploadResult = await ApiService.uploadCourseImage('thumbnail.jpg', imageBytes: bytes);
          setState(() {
            _selectedThumbnailBytes = Uint8List.fromList(bytes);
            _selectedThumbnail = null;
          });
        } else {
          uploadResult = await ApiService.uploadCourseImage(image.path);
          setState(() {
            _selectedThumbnail = File(image.path);
            _selectedThumbnailBytes = null;
          });
        }

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // Extract URL from API response
          String? thumbnailUrl;
          final data = uploadResult['data'];
          
          if (data is String) {
            thumbnailUrl = data;
          } else if (data is Map && data['url'] != null) {
            thumbnailUrl = data['url'].toString();
          } else if (data is Map && data['image'] != null && data['image']['url'] != null) {
            thumbnailUrl = data['image']['url'].toString();
          }
          
          setState(() {
            _uploadedThumbnailUrl = thumbnailUrl ?? '';
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thumbnail uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload thumbnail: ${uploadResult['message']}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Single Intro Video Upload
  Future<void> _pickIntroVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );
      
      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        Map<String, dynamic> uploadResult;
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          uploadResult = await ApiService.uploadCourseVideo(result.files.first.name, videoBytes: bytes);
          setState(() {
            _selectedIntroVideo = File(result.files.first.name);
          });
        } else {
          uploadResult = await ApiService.uploadCourseVideo(result.files.first.path!);
          setState(() {
            _selectedIntroVideo = File(result.files.first.path!);
          });
        }

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // Extract URL from API response
          String? introVideoUrl;
          final data = uploadResult['data'];
          
          if (data is String) {
            introVideoUrl = data;
          } else if (data is Map && data['url'] != null) {
            introVideoUrl = data['url'].toString();
          } else if (data is Map && data['video'] != null && data['video']['url'] != null) {
            introVideoUrl = data['video']['url'].toString();
          }
          
          setState(() {
            _uploadedIntroVideoUrl = introVideoUrl ?? '';
            _isUploading = false;
            // Set default values for intro video fields
            if (_introVideoTitleController.text.isEmpty) {
              _introVideoTitleController.text = 'Course Overview';
            }
            if (_introVideoDescriptionController.text.isEmpty) {
              _introVideoDescriptionController.text = 'What you\'ll learn in this course';
            }
            if (_introVideoDurationController.text.isEmpty) {
              _introVideoDurationController.text = '180';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Intro video uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload intro video: ${uploadResult['message']}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Course' : 'Create Course'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: (_isCreating || _isUploading) ? null : _saveCourse,
            child: (_isCreating || _isUploading)
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('SAVING...'),
                    ],
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionHeader('Basic Information', Icons.info_outline),
              const SizedBox(height: 16),
              _buildCard([
                _buildTextField(
                  controller: _titleController,
                  label: 'Course Title *',
                  hint: 'Enter course title',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description *',
                  hint: 'Enter course description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _priceController,
                  label: 'Price (₹) *',
                  hint: 'Enter course price',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildLevelDropdown(),
                const SizedBox(height: 16),
                _buildPublishedSwitch(),
              ]),

              const SizedBox(height: 24),

              // Category & Instructor
              _buildSectionHeader('Category & Instructor', Icons.category),
              const SizedBox(height: 16),
              _buildCard([
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildSubcategoryDropdown(),
                const SizedBox(height: 16),
                _buildInstructorDropdown(),
              ]),

              const SizedBox(height: 24),

              // Media Files
              _buildSectionHeader('Media Files', Icons.attach_file),
              const SizedBox(height: 16),
              _buildCard([
                _buildFileUploadSection(),
              ]),

              const SizedBox(height: 24),

              // Course Sections
              _buildSectionHeader('Course Content', Icons.library_books),
              const SizedBox(height: 16),
              _buildCard([
                _buildSectionsSection(),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF9C27B0), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Thumbnail Section
        const Text(
          'Course Thumbnail',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (_selectedThumbnail != null || _selectedThumbnailBytes != null || _uploadedThumbnailUrl != null) ...[
          Container(
            width: 120,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb && _selectedThumbnailBytes != null
                      ? Image.memory(
                          _selectedThumbnailBytes!,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                        )
                      : _selectedThumbnail != null
                          ? Image.file(
                              _selectedThumbnail!,
                              width: 120,
                              height: 90,
                              fit: BoxFit.cover,
                            )
                          : _uploadedThumbnailUrl != null
                              ? Image.network(
                                  _getFullImageUrl(_uploadedThumbnailUrl!),
                                  width: 120,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 90,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    );
                                  },
                                )
                              : Container(
                                  width: 120,
                                  height: 90,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedThumbnail = null;
                        _selectedThumbnailBytes = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No thumbnail selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        const SizedBox(height: 12),
        
        // Add Thumbnail Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickThumbnail,
            icon: const Icon(Icons.add_photo_alternate, size: 18),
            label: const Text('Add Thumbnail'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Intro Video Section
        Row(
          children: [
            const Text(
              'Intro Video',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickIntroVideo,
              icon: const Icon(Icons.video_call, size: 18),
              label: const Text('Add Intro Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedIntroVideo != null || _uploadedIntroVideoUrl != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedIntroVideo?.path.split('/').last ?? 
                        (_uploadedIntroVideoUrl != null ? 'Existing Intro Video' : 'No video selected'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIntroVideo = null;
                          _uploadedIntroVideoUrl = null;
                          _introVideoTitleController.clear();
                          _introVideoDescriptionController.clear();
                          _introVideoDurationController.clear();
                        });
                      },
                      child: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _introVideoTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Intro Video Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _introVideoDescriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Intro Video Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _introVideoDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No intro video selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  // Load categories from API
  Future<void> _loadCategories() async {
    try {
      final result = await ApiService.getCategories();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  // Load subcategories based on selected category
  Future<void> _loadSubcategories(String categoryId) async {
    setState(() {
      _subcategories = [];
      _selectedSubcategoryId = null;
    });

    try {
      final result = await ApiService.getSubcategories(categoryId);
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _subcategories = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subcategories: $e')),
      );
    }
  }

  // Load instructors from API
  Future<void> _loadInstructors() async {
    try {
      final result = await ApiService.getInstructors(limit: 100);
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _instructors = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load instructors: $e')),
      );
    }
  }

  Widget _buildLevelDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLevel,
      decoration: InputDecoration(
        labelText: 'Level *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: const [
        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
        DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedLevel = value!;
        });
      },
    );
  }

  Widget _buildPublishedSwitch() {
    return Row(
      children: [
        const Text(
          'Published',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Switch(
          value: _published,
          onChanged: (value) {
            setState(() {
              _published = value;
            });
          },
          activeColor: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category['_id']?.toString() ?? category['id']?.toString(),
          child: Text(category['name'] ?? 'Unknown Category'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
          _selectedSubcategoryId = null;
          _subcategories = [];
          if (value != null) {
            _loadSubcategories(value);
          }
        });
      },
    );
  }

  Widget _buildSubcategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSubcategoryId,
      decoration: InputDecoration(
        labelText: 'Subcategory *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _subcategories.map((subcategory) {
        return DropdownMenuItem(
          value: subcategory['_id']?.toString() ?? subcategory['id']?.toString(),
          child: Text(subcategory['name'] ?? 'Unknown Subcategory'),
        );
      }).toList(),
      onChanged: _selectedCategoryId == null ? null : (value) {
        setState(() {
          _selectedSubcategoryId = value;
        });
      },
    );
  }

  Widget _buildInstructorDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedInstructorId,
      decoration: InputDecoration(
        labelText: 'Instructor *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _instructors.map((instructor) {
        return DropdownMenuItem(
          value: instructor['_id']?.toString() ?? instructor['id']?.toString(),
          child: Text(instructor['name'] ?? 'Unknown Instructor'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedInstructorId = value;
        });
      },
    );
  }

  Widget _buildSectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Course Sections',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addNewSection,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Section'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_sections.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No sections added yet. Click "Add Section" to create your first section.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            return _buildSectionCard(section, index);
          }),
      ],
    );
  }

  Widget _buildSectionCard(CourseSectionData section, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Section ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeSection(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: section.titleController,
              decoration: const InputDecoration(
                labelText: 'Section Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: section.descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Section Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Videos:', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _pickSectionVideo(index),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...section.videos.asMap().entries.map((videoEntry) {
              final videoIndex = videoEntry.key;
              final video = videoEntry.value;
              return _buildVideoItem(video, index, videoIndex);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoItem(CourseVideoData video, int sectionIndex, int videoIndex) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.videocam, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  video.file?.path.split('/').last ?? 
                  (video.uploadedUrl != null ? 'Existing Video' : 'No video selected'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: () => _removeVideo(sectionIndex, videoIndex),
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: video.titleController,
            decoration: const InputDecoration(
              labelText: 'Video Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: video.descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Video Description',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: video.durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: video.orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Order',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          // Removed isFreePreview field as per requirement
        ],
      ),
    );
  }

  Future<void> _pickSectionVideo(int sectionIndex) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );
      
      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        // Upload video immediately using single video API
        Map<String, dynamic> uploadResult;
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          uploadResult = await ApiService.uploadCourseVideo(result.files.first.name, videoBytes: bytes);
        } else {
          uploadResult = await ApiService.uploadCourseVideo(result.files.first.path!);
        }

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // Extract URL from API response - handle different response formats
          String? videoUrl;
          final data = uploadResult['data'];
          
          if (data is String) {
            // If data is direct URL string
            videoUrl = data;
          } else if (data is Map && data['url'] != null) {
            // If data is object with url field
            videoUrl = data['url'].toString();
          } else if (data is Map && data['video'] != null && data['video']['url'] != null) {
            // If nested structure
            videoUrl = data['video']['url'].toString();
          }
          
          // Add video with uploaded URL to section
          setState(() {
            _sections[sectionIndex].videos.add(CourseVideoData(
              file: kIsWeb ? File(result.files.first.name) : File(result.files.first.path!),
              bytes: kIsWeb ? result.files.first.bytes : null,
              titleController: TextEditingController(),
              descriptionController: TextEditingController(),
              durationController: TextEditingController(text: '0'), // Default duration
              orderController: TextEditingController(text: '${_sections[sectionIndex].videos.length + 1}'), // Auto order
              uploadedUrl: videoUrl ?? '', // Store uploaded URL in format like "/uploads/courses/video.mp4"
            ));
            _isUploading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Section video uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload section video: ${uploadResult['message']}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _removeVideo(int sectionIndex, int videoIndex) {
    setState(() {
      _sections[sectionIndex].videos.removeAt(videoIndex);
    });
  }

  void _addNewSection() {
    setState(() {
      _sections.add(CourseSectionData(
        titleController: TextEditingController(),
        descriptionController: TextEditingController(),
        videos: [],
      ));
    });
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        // Prepare sections data
        List<Map<String, dynamic>> sectionsData = [];
        
        for (int i = 0; i < _sections.length; i++) {
          final section = _sections[i];
          
          String sectionTitle = section.titleController.text.trim();
          if (sectionTitle.isEmpty) {
            sectionTitle = 'Section ${i + 1}';
          }
          
          List<Map<String, dynamic>> videosData = [];
          
          for (int j = 0; j < section.videos.length; j++) {
            final video = section.videos[j];
            String videoTitle = video.titleController.text.trim();
            if (videoTitle.isEmpty) {
              videoTitle = 'Video ${j + 1}';
            }
            
            videosData.add({
              'title': videoTitle,
              'description': video.descriptionController.text.trim().isEmpty 
                  ? 'Video description' 
                  : video.descriptionController.text.trim(),
              'url': video.uploadedUrl ?? '', // Use uploaded URL
              'durationSeconds': int.tryParse(video.durationController.text) ?? 0,
              'order': int.tryParse(video.orderController.text) ?? (j + 1),
            });
          }
          
          sectionsData.add({
            'title': sectionTitle,
            'description': section.descriptionController.text.trim().isEmpty 
                ? 'Section description' 
                : section.descriptionController.text.trim(),
            'videos': videosData,
          });
        }
        
        // Don't add default empty section - let user create sections manually

        // Create or update course
        final courseResult = isEditing 
          ? await ApiService.updateCourse(
              courseId: widget.course!.id,
              category: _selectedCategoryId ?? '',
              subcategory: _selectedSubcategoryId ?? '',
              title: _titleController.text,
              description: _descriptionController.text,
              price: _priceController.text.isEmpty ? '0' : _priceController.text,
              level: _selectedLevel,
              published: _published ? 1 : 0,
              instructor: _selectedInstructorId ?? '',
              thumbnail: _uploadedThumbnailUrl ?? '',
              introVideo: _uploadedIntroVideoUrl != null ? {
                'title': _introVideoTitleController.text.trim().isEmpty 
                    ? 'Course Overview' 
                    : _introVideoTitleController.text.trim(),
                'description': _introVideoDescriptionController.text.trim().isEmpty 
                    ? 'What you\'ll learn in this course' 
                    : _introVideoDescriptionController.text.trim(),
                'url': _uploadedIntroVideoUrl,
                'durationSeconds': int.tryParse(_introVideoDurationController.text) ?? 180,
                'thumbnail': _uploadedThumbnailUrl ?? '',
              } : null,
              sections: sectionsData,
            )
          : await ApiService.createCourse(
              category: _selectedCategoryId ?? '',
              subcategory: _selectedSubcategoryId ?? '',
              title: _titleController.text,
              description: _descriptionController.text,
              price: _priceController.text.isEmpty ? '0' : _priceController.text,
              level: _selectedLevel,
              published: _published ? 1 : 0,
              instructor: _selectedInstructorId ?? '',
              thumbnail: _uploadedThumbnailUrl ?? '',
              introVideo: _uploadedIntroVideoUrl != null ? {
                'title': _introVideoTitleController.text.trim().isEmpty 
                    ? 'Course Overview' 
                    : _introVideoTitleController.text.trim(),
                'description': _introVideoDescriptionController.text.trim().isEmpty 
                    ? 'What you\'ll learn in this course' 
                    : _introVideoDescriptionController.text.trim(),
                'url': _uploadedIntroVideoUrl,
                'durationSeconds': int.tryParse(_introVideoDurationController.text) ?? 180,
                'thumbnail': _uploadedThumbnailUrl ?? '',
              } : null,
              sections: sectionsData,
            );

        setState(() {
          _isCreating = false;
        });

        if (courseResult['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Course updated successfully' : 'Course created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save course: ${courseResult['message']}')),
          );
        }
      } catch (e) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Helper function to get full URL
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // Already a full URL
    }
    return '${ApiService.baseUrl}$url'; // Add baseUrl for relative paths
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _introVideoTitleController.dispose();
    _introVideoDescriptionController.dispose();
    _introVideoDurationController.dispose();
    super.dispose();
  }
}

class CourseSectionData {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<CourseVideoData> videos;

  CourseSectionData({
    required this.titleController,
    required this.descriptionController,
    required this.videos,
  });
}

class CourseVideoData {
  final File? file;
  final Uint8List? bytes;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  final TextEditingController orderController;
  final String? uploadedUrl; // Store the uploaded video URL

  CourseVideoData({
    this.file,
    this.bytes,
    required this.titleController,
    required this.descriptionController,
    required this.durationController,
    required this.orderController,
    this.uploadedUrl,
  });
}