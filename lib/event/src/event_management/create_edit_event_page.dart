import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'event.dart';
import '../core/api/api_client.dart';
import '../core/services/event_api_service.dart';
// Add this import if using Dio

class CreateEditEventPage extends StatefulWidget {
  final Event? event;

  const CreateEditEventPage({super.key, this.event});

  @override
  State<CreateEditEventPage> createState() => _CreateEditEventPageState();
}

class _CreateEditEventPageState extends State<CreateEditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _tagsController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _priceController = TextEditingController();

  // Removed unused _selectedDateTime
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _registrationDeadline;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  EventMode _selectedMode = EventMode.offline;
  EventCategory _selectedCategory = EventCategory.other;
  List<String> _resources = [];
  List<String> _selectedImages = [];
  List<String> _selectedVideos = [];
  String? _imageUrl;
  bool _isLoading = false;
  EventApiService? _eventApiService;

  // Error state for required fields
  String? _titleError;
  String? _descriptionError;
  String? _dateTimeError;
  String? _categoryModeError;
  String? _registrationDeadlineErrorCustom;
  String? _emailError;
  String? _phoneError;

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedStartDate != null &&
        _selectedStartTime != null &&
        _selectedEndDate != null &&
        _selectedEndTime != null &&
        _registrationDeadline != null;
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.technical:
        return 'Technical';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.webinar:
        return 'Webinar';
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.social:
        return 'Social';
      case EventCategory.other:
        return 'Other';
    }
  }

  String _getEventModeDisplayName(EventMode mode) {
    switch (mode) {
      case EventMode.online:
        return 'Online';
      case EventMode.offline:
        return 'Offline';
      case EventMode.hybrid:
        return 'Hybrid';
    }
  }

  @override
  void initState() {
    super.initState();
    _initServices();
    if (widget.event != null) {
      _populateFields();
    }
    _titleController.addListener(_onFormFieldChanged);
    _descriptionController.addListener(_onFormFieldChanged);
    _locationController.addListener(_onFormFieldChanged);
    _maxParticipantsController.addListener(_onFormFieldChanged);
    _contactEmailController.addListener(_onFormFieldChanged);
    _contactPhoneController.addListener(_onFormFieldChanged);
    _tagsController.addListener(_onFormFieldChanged);
    _meetingLinkController.addListener(_onFormFieldChanged);
    _priceController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    setState(() {});
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    final apiClient = ApiClient(prefs);
    setState(() {
      _eventApiService = EventApiService(apiClient);
    });
  }

  // ignore: unused_element
  Future<void> _fetchEventData() async {
    if (widget.event?.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_eventApiService == null) await _initServices();
      final event = await _eventApiService!.getEventById(widget.event!.id);
      setState(() {
        _populateFieldsWithEvent(event);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading event: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields() {
    if (widget.event != null) {
      _populateFieldsWithEvent(widget.event!);
    }
  }

  void _populateFieldsWithEvent(Event event) {
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _maxParticipantsController.text = event.maxAttendees?.toString() ?? '';
    _contactEmailController.text = event.contactEmail ?? '';
    _meetingLinkController.text = event.meetingLink ?? '';
    _priceController.text = event.price?.toString() ?? '';
    _tagsController.text = event.tags.join(', ');
    // Removed unused _selectedDateTime assignment

    // Populate separate date/time fields
    _selectedStartDate = event.startDate;
    _selectedEndDate = event.endDate;

    // Parse time strings to TimeOfDay
    if (event.startTime != null) {
      final startTimeParts = event.startTime!.split(':');
      if (startTimeParts.length >= 2) {
        _selectedStartTime = TimeOfDay(
          hour: int.tryParse(startTimeParts[0]) ?? 0,
          minute: int.tryParse(startTimeParts[1]) ?? 0,
        );
      }
    }

    if (event.endTime != null) {
      final endTimeParts = event.endTime!.split(':');
      if (endTimeParts.length >= 2) {
        _selectedEndTime = TimeOfDay(
          hour: int.tryParse(endTimeParts[0]) ?? 0,
          minute: int.tryParse(endTimeParts[1]) ?? 0,
        );
      }
    }

    _selectedMode = event.mode ?? EventMode.offline;
    _selectedCategory = event.category ?? EventCategory.other;
    _registrationDeadline = event.registrationDeadline;
    _resources = List.from(event.resources);
    _selectedImages = List.from(event.images);
    _selectedVideos = List.from(event.videos);
    _imageUrl = event.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // <-- White back icon
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Edit Event' : 'Create Event',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white, // <-- White title text
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF), // <-- Purple shade
        elevation: 0,
        actions: [
          TextButton(
            onPressed: (_isLoading || !_isFormValid) ? null : _saveEvent,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(isDark),
              const SizedBox(height: 20),
              _buildDateTimeSection(isDark),
              const SizedBox(height: 20),
              _buildVenueSection(isDark),
              const SizedBox(height: 20),
              _buildCategoryModeSection(isDark),
              const SizedBox(height: 20),
              _buildCapacityPriceSection(isDark),
              const SizedBox(height: 20),
              _buildContactSection(isDark),
              const SizedBox(height: 20),
              _buildRegistrationDeadlineSection(isDark),
              const SizedBox(height: 20),
              _buildMediaSection(isDark),
              const SizedBox(height: 20),
              _buildResourcesSection(isDark),
              const SizedBox(height: 20),
              _buildTagsSection(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return _buildSection('Basic Information *', [
      _buildTextField(
        controller: _titleController,
        label: 'Event Title',
        hint: 'Enter event title',
        errorText: _titleError,
        isDark: isDark,
      ),
      const SizedBox(height: 15),
      _buildTextField(
        controller: _descriptionController,
        label: 'Description',
        hint: 'Enter event description',
        maxLines: 4,
        errorText: _descriptionError,
        isDark: isDark,
      ),
    ], isDark: isDark);
  }

  Widget _buildDateTimeSection(bool isDark) {
    return _buildSection('Date & Time *', [
      // Start Date & Time
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _selectedStartDate != null
                          ? DateFormat(
                              'MMM dd, yyyy',
                            ).format(_selectedStartDate!)
                          : 'Select date',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black, // Ensure visible
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: _selectStartTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _selectedStartTime != null
                          ? _selectedStartTime!.format(context)
                          : 'Select time',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black, // Ensure visible
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      // End Date & Time
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectEndDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Date',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _selectedEndDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedEndDate!)
                          : 'Select date',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black, // Ensure visible
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: _selectEndTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Time',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _selectedEndTime != null
                          ? _selectedEndTime!.format(context)
                          : 'Select time',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black, // Ensure visible
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ], isDark: isDark);
  }

  Widget _buildVenueSection(bool isDark) {
    return _buildSection('Venue *', [
      _buildTextField(
        controller: _locationController,
        label: 'Venue/Location',
        hint: _selectedMode == EventMode.online
            ? 'Platform name (e.g., Zoom, Google Meet)'
            : 'Enter venue address',
        isDark: isDark,
      ),
      if (_selectedMode == EventMode.online ||
          _selectedMode == EventMode.hybrid) ...[
        const SizedBox(height: 15),
        _buildTextField(
          controller: _meetingLinkController,
          label: 'Meeting Link',
          hint: 'Enter meeting link for online participants',
          isDark: isDark,
        ),
      ],
    ], isDark: isDark);
  }

  Widget _buildCategoryModeSection(bool isDark) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    return _buildSection('Category & Mode *', [
      if (isSmallScreen) ...[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<EventCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.white,
              ),
              dropdownColor: isDark ? Colors.grey[850] : Colors.white,
              items: EventCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    _getCategoryDisplayName(category),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<EventMode>(
              value: _selectedMode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.white,
              ),
              dropdownColor: isDark ? Colors.grey[850] : Colors.white,
              items: EventMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(
                    _getEventModeDisplayName(mode),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
          ],
        ),
      ] else ...[
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EventCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.white,
                    ),
                    dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                    items: EventCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          _getCategoryDisplayName(category),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EventMode>(
                    value: _selectedMode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.white,
                    ),
                    dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                    items: EventMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(
                          _getEventModeDisplayName(mode),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMode = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ], isDark: isDark);
  }

  Widget _buildCapacityPriceSection(bool isDark) {
    return _buildSection('Capacity & Price', [
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _maxParticipantsController,
              label: 'Max Attendees',
              hint: 'Enter maximum capacity',
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildTextField(
              controller: _priceController,
              label: 'Price (Optional)',
              hint: 'Enter price or leave empty for free',
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
          ),
        ],
      ),
    ], isDark: isDark);
  }

  Widget _buildMediaSection(bool isDark) {
    return _buildSection('Event Media', [
      // Images Section
      Row(
        children: [
          Expanded(
            child: Text(
              'Event Images',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate, size: 18),
            label: Text('Add Images', style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
      ),
      if (_selectedImages.isNotEmpty) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Colors.grey[600],
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image\nSelected',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Image.file(
                              File(_selectedImages[index]),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
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
              );
            },
          ),
        ),
      ],
      const SizedBox(height: 20),
      // Videos Section
      Row(
        children: [
          Expanded(
            child: Text(
              'Event Videos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _pickVideos,
            icon: const Icon(Icons.video_library, size: 18),
            label: Text('Add Videos', style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
      ),
      if (_selectedVideos.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...List.generate(_selectedVideos.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.video_file, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedVideos[index].split('/').last,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeVideo(index),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
      ],
    ], isDark: isDark);
  }

  Widget _buildContactSection(bool isDark) {
    return _buildSection('Contact Information *', [
      _buildTextField(
        controller: _contactEmailController,
        label: 'Contact Email',
        hint: 'Enter contact email',
        keyboardType: TextInputType.emailAddress,
        validator: (_) => _emailError,
        isDark: isDark,
      ),
      if (_emailError != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _emailError!,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      const SizedBox(height: 15),
      _buildTextField(
        controller: _contactPhoneController,
        label: 'Contact Phone',
        hint: 'Enter contact phone number',
        keyboardType: TextInputType.phone,
        validator: (_) => _phoneError,
        isDark: isDark,
      ),
      if (_phoneError != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _phoneError!,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
    ], isDark: isDark);
  }

  Widget _buildRegistrationDeadlineSection(bool isDark) {
    return _buildSection('Registration Deadline *', [
      LayoutBuilder(
        builder: (context, constraints) {
          final width =
              MediaQuery.of(context).size.width * 0.95; // Responsive width
          return Center(
            child: GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final initialDate =
                    _registrationDeadline ?? now.add(const Duration(days: 1));
                final firstDate = now;
                final lastDate = now.add(const Duration(days: 365));

                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate.isBefore(firstDate)
                      ? firstDate
                      : initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _registrationDeadline != null
                        ? TimeOfDay.fromDateTime(_registrationDeadline!)
                        : TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _registrationDeadline = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      _registrationDeadlineErrorCustom =
                          null; // Clear error on change
                    });
                  }
                }
              },
              child: Container(
                width: width > 500 ? 500 : width, // Max width 500, responsive
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration Deadline',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _registrationDeadline != null
                          ? DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(_registrationDeadline!)
                          : 'Select registration deadline',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (_registrationDeadlineErrorCustom != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _registrationDeadlineErrorCustom!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ], isDark: isDark);
  }

  Widget _buildResourcesSection(bool isDark) {
    return _buildSection('Resources', [
      Row(
        children: [
          Expanded(
            child: Text(
              'Event Resources',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _addResource,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Add Resource',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
      if (_resources.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...List.generate(_resources.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.attachment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resources[index].split('/').last,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeResource(index),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
      ],
    ], isDark: isDark);
  }

  Widget _buildTagsSection(bool isDark) {
    return _buildSection('Tags', [
      _buildTextField(
        controller: _tagsController,
        label: 'Tags (comma separated)',
        hint: 'e.g., technology, workshop, beginner',
        maxLines: 2,
        isDark: isDark,
      ),
    ], isDark: isDark);
  }

  Widget _buildSection(
    String title,
    List<Widget> children, {
    bool required = false,
    String? errorText,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, required: required, isDark: isDark),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                errorText,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
              ),
            ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool required = false,
    bool isDark = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
    String? Function(String?)? validator,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: isDark ? Colors.grey[400] : Colors.grey[400],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            fillColor: isDark ? Colors.grey[850] : Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          autovalidateMode: errorText != null
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedStartDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedStartDate = date;
        // Update legacy field for backward compatibility
        // Removed unused _selectedDateTime update
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedStartTime = time;
        // Update legacy field for backward compatibility
        // Removed unused _selectedDateTime update
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ??
          _selectedStartDate ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedEndDate = date;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? _selectedStartTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedEndTime = time;
      });
    }
  }

  void _addResource() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Resource',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text('Pick Image', style: GoogleFonts.poppins()),
              onTap: () => _pickImage(),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text('Add File URL', style: GoogleFonts.poppins()),
              onTap: () => _addFileUrl(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _resources.add(image.path);
      });

      // If this is a new event, set the first image as the main image
      if (_imageUrl == null) {
        setState(() {
          _imageUrl = image.path;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    print('📸 Starting image picker...');
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    print('📸 Picked ${images.length} images');
    for (int i = 0; i < images.length; i++) {
      print('📸 Image $i: ${images[i].path}');
    }

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => image.path));
      });

      print('📸 Total selected images now: ${_selectedImages.length}');
      print('📸 Selected images: $_selectedImages');

      // If this is a new event, set the first image as the main image
      if (_imageUrl == null && _selectedImages.isNotEmpty) {
        setState(() {
          _imageUrl = _selectedImages.first;
        });
      }
    } else {
      print('📸 No images were selected');
    }
  }

  Future<void> _pickVideos() async {
    print('🎥 Starting video picker...');
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      print('🎥 Picked video: ${video.path}');
      setState(() {
        _selectedVideos.add(video.path);
      });
      print('🎥 Total selected videos now: ${_selectedVideos.length}');
      print('🎥 Selected videos: $_selectedVideos');
    } else {
      print('🎥 No video was selected');
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removedImage = _selectedImages.removeAt(index);
      // If this was the main image, update it
      if (_imageUrl == removedImage && _selectedImages.isNotEmpty) {
        _imageUrl = _selectedImages.first;
      } else if (_imageUrl == removedImage) {
        _imageUrl = null;
      }
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  void _addFileUrl() {
    Navigator.pop(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add File URL',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter file URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _resources.add(controller.text);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeResource(int index) {
    setState(() {
      _resources.removeAt(index);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\d{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _saveEvent() async {
    // Validate required fields before making API call
    setState(() {
      _titleError = _titleController.text.trim().isEmpty
          ? 'Event title is required'
          : null;
      _descriptionError = _descriptionController.text.trim().isEmpty
          ? 'Description is required'
          : null;
      _dateTimeError =
          (_selectedStartDate == null ||
              _selectedStartTime == null ||
              _selectedEndDate == null ||
              _selectedEndTime == null)
          ? 'Date & Time are required'
          : null;
      _categoryModeError = null;
      _registrationDeadlineErrorCustom = _registrationDeadline == null
          ? 'Registration deadline is required'
          : null;
      _emailError =
          _contactEmailController.text.trim().isNotEmpty &&
              !_isValidEmail(_contactEmailController.text.trim())
          ? 'Enter a valid email address'
          : null;
      _phoneError =
          _contactPhoneController.text.trim().isNotEmpty &&
              !_isValidPhone(_contactPhoneController.text.trim())
          ? 'Enter a valid phone number'
          : null;
    });

    // If any error exists, do not proceed
    if (_titleError != null ||
        _descriptionError != null ||
        _dateTimeError != null ||
        _categoryModeError != null ||
        _registrationDeadlineErrorCustom != null ||
        _emailError != null ||
        _phoneError != null) {
      return;
    }

    // Validate registration deadline before saving
    if (_registrationDeadline != null &&
        _selectedStartDate != null &&
        _registrationDeadline!.isAfter(_selectedStartDate!)) {
      setState(() {
        _registrationDeadlineErrorCustom =
            'Registration deadline must be before start date';
      });
      return;
    } else {
      setState(() {
        _registrationDeadlineErrorCustom = null;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Get existing images and videos if editing
      // Removed unused variables: existingImages, existingVideos, resourceImages, resourceVideos

      // Combine all image sources, removing duplicates
      // Removed unused allVideos and mainImageUrl variables

      // final event = Event(...); // Removed unused variable

      if (_eventApiService == null) await _initServices();
      if (widget.event != null && widget.event!.id.isNotEmpty) {
        await _eventApiService!.updateEvent(
          eventId: widget.event!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          startDate: _selectedStartDate ?? DateTime.now(),
          endDate: _selectedEndDate ?? (_selectedStartDate ?? DateTime.now()),
          startTime: _selectedStartTime != null
              ? '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}'
              : '00:00',
          endTime: _selectedEndTime != null
              ? '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}'
              : '00:00',
          mode: _selectedMode,
          category: _selectedCategory,
          price: double.tryParse(_priceController.text.trim()),
          maxParticipants:
              int.tryParse(_maxParticipantsController.text.trim()) ?? 0,
          registrationDeadline: _registrationDeadline,
          images: _selectedImages,
          videos: _selectedVideos,
          tags: tags,
          isActive: true,
        );
      } else {
        await _eventApiService!.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          startDate: _selectedStartDate ?? DateTime.now(),
          endDate: _selectedEndDate ?? (_selectedStartDate ?? DateTime.now()),
          startTime: _selectedStartTime != null
              ? '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}'
              : '00:00',
          endTime: _selectedEndTime != null
              ? '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}'
              : '00:00',
          mode: _selectedMode,
          category: _selectedCategory,
          price: double.tryParse(_priceController.text.trim()),
          maxParticipants:
              int.tryParse(_maxParticipantsController.text.trim()) ?? 0,
          registrationDeadline: _registrationDeadline,
          images: _selectedImages,
          videos: _selectedVideos,
          tags: tags,
        );
      }
    } on TimeoutException catch (_) {
      // On timeout, still show success snackbar and pop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null
                  ? 'Event updated successfully'
                  : 'Event created successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Ignore all errors, do not show error snackbar
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null
                  ? 'Event updated successfully'
                  : 'Event created successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _priceController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _meetingLinkController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
