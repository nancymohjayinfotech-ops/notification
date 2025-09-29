import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'avatar_management.dart' as avatar;

class InstructorProfilePage extends StatefulWidget {
  final String instructorName;
  final String role;
  final String about; // Keeping this for widget initialization, will map to bio
  final List<String> courses;
  final List<String> certifications;
  final double rating;
  final Uint8List? avatarBytes;
  final String? avatarUrl;

  const InstructorProfilePage({
    super.key,
    required this.instructorName,
    required this.role,
    required this.about,
    required this.courses,
    required this.certifications,
    required this.rating,
    this.avatarBytes,
    this.avatarUrl,
  });

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  late String instructorName;
  late String role;
  late String bio; // Changed from about to bio
  late List<String> courses;
  late List<String> certifications;
  late double rating;
  Uint8List? avatarBytes;
  String? avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    instructorName = widget.instructorName;
    role = widget.role.isNotEmpty ? widget.role : "Not specified";
    bio = widget.about; // Map the initial about to bio
    courses = widget.courses;
    certifications = widget.certifications;
    rating = widget.rating;
    avatarBytes = widget.avatarBytes;
    avatarUrl = widget.avatarUrl;
    avatar.AvatarManagement().initialize(instructorName: instructorName);
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final data = await ApiService.getProfile();
      setState(() {
        instructorName = data['user']['name'] ?? widget.instructorName;
        role = data['user']['role']?.isNotEmpty == true
            ? data['user']['role']
            : widget.role.isNotEmpty
            ? widget.role
            : "Not specified";
        bio =
            data['user']['bio'] ??
            data['user']['about'] ??
            widget.about; // Use bio from API
        courses = List<String>.from(data['user']['courses'] ?? widget.courses);
        certifications = List<String>.from(
          data['user']['certifications'] ?? widget.certifications,
        );
        rating = (data['user']['rating'] ?? widget.rating).toDouble();
        avatarUrl = data['user']['avatar'] != null
            ? 'http://54.82.53.11:5001${data['user']['avatar']}'
            : widget.avatarUrl;
        avatarBytes = widget.avatarBytes;
        _isLoading = false;
        avatar.AvatarManagement().updateInstructorData(
          name: instructorName,
          avatarUrl: avatarUrl,
          avatarBytes: avatarBytes,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching profile: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInstructorProfilePage(
          name: instructorName,
          bio: bio,
          avatarBytes: avatarBytes,
          avatarUrl: avatarUrl,
        ),
      ),
    );

    if (updatedData != null) {
      setState(() {
        instructorName = updatedData["name"];
        bio = updatedData["bio"];
        avatarBytes = updatedData["avatarBytes"];
        avatarUrl = updatedData["avatarUrl"];
      });
      avatar.AvatarManagement().updateInstructorData(
        name: instructorName,
        avatarUrl: avatarUrl,
        avatarBytes: avatarBytes,
      );
      await _updateProfile();
      await _fetchProfileData();
    }
  }

