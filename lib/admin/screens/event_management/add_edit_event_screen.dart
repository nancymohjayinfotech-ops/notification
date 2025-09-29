import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/event.dart';
import '../../services/api_service.dart';

class AddEditEventScreen extends StatefulWidget {
  final Event? event;
  final Function(Event) onSave;

  const AddEditEventScreen({super.key, this.event, required this.onSave});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  EventMode _selectedMode = EventMode.offline;
  EventCategory _selectedCategory = EventCategory.workshop;

  // File uploads
  final List<File> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
  final List<File> _selectedVideos = [];
  final List<String> _uploadedImageUrls = []; // Store uploaded image URLs
  final List<String> _uploadedVideoUrls = []; // Store uploaded video URLs
  bool _isUploading = false;
  bool _isCreating = false;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _venueController.text = event.venue;
    _maxAttendeesController.text = event.maxAttendees.toString();
    _priceController.text = event.price?.toString() ?? '';
    _contactEmailController.text = event.contactEmail ?? '';
    _contactPhoneController.text = event.contactPhone ?? '';
    _meetingLinkController.text = event.meetingLink ?? '';
    _tagsController.text = event.tags.join(', ');
    _selectedStartDate = event.dateTime;
    _selectedEndDate = event.dateTime.add(const Duration(days: 1));
    _selectedStartTime = TimeOfDay.fromDateTime(event.dateTime);
    _selectedEndTime = TimeOfDay.fromDateTime(
      event.dateTime.add(const Duration(hours: 2)),
    );
    _selectedMode = event.mode;
    _selectedCategory = event.category;
  }

  Widget _buildResponsiveRow(
    BuildContext context, {
    required List<Widget> children,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    // For small screens (< 600px), stack fields vertically
    if (screenWidth < 600) {
      return Column(
        children: children
            .map(
              (child) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: child,
              ),
            )
            .toList(),
      );
    }

    // For larger screens, display fields in a row
    List<Widget> rowChildren = [];
    for (int i = 0; i < children.length; i++) {
      rowChildren.add(Expanded(child: children[i]));
      if (i < children.length - 1) {
        rowChildren.add(const SizedBox(width: 16));
      }
    }

    return Row(children: rowChildren);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create Event'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_isCreating || _isUploading) ? null : _saveEvent,
            child: (_isCreating || _isUploading)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_isUploading ? 'UPLOADING...' : 'CREATING...'),
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
              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.info_outline),
              const SizedBox(height: 16),
              _buildCard([
                _buildTextField(
                  controller: _titleController,
                  label: 'Event Title',
                  hint: 'Enter event title',
                  icon: Icons.title,
                  validator: null, // Made optional
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter event description',
                  icon: Icons.description,
                  maxLines: 3,
                  validator: null, // Made optional
                ),
                const SizedBox(height: 16),
                _buildResponsiveRow(
                  context,
                  children: [
                    _buildDropdown<EventCategory>(
                      label: 'Category',
                      value: _selectedCategory,
                      items: EventCategory.values,
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                      itemBuilder: (category) => Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(category.displayName),
                        ],
                      ),
                    ),
                    _buildDropdown<EventMode>(
                      label: 'Mode',
                      value: _selectedMode,
                      items: EventMode.values,
                      onChanged: (value) =>
                          setState(() => _selectedMode = value!),
                      itemBuilder: (mode) => Row(
                        children: [
                          Icon(mode.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(mode.displayName),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),

              // Date, Time & Venue Section
              _buildSectionHeader('Date, Time & Venue', Icons.schedule),
              const SizedBox(height: 16),
              _buildCard([
                _buildDateTimePicker(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _venueController,
                  label: 'Venue',
                  hint: _selectedMode == EventMode.online
                      ? 'Online Platform'
                      : 'Enter venue address',
                  icon: _selectedMode == EventMode.online
                      ? Icons.computer
                      : Icons.location_on,
                  validator: null, // Made optional
                ),
              ]),
              const SizedBox(height: 24),

              // Capacity & Pricing Section
              _buildSectionHeader('Capacity & Pricing', Icons.people),
              const SizedBox(height: 16),
              _buildCard([
                const SizedBox(height: 16),
                _buildResponsiveRow(
                  context,
                  children: [
                    _buildTextField(
                      controller: _maxAttendeesController,
                      label: 'Max Attendees',
                      hint: 'Enter maximum attendees',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true)
                          return null; // Made optional
                        final number = int.tryParse(value!);
                        if (number == null || number <= 0)
                          return 'Enter a valid number';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      hint: 'Enter price',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true)
                          return null; // Made optional
                        final number = double.tryParse(value!);
                        if (number == null || number < 0)
                          return 'Enter a valid price';
                        return null;
                      },
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information', Icons.contact_mail),
              const SizedBox(height: 16),
              _buildCard([
                _buildTextField(
                  controller: _contactEmailController,
                  label: 'Contact Email',
                  hint: 'Enter contact email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactPhoneController,
                  label: 'Contact Phone',
                  hint: 'Enter contact phone number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ]),
              const SizedBox(height: 24),

              // Additional Details Section
              _buildSectionHeader('Additional Details', Icons.more_horiz),
              const SizedBox(height: 16),
              _buildCard([
                _buildTextField(
                  controller: _tagsController,
                  label: 'Tags',
                  hint: 'Enter tags separated by commas',
                  icon: Icons.tag,
                ),
                const SizedBox(height: 16),
                // _buildResourcesSection(),
                // const SizedBox(height: 16),
                // _buildImageUrlField(),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Media Files', Icons.attach_file),
              const SizedBox(height: 16),
              _buildCard([_buildFileUploadSection()]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF9C27B0).withOpacity(0.18)
                : const Color(0xFF9C27B0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF9C27B0), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
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
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.black : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF9C27B0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
              style: TextStyle(color: isDark ? Colors.black : Colors.white),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: itemBuilder(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Date & Time Section
        Text(
          'Start Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectStartDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedStartDate != null && _selectedStartTime != null
                        ? '${DateFormat('MMM dd, yyyy').format(_selectedStartDate!)} at ${_selectedStartTime!.format(context)}'
                        : 'Select start date and time',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedStartDate != null
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white38 : Colors.grey[600]),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // End Date & Time Section
        Text(
          'End Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectEndDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Color(0xFFF44336)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedEndDate != null && _selectedEndTime != null
                        ? '${DateFormat('MMM dd, yyyy').format(_selectedEndDate!)} at ${_selectedEndTime!.format(context)}'
                        : 'Select end date and time',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedEndDate != null
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white38 : Colors.grey[600]),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images Section
        Row(
          children: [
            Text(
              'Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb && index < _selectedImageBytes.length
                          ? Image.memory(
                              _selectedImageBytes[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              file,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            // Remove from display list
                            _selectedImages.removeAt(index);

                            // Remove from uploaded URLs list (this is what gets sent to backend)
                            if (index < _uploadedImageUrls.length) {
                              _uploadedImageUrls.removeAt(index);
                            }

                            // Remove from bytes list for web if it exists
                            if (kIsWeb && index < _selectedImageBytes.length) {
                              _selectedImageBytes.removeAt(index);
                            }
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
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No images selected',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Videos Section
        Row(
          children: [
            Text(
              'Videos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickVideos,
              icon: const Icon(Icons.video_call, size: 18),
              label: const Text('Add Videos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedVideos.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedVideos.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.videocam,
                        size: 32,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            // Remove from display list
                            _selectedVideos.removeAt(index);

                            // Remove from uploaded URLs list (this is what gets sent to backend)
                            if (index < _uploadedVideoUrls.length) {
                              _uploadedVideoUrls.removeAt(index);
                            }
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
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Text(
                        file.path.split('/').last,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No videos selected',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  // Widget _buildResourcesSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           const Text(
  //             'Resources',
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.black87,
  //             ),
  //           ),
  //           const Spacer(),
  //           TextButton.icon(
  //             onPressed: _addResource,
  //             icon: const Icon(Icons.add, size: 16),
  //             label: const Text('Add Resource'),
  //             style: TextButton.styleFrom(
  //               foregroundColor: const Color(0xFF9C27B0),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: Colors.grey[50],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: Colors.grey[300]!),
  //         ),
  //         child: _resources.isEmpty
  //             ? Text(
  //                 'No resources added',
  //                 style: TextStyle(color: Colors.grey[600]),
  //               )
  //             : Wrap(
  //                 spacing: 8,
  //                 runSpacing: 8,
  //                 children: _resources.map((resource) => Chip(
  //                       label: Text(resource),
  //                       onDeleted: () => _removeResource(resource),
  //                       backgroundColor: const Color(0xFF9C27B0).withOpacity(0.1),
  //                       labelStyle: const TextStyle(color: Color(0xFF9C27B0)),
  //                       deleteIconColor: const Color(0xFF9C27B0),
  //                     )).toList(),
  //               ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildImageUrlField() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Event Image URL',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w500,
  //           color: Colors.black87,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       TextFormField(
  //         initialValue: _imageUrl,
  //         onChanged: (value) => _imageUrl = value.isEmpty ? null : value,
  //         decoration: InputDecoration(
  //           hintText: 'Enter image URL (optional)',
  //           prefixIcon: const Icon(Icons.image, color: Color(0xFF9C27B0)),
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: BorderSide(color: Colors.grey[300]!),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
  //           ),
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: BorderSide(color: Colors.grey[300]!),
  //           ),
  //           filled: true,
  //           fillColor: Colors.grey[50],
  //         ),
  //       ),
  //       if (_imageUrl?.isNotEmpty == true) ...[
  //         const SizedBox(height: 12),
  //         Container(
  //           height: 120,
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.grey[300]!),
  //           ),
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(8),
  //             child: Image.network(
  //               _imageUrl!,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) => Container(
  //                 color: Colors.grey[100],
  //                 child: const Icon(Icons.broken_image, color: Colors.grey),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ],
  //   );
  // }

  Future<void> _selectStartDate() async {
    // Select start date
    final startDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedStartDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Start Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (startDate != null) {
      // Select start time
      final startTime = await showTimePicker(
        context: context,
        initialTime: _selectedStartTime ?? TimeOfDay.now(),
        helpText: 'Select Start Time',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4CAF50),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (startTime != null) {
        setState(() {
          _selectedStartDate = startDate;
          _selectedStartTime = startTime;
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    // Select end date
    final endDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ??
          (_selectedStartDate?.add(const Duration(days: 1)) ??
              DateTime.now().add(const Duration(days: 2))),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select End Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF44336),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (endDate != null) {
      // Select end time
      final endTime = await showTimePicker(
        context: context,
        initialTime:
            _selectedEndTime ??
            TimeOfDay.fromDateTime(
              DateTime.now().add(const Duration(hours: 2)),
            ),
        helpText: 'Select End Time',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFF44336),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (endTime != null) {
        setState(() {
          _selectedEndDate = endDate;
          _selectedEndTime = endTime;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85, // Reduce quality for better performance
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (images.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });

        // Upload all images at once using multiple upload API
        Map<String, dynamic> uploadResult;

        if (kIsWeb) {
          // For web, read all images as bytes and upload together
          List<Uint8List> imageBytesList = [];
          for (XFile image in images) {
            final bytes = await image.readAsBytes();
            imageBytesList.add(bytes);
          }
          uploadResult = await ApiService.uploadEventImages(
            [],
            imageBytes: imageBytesList,
          );
        } else {
          // For mobile, upload all file paths together
          List<String> imagePaths = images.map((image) => image.path).toList();
          print('Mobile: Uploading ${imagePaths.length} images: $imagePaths');
          uploadResult = await ApiService.uploadEventImages(imagePaths);
          print('Mobile: Upload result: $uploadResult');
        }

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // Extract URLs from the response format: {"data": {"images": [{"url": "..."}, ...]}}
          final data = uploadResult['data'];
          List<String> uploadedUrls = [];

          if (data['images'] != null && data['images'] is List) {
            for (var imageData in data['images']) {
              if (imageData['url'] != null) {
                uploadedUrls.add(imageData['url'].toString());
              }
            }
          }

          // Only update state if we have successfully uploaded images
          if (uploadedUrls.isNotEmpty) {
            _uploadedImageUrls.addAll(uploadedUrls);

            // Keep files for display purposes
            if (kIsWeb) {
              List<Uint8List> imageBytesList = [];
              for (XFile image in images) {
                final bytes = await image.readAsBytes();
                imageBytesList.add(bytes);
              }
              _selectedImageBytes.addAll(imageBytesList);
              _selectedImages.addAll(
                images.map((image) => File(image.name)).toList(),
              );
            } else {
              _selectedImages.addAll(
                images.map((image) => File(image.path)).toList(),
              );
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully uploaded ${uploadedUrls.length} images',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('Image upload failed: ${uploadResult['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload images: ${uploadResult['message']}',
              ),
            ),
          );
        }

        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
    }
  }

  Future<void> _pickVideos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        // Upload all videos at once using multiple upload API
        Map<String, dynamic> uploadResult;

        if (kIsWeb) {
          // For web, we'll need to upload one by one since uploadEventVideos doesn't support bytes
          List<String> uploadedUrls = [];
          List<File> selectedVideoFiles = [];

          for (var file in result.files) {
            try {
              final singleUploadResult = await ApiService.uploadEventVideo(
                file.name,
                videoBytes: file.bytes,
              );

              if (singleUploadResult['success'] == true &&
                  singleUploadResult['data'] != null) {
                final data = singleUploadResult['data'];
                if (data['videos'] != null &&
                    data['videos'] is List &&
                    data['videos'].isNotEmpty) {
                  final videoData = data['videos'][0];
                  if (videoData['url'] != null) {
                    uploadedUrls.add(videoData['url'].toString());
                    selectedVideoFiles.add(File(file.name));
                  }
                }
              }
            } catch (e) {
              print('Error uploading video: $e');
            }
          }

          // Only add to state if we have successfully uploaded videos
          if (uploadedUrls.isNotEmpty) {
            _uploadedVideoUrls.addAll(uploadedUrls);
            _selectedVideos.addAll(selectedVideoFiles);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully uploaded ${uploadedUrls.length} videos',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // For mobile, upload all video paths together
          List<String> videoPaths = result.paths
              .where((path) => path != null)
              .cast<String>()
              .toList();
          uploadResult = await ApiService.uploadEventVideos(videoPaths);

          if (uploadResult['success'] == true && uploadResult['data'] != null) {
            // Extract URLs from the response format: {"data": {"videos": [{"url": "..."}, ...]}}
            final data = uploadResult['data'];
            List<String> uploadedUrls = [];

            if (data['videos'] != null && data['videos'] is List) {
              for (var videoData in data['videos']) {
                if (videoData['url'] != null) {
                  uploadedUrls.add(videoData['url'].toString());
                }
              }
            }

            // Only update state if we have successfully uploaded videos
            if (uploadedUrls.isNotEmpty) {
              _uploadedVideoUrls.addAll(uploadedUrls);
              _selectedVideos.addAll(
                result.paths.map((path) => File(path!)).toList(),
              );
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully uploaded ${uploadedUrls.length} videos',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to upload videos: ${uploadResult['message']}',
                ),
              ),
            );
          }
        }

        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking videos: $e')));
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStartDate == null ||
          _selectedEndDate == null ||
          _selectedStartTime == null ||
          _selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select start and end dates with times'),
          ),
        );
        return;
      }

      setState(() {
        _isCreating = true;
      });

      try {
        // Use already uploaded URLs from when user selected files
        List<String> uploadedImageUrls = _uploadedImageUrls;
        List<String> uploadedVideoUrls = _uploadedVideoUrls;

        // Create or update event
        final tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        final Map<String, dynamic> eventResult;

        if (isEditing) {
          // Update existing event
          eventResult = await ApiService.updateEvent(
            eventId: widget.event!.id,
            title: _titleController.text.isEmpty
                ? 'Untitled Event'
                : _titleController.text,
            description: _descriptionController.text.isEmpty
                ? 'No description provided'
                : _descriptionController.text,
            location: _venueController.text.isEmpty
                ? 'TBD'
                : _venueController.text,
            category: _selectedCategory.name,
            eventType: _selectedMode.name,
            startDate: DateFormat('yyyy-MM-dd').format(_selectedStartDate!),
            endDate: DateFormat('yyyy-MM-dd').format(_selectedEndDate!),
            registrationDeadline: DateFormat(
              'yyyy-MM-dd',
            ).format(_selectedStartDate!.subtract(const Duration(days: 1))),
            maxParticipants: _maxAttendeesController.text.isEmpty
                ? 0
                : int.parse(_maxAttendeesController.text),
            tags: tags,
            startTime:
                '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}',
            endTime:
                '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}',
            contactEmail: _contactEmailController.text.isEmpty
                ? null
                : _contactEmailController.text,
            contactPhone: _contactPhoneController.text.isEmpty
                ? null
                : _contactPhoneController.text,
            price: _priceController.text.isEmpty
                ? null
                : double.tryParse(_priceController.text),
            images: uploadedImageUrls.isNotEmpty ? uploadedImageUrls : null,
            videos: uploadedVideoUrls.isNotEmpty ? uploadedVideoUrls : null,
          );
        } else {
          // Create new event
          eventResult = await ApiService.createEvent(
            title: _titleController.text.isEmpty
                ? 'Untitled Event'
                : _titleController.text,
            description: _descriptionController.text.isEmpty
                ? 'No description provided'
                : _descriptionController.text,
            location: _venueController.text.isEmpty
                ? 'TBD'
                : _venueController.text,
            category: _selectedCategory.name,
            eventType: _selectedMode.name,
            startDate: DateFormat('yyyy-MM-dd').format(_selectedStartDate!),
            endDate: DateFormat('yyyy-MM-dd').format(_selectedEndDate!),
            registrationDeadline: DateFormat(
              'yyyy-MM-dd',
            ).format(_selectedStartDate!.subtract(const Duration(days: 1))),
            maxParticipants: _maxAttendeesController.text.isEmpty
                ? 0
                : int.parse(_maxAttendeesController.text),
            tags: tags,
            startTime:
                '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}',
            endTime:
                '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}',
            contactEmail: _contactEmailController.text.isEmpty
                ? null
                : _contactEmailController.text,
            contactPhone: _contactPhoneController.text.isEmpty
                ? null
                : _contactPhoneController.text,
            price: _priceController.text.isEmpty
                ? null
                : double.tryParse(_priceController.text),
            images: uploadedImageUrls.isNotEmpty ? uploadedImageUrls : null,
            videos: uploadedVideoUrls.isNotEmpty ? uploadedVideoUrls : null,
          );
        }

        setState(() {
          _isCreating = false;
        });

        if (eventResult['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Event updated successfully'
                    : 'Event created successfully',
              ),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create event: ${eventResult['message']}',
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isCreating = false;
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _maxAttendeesController.dispose();
    _priceController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _meetingLinkController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