  Future<void> _updateProfile() async {
    try {
      await ApiService.updateProfile({'name': instructorName, 'bio': bio});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  Widget _buildAvatar(double radius) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: avatar.AvatarManagement.avatarBytesNotifier,
      builder: (context, bytes, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: avatar.AvatarManagement.avatarUrlNotifier,
          builder: (context, url, _) {
            if (bytes != null) {
              return CircleAvatar(
                radius: radius,
                backgroundImage: MemoryImage(bytes),
              );
            } else if (url != null && url.isNotEmpty) {
              return CircleAvatar(
                radius: radius,
                backgroundImage: NetworkImage(url),
              );
            } else {
              return CircleAvatar(
                radius: radius,
                backgroundImage: const AssetImage(
                  "assets/images/developer.png",
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Instructor Profile"),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;

                if (screenWidth < 400) {
                  return _buildSingleColumn(
                    context,
                    screenWidth,
                    isSmall: true,
                  );
                } else if (screenWidth < 768) {
                  return _buildSingleColumn(context, screenWidth);
                } else if (screenWidth < 1092) {
                  return _buildSingleColumn(
                    context,
                    screenWidth,
                    isTablet: true,
                  );
                } else {
                  return _buildTwoColumn(context, screenWidth);
                }
              },
            ),
    );
  }

  Widget _buildSingleColumn(
    BuildContext context,
    double screenWidth, {
    bool isTablet = false,
    bool isSmall = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarRadius = isSmall
        ? 30.0
        : (screenWidth * 0.12).clamp(40.0, 70.0);
    final titleSize = isSmall
        ? 18.0
        : isTablet
        ? 24.0
        : 20.0;
    final textSize = isSmall
        ? 14.0
        : isTablet
        ? 18.0
        : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(avatarRadius),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable:
                          avatar.AvatarManagement.instructorNameNotifier,
                      builder: (context, name, _) {
                        return Text(
                          name.isNotEmpty ? name : instructorName,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    Text(
                      role.isNotEmpty ? role : "Not specified",
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, "About Me", textSize),
          Text(
            bio.isNotEmpty ? bio : "Not specified",
            style: TextStyle(
              fontSize: textSize,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, "Assigned Courses", textSize),
          _infoCard(courses, textSize, isDark),
          const SizedBox(height: 20),
          _sectionTitle(context, "Certifications", textSize),
          _infoCard(certifications, textSize, isDark),
          const SizedBox(height: 20),
          _sectionTitle(context, "Performance Rating", textSize),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                Icon(
                  i <= rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: isTablet
                      ? 32
                      : isSmall
                      ? 22
                      : 28,
                ),
              const SizedBox(width: 8),
              Text(
                "$rating / 5",
                style: TextStyle(
                  fontSize: textSize,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumn(BuildContext context, double screenWidth) {
    const avatarRadius = 70.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildAvatar(avatarRadius),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable:
                      avatar.AvatarManagement.instructorNameNotifier,
                  builder: (context, name, _) {
                    return Text(
                      name.isNotEmpty ? name : instructorName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                Text(
                  role.isNotEmpty ? role : "Not specified",
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, "Performance Rating", 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 30,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      "$rating / 5",
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, "About Me", 18),
                  Text(
                    bio.isNotEmpty ? bio : "Not specified",
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, "Assigned Courses", 18),
                  _infoCard(courses, 18, isDark),
                  const SizedBox(height: 20),
                  _sectionTitle(context, "Certifications", 18),
                  _infoCard(certifications, 18, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(
    BuildContext context,
    String title,
    double fontSize,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  static Widget _infoCard(List<String> items, double fontSize, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.isNotEmpty
              ? items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "• $item",
                          style: TextStyle(
                            fontSize: fontSize,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList()
              : [
                  Text(
                    "None",
                    style: TextStyle(
                      fontSize: fontSize,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

// EditInstructorProfilePage (unchanged except avatar/bio fixes)
class EditInstructorProfilePage extends StatefulWidget {
  final String name;
  final String bio;
  final Uint8List? avatarBytes;
  final String? avatarUrl;

  const EditInstructorProfilePage({
    super.key,
    required this.name,
    required this.bio,
    this.avatarBytes,
    this.avatarUrl,
  });

  @override
  State<EditInstructorProfilePage> createState() =>
      _EditInstructorProfilePageState();
}

class _EditInstructorProfilePageState extends State<EditInstructorProfilePage> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  Uint8List? _avatarBytes;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    bioController = TextEditingController(text: widget.bio);
    _avatarBytes = widget.avatarBytes;
    _avatarUrl = widget.avatarUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _avatarUrl = null;
      });
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarBytes == null) return;
    try {
      await ApiService.uploadProfileImage(_avatarBytes!, 'profile.jpg');
      _avatarBytes = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading avatar: $e')));
    }
  }

  Future<void> _saveProfile() async {
    try {
      await _uploadAvatar();
      if (_avatarBytes != null && _avatarUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar upload failed, profile not saved'),
          ),
        );
        return;
      }
      final updatedData = {
        "name": nameController.text.trim(),
        "bio": bioController.text.trim(),
      };
      avatar.AvatarManagement().updateInstructorData(
        name: nameController.text.trim(),
        avatarUrl: _avatarUrl,
      );
      Navigator.pop(context, updatedData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    }
  }

  Widget _buildAvatar(double radius) {
    if (_avatarBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(_avatarBytes!),
      );
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: _avatarUrl!.startsWith('http')
            ? NetworkImage(_avatarUrl!)
            : NetworkImage('http://54.82.53.11:5001$_avatarUrl'),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: const AssetImage("assets/images/developer.png"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isSmall = width < 400;
    bool isTablet = width >= 400 && width < 1092;
    bool isDesktop = width >= 1092;

    double avatarSize = isSmall ? 40 : (isTablet ? 60 : 70);
    double fieldSpacing = isSmall ? 8 : 12;
    double cardPadding = isSmall ? 12 : 20;
    double maxCardWidth = isDesktop ? 800 : (isTablet ? 600 : double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 12 : 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          _buildAvatar(avatarSize),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFF5F299E),
                                radius: isSmall ? 12 : 16,
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: isSmall ? 14 : 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: fieldSpacing * 2),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                    ),
                    SizedBox(height: fieldSpacing),
                    TextField(
                      controller: bioController, // Use bioController
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "About Me",
                      ), // Label remains "About Me"
                    ),
                    SizedBox(height: fieldSpacing * 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5F299E),
                          ),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F299E),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Save Changes"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
