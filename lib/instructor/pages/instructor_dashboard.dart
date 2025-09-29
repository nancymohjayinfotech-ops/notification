import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/pages/Feedback.dart';
import 'package:fluttertest/instructor/pages/instructor_drawer.dart';
import 'package:fluttertest/student/screens/auth/LoginPageScreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../../student/providers/theme_provider.dart';
import '../services/api_service.dart';
import 'courses_page.dart';
import 'Settings.dart';
import 'notifications_page.dart';
import 'instructor_profile_page.dart';
import 'create_course_page.dart';
import 'groups_page.dart';
import 'avatar_management.dart' as avatar;
import 'student_page.dart';
import '../../live_session/pages/meetings_page.dart';

class InstructorDashboard extends StatefulWidget {
  final String instructorName;
  final bool? initialVerificationStatus;

  const InstructorDashboard({
    super.key,
    required this.instructorName,
    this.initialVerificationStatus,
  });

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _selectedIndex = 0;
  int _unreadNotifications = 2;
  late String _instructorName;
  bool? _isVerified; // Remove static false initialization
  String? _verificationMessage;

  @override
  void initState() {
    super.initState();
    _instructorName = widget.instructorName;

    // Set initial verification status if passed from OTP
    if (widget.initialVerificationStatus != null) {
      _isVerified = widget.initialVerificationStatus;
      print(
        "🔍 INITIAL VERIFICATION STATUS FROM OTP: ${widget.initialVerificationStatus}",
      );
    }

    // Fetch fresh profile data from backend - this will update _isVerified
    fetchProfile();
    loadSavedProfile();
    avatar.AvatarManagement.instructorNameNotifier.addListener(() {
      if (mounted) {
        setState(() {
          _instructorName =
              avatar.AvatarManagement.instructorNameNotifier.value;
        });
      }
    });
    avatar.AvatarManagement.avatarBytesNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    avatar.AvatarManagement.avatarUrlNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    avatar.AvatarManagement().initialize(instructorName: _instructorName);
  }

  Future<void> fetchProfile() async {
    // Get access token for API call using InstructorAuthService
    String? accessToken = await InstructorAuthService.getAccessToken();
    print('🔍 FETCHPROFILE - Full Token: $accessToken');
    print('🔍 FETCHPROFILE - Token Length: ${accessToken?.length ?? 0}');
    print(
      '🔍 FETCHPROFILE - Token Preview: ${accessToken?.substring(0, 20) ?? 'null'}...',
    );

    if (accessToken == null || accessToken.isEmpty) {
      print('❌ FETCHPROFILE - No access token available');
      throw Exception("No access token available");
    }

    final response = await ApiService.getProfile();
    print("🔍 FULL API RESPONSE:");
    print(response);

    if (response['user'] != null) {
      final userData = response['user'];
      final profileStatus =
          response['data']?['profileStatus'] ?? response['profileStatus'] ?? {};

      // Extract verification status from profileStatus (same as isProfileComplete logic)
      print("🔍 CHECKING VERIFICATION STATUS:");
      print("🔍 FULL RESPONSE STRUCTURE: $response");
      print("🔍 PROFILE STATUS OBJECT: $profileStatus");
      print("🔍 USER DATA OBJECT: $userData");

      // Check multiple possible locations for verification status
      bool isVerified = false;

      if (profileStatus.containsKey('isVerified')) {
        isVerified = profileStatus['isVerified'] == true;
        print(
          "🔍 Found in profileStatus['isVerified']: ${profileStatus['isVerified']} -> $isVerified",
        );
      } else if (userData.containsKey('isVerified')) {
        isVerified = userData['isVerified'] == true;
        print(
          "🔍 Found in userData['isVerified']: ${userData['isVerified']} -> $isVerified",
        );
      } else {
        print("🔍 NO VERIFICATION FIELD FOUND - defaulting to false");
      }

      print("🔍 FINAL EXTRACTED VERIFICATION STATUS: $isVerified");
      print("🔍 CURRENT _isVerified STATE BEFORE UPDATE: $_isVerified");

      // Update verification status in state
      if (mounted) {
        setState(() {
          _isVerified = isVerified;
          // Clear verification message if user is verified
          if (isVerified) {
            _verificationMessage = null;
          }
        });
        print("🔍 STATE UPDATED: _isVerified = $_isVerified");
        print("🔍 UI CONDITION (_isVerified != true): ${_isVerified != true}");
        print(
          "🔍 UI WILL ${(_isVerified != true) ? 'SHOW' : 'HIDE'} VERIFICATION OVERLAY",
        );

        // Force UI rebuild to ensure changes are reflected
        Future.microtask(() {
          if (mounted) {
            setState(() {});
            print("🔍 FORCED UI REBUILD - Current _isVerified: $_isVerified");
          }
        });
      }

      // Save verification status to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('verification_status', isVerified);
      print("🔍 SAVED VERIFICATION STATUS: $isVerified");

      // Update avatar URL
      final String avatarUrl = userData['avatar'] != null
          ? 'http://54.82.53.11:5001${userData['avatar']}'
          : "";
      print("Avatar URL: $avatarUrl");

      // Update instructor name
      avatar.AvatarManagement.instructorNameNotifier.value = userData["name"];

      // Update avatar URL
      avatar.AvatarManagement.avatarUrlNotifier.value = avatarUrl;

      await prefs.setString("avatarUrl", avatarUrl);
      await prefs.setString("instructorName", userData["name"] ?? "");
    } else {
      print("❌ NO USER DATA IN API RESPONSE");
      throw Exception("Failed to load profile");
    }
  }

  Future<void> loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString("avatarUrl");
    final savedName = prefs.getString("instructorName");

    if (savedUrl != null && savedUrl.isNotEmpty) {
      avatar.AvatarManagement.avatarUrlNotifier.value = savedUrl;
    }
    if (savedName != null && savedName.isNotEmpty) {
      avatar.AvatarManagement.instructorNameNotifier.value = savedName;
    }
  }

  Future<void> _requestVerification() async {
    print('🔵 _requestVerification method called');
    try {
      // Optimistic UI update - immediately show processing state
      setState(() {
        _verificationMessage = 'Processing verification request...';
      });

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('🔵 Loading dialog shown');

      // Get access token using InstructorAuthService
      String? accessToken = await InstructorAuthService.getAccessToken();
      print('🔍 DASHBOARD - Full Token: $accessToken');
      print('🔍 DASHBOARD - Token Length: ${accessToken?.length ?? 0}');
      print(
        '🔍 DASHBOARD - Token Preview: ${accessToken?.substring(0, 20) ?? 'null'}...',
      );

      if (accessToken == null || accessToken.isEmpty) {
        print('❌ DASHBOARD - No access token available');
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            _verificationMessage =
                'Authentication required. Please login again.';
          });
        }
        return;
      }

      // Make API call to request verification
      final apiUrl = '${ApiService.baseUrl}/user/request-verification';
      print('🔵 Making API call to: $apiUrl');
      print(
        '🔵 Headers: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, 20)}...',
      );

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('🟢 API call completed');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Print response for debugging
      print('🔵 Verification API Response Status: ${response.statusCode}');
      print('🔵 Verification API Response Headers: ${response.headers}');
      print('🔵 Verification API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed Response Data: $responseData');

        if (responseData['success'] == true) {
          print(
            '🔵 Verification request successful - Now polling for verification status',
          );

          if (mounted) {
            setState(() {
              _verificationMessage =
                  'Verification request sent successfully! Checking status...';
            });
          }

          // Immediately check current status first
          await _checkVerificationStatus();

          // If still not verified, start polling
          if (_isVerified != true) {
            _pollForVerificationStatus();
          }
        } else {
          if (mounted) {
            setState(() {
              _verificationMessage =
                  responseData['message'] ??
                  'Unable to process verification request';
            });
          }
        }
      } else {
        // Try to parse error response for user-friendly message
        String errorMessage =
            'Connection error: Server returned error ${response.statusCode}. Please try again.';

        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null &&
              errorData['message'].toString().isNotEmpty) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If parsing fails, keep the default message
          print('🔴 Failed to parse error response: $e');
        }

        if (mounted) {
          setState(() {
            _verificationMessage = errorMessage;
          });
        }
      }
    } catch (e) {
      print('🔴 Exception occurred: $e');
      print('🔴 Stack trace: ${StackTrace.current}');

      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        setState(() {
          _verificationMessage =
              'Something went wrong. Please check your connection and try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    avatar.AvatarManagement.instructorNameNotifier.removeListener(() {});
    avatar.AvatarManagement.avatarBytesNotifier.removeListener(() {});
    avatar.AvatarManagement.avatarUrlNotifier.removeListener(() {});
    super.dispose();
  }

  // Check verification status once
  Future<void> _checkVerificationStatus() async {
    try {
      print('🔄 Checking verification status...');

      // Fetch fresh profile data to check verification status
      await fetchProfile();

      // Update UI based on current status
      if (mounted) {
        setState(() {
          if (_isVerified == true) {
            _verificationMessage =
                'Account verified successfully! Welcome to the platform.';
            // Clear success message after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _verificationMessage = null;
                });
              }
            });
          } else {
            _verificationMessage =
                'Verification request sent successfully! Waiting for approval...';
          }
        });
      }
    } catch (e) {
      print('❌ Error checking verification status: $e');
      if (mounted) {
        setState(() {
          _verificationMessage = 'Error checking status. Please try again.';
        });
      }
    }
  }

  // Poll for verification status until it becomes true
  Future<void> _pollForVerificationStatus() async {
    print('🔄 Starting verification status polling...');

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        print('🔄 Polling verification status... (attempt ${timer.tick})');

        // Check verification status
        await _checkVerificationStatus();

        // If verified, stop polling
        if (_isVerified == true) {
          print('✅ Verification confirmed! Stopping polling.');
          timer.cancel();
        }

        // Stop polling after 10 minutes to prevent infinite polling
        if (timer.tick > 120) {
          // 120 * 5 seconds = 10 minutes
          print('⏰ Polling timeout - stopping after 10 minutes');
          timer.cancel();

          if (mounted) {
            setState(() {
              _verificationMessage =
                  'Verification is taking longer than expected. You can manually refresh or try again later.';
            });
          }
        }
      } catch (e) {
        print('❌ Error during polling: $e');
        // Continue polling even if there's an error, but show user-friendly message
        if (mounted && timer.tick % 6 == 0) {
          // Show error every 30 seconds (6 * 5 seconds)
          setState(() {
            _verificationMessage =
                'Checking verification status... (Connection issues detected)';
          });
        }
      }
    });
  }

  final List<Widget> _dashboardPages = const [
    CoursesTab(),
    StudentPage(isInDashboard: true),
    GroupsTab(),
    AnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Debug current verification state in build method

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        ThemeData currentTheme = themeProvider.themeMode == ThemeMode.light
            ? themeProvider.lightTheme
            : themeProvider.themeMode == ThemeMode.dark
            ? themeProvider.darkTheme
            : ThemeData(
                brightness: MediaQuery.of(context).platformBrightness,
                primaryColor: const Color(0xFF5F299E),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF5F299E),
                  foregroundColor: Colors.white,
                ),
              );

        return Theme(
          data: currentTheme,
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text('Hi! $_instructorName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFF5F299E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  actions: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () async {
                            final int? unread = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                            if (unread != null) {
                              setState(() {
                                _unreadNotifications = unread;
                              });
                            }
                          },
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: ValueListenableBuilder<String?>(
                        valueListenable:
                            avatar.AvatarManagement.avatarUrlNotifier,
                        builder: (context, avatarUrl, _) {
                          return CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : const AssetImage(
                                        "assets/images/developer.png",
                                      )
                                      as ImageProvider,
                          );
                        },
                      ),
                      onPressed: () async {
                        final updatedName = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InstructorProfilePage(
                              instructorName: _instructorName,
                              role: "Instructor",
                              about:
                                  "Experienced instructor with 5+ years teaching Flutter and mobile app development.",
                              courses: const [
                                "Flutter Development Masterclass",
                                "Advanced React & Node.js",
                                "UI/UX Design Fundamentals",
                              ],
                              certifications: const [
                                "Google Certified Flutter Developer",
                                "AWS Certified Educator",
                              ],
                              rating: 4.5,
                            ),
                          ),
                        );
                        if (updatedName != null && updatedName is String) {
                          setState(() {
                            _instructorName = updatedName;
                            avatar
                                    .AvatarManagement
                                    .instructorNameNotifier
                                    .value =
                                updatedName;
                          });
                        }
                      },
                    ),
                  ],
                ),
                drawer: InstructorDrawer(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                  instructorName: _instructorName,
                  unreadNotifications: _unreadNotifications,
                ),
                body: _dashboardPages[_selectedIndex],
                bottomNavigationBar: Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: const Color(0xFF5F299E),
                    unselectedItemColor: Colors.grey,
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
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
                ),
              ),
              // Verification overlay when not verified - show when false OR null (loading)
              if (_isVerified != true)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 60,
                              color: Color(0xFF5F299E),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Account Verification Required',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your instructor account needs to be verified to access all features. Please complete the verification process.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _requestVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5F299E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Verify Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Complete logout - clear everything
                                    setState(() {
                                      _verificationMessage = 'Logging out...';
                                    });

                                    try {
                                      // Use the proper logout method from auth service
                                      await InstructorAuthService.logout();

                                      // Clear all stored data
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.clear();

                                      // Clear avatar management data
                                      avatar
                                              .AvatarManagement
                                              .avatarUrlNotifier
                                              .value =
                                          '';
                                      avatar
                                              .AvatarManagement
                                              .avatarBytesNotifier
                                              .value =
                                          null;
                                      avatar
                                              .AvatarManagement
                                              .instructorNameNotifier
                                              .value =
                                          '';

                                      // Show logout message
                                      setState(() {
                                        _verificationMessage =
                                            'Logged out successfully. Redirecting...';
                                      });

                                      // Navigate to login screen after 1 second
                                      await Future.delayed(
                                        const Duration(seconds: 1),
                                      );
                                      if (mounted) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPageScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    } catch (e) {
                                      print('❌ Error during logout: $e');
                                      setState(() {
                                        _verificationMessage =
                                            'Logout completed. Redirecting...';
                                      });

                                      // Navigate to login even if error occurred
                                      await Future.delayed(
                                        const Duration(seconds: 1),
                                      );
                                      if (mounted) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPageScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.logout, size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        'Refresh',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Message area below button
                            if (_verificationMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      _verificationMessage!.contains(
                                            'success',
                                          ) ||
                                          _verificationMessage!.contains(
                                            'sent',
                                          ) ||
                                          _verificationMessage!.contains(
                                            'Processing',
                                          ) ||
                                          _verificationMessage!.contains(
                                            'Checking',
                                          ) ||
                                          _verificationMessage!.contains(
                                            'Refreshing',
                                          )
                                      ? Colors.green.withOpacity(0.1)
                                      : _verificationMessage!.contains(
                                              'Error',
                                            ) ||
                                            _verificationMessage!.contains(
                                              'Connection',
                                            )
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  border: Border.all(
                                    color:
                                        _verificationMessage!.contains(
                                              'success',
                                            ) ||
                                            _verificationMessage!.contains(
                                              'sent',
                                            ) ||
                                            _verificationMessage!.contains(
                                              'Processing',
                                            ) ||
                                            _verificationMessage!.contains(
                                              'Checking',
                                            ) ||
                                            _verificationMessage!.contains(
                                              'Refreshing',
                                            )
                                        ? Colors.green
                                        : _verificationMessage!.contains(
                                                'Error',
                                              ) ||
                                              _verificationMessage!.contains(
                                                'Connection',
                                              )
                                        ? Colors.orange
                                        : Colors.red,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _verificationMessage!.contains('success')
                                          ? Icons.check_circle_outline
                                          : _verificationMessage!.contains(
                                                  'sent',
                                                ) ||
                                                _verificationMessage!.contains(
                                                  'Processing',
                                                ) ||
                                                _verificationMessage!.contains(
                                                  'Checking',
                                                ) ||
                                                _verificationMessage!.contains(
                                                  'Refreshing',
                                                )
                                          ? Icons.hourglass_empty
                                          : _verificationMessage!.contains(
                                                  'Error',
                                                ) ||
                                                _verificationMessage!.contains(
                                                  'Connection',
                                                )
                                          ? Icons.warning_outlined
                                          : Icons.error_outline,
                                      color:
                                          _verificationMessage!.contains(
                                                'success',
                                              ) ||
                                              _verificationMessage!.contains(
                                                'sent',
                                              ) ||
                                              _verificationMessage!.contains(
                                                'Processing',
                                              ) ||
                                              _verificationMessage!.contains(
                                                'Checking',
                                              ) ||
                                              _verificationMessage!.contains(
                                                'Refreshing',
                                              )
                                          ? Colors.green
                                          : _verificationMessage!.contains(
                                                  'Error',
                                                ) ||
                                                _verificationMessage!.contains(
                                                  'Connection',
                                                )
                                          ? Colors.orange
                                          : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _verificationMessage!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              _verificationMessage!.contains(
                                                    'success',
                                                  ) ||
                                                  _verificationMessage!
                                                      .contains('sent') ||
                                                  _verificationMessage!
                                                      .contains('Processing') ||
                                                  _verificationMessage!
                                                      .contains('Checking') ||
                                                  _verificationMessage!
                                                      .contains('Refreshing')
                                              ? Colors.green.shade700
                                              : _verificationMessage!.contains(
                                                      'Error',
                                                    ) ||
                                                    _verificationMessage!
                                                        .contains('Connection')
                                              ? Colors.orange.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double cardPadding = constraints.maxWidth < 600 ? 16 : 32;
            return SingleChildScrollView(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('My Courses'),
                  SizedBox(height: cardPadding),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.school,
                                color: Color(0xFF5F299E),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Courses',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Manage your courses and categories',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CoursesPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5F299E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Go to Courses',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: cardPadding),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.videocam,
                                color: Color(0xFF5F299E),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Meetings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Schedule and join virtual meetings with students',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) => const MeetingsPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5F299E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Go to Meetings',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: cardPadding + 8),
                  // _buildActionButton(
                  //   context: context,
                  //   title: 'Create New Course',
                  //   icon: Icons.add,
                  //   onTap: () {
                  //     try {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => const CreateCoursePage(),
                  //         ),
                  //       );
                  //     } catch (e) {
                  //       showDialog(
                  //         context: context,
                  //         builder: (BuildContext context) {
                  //           return AlertDialog(
                  //             title: const Text('Error'),
                  //             content: Text(
                  //               'Could not open create course page: $e',
                  //             ),
                  //             actions: [
                  //               TextButton(
                  //                 onPressed: () {
                  //                   Navigator.of(context).pop();
                  //                 },
                  //                 child: const Text('OK'),
                  //               ),
                  //             ],
                  //           );
                  //         },
                  //       );
                  //     }
                  //   },
                  // ),
                  _buildCourseCard(
                    title: 'Flutter Development Masterclass',
                    students: 42,
                    progress: 0.8,
                    image: 'assets/images/developer.png',
                  ),
                  _buildCourseCard(
                    title: 'Advanced React & Node.js',
                    students: 28,
                    progress: 0.6,
                    image: 'assets/images/devop.png',
                  ),
                  _buildCourseCard(
                    title: 'UI/UX Design Fundamentals',
                    students: 35,
                    progress: 0.9,
                    image: 'assets/images/digital.jpg',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5F299E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5F299E).withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required String title,
    required int students,
    required double progress,
    required String image,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$students students enrolled',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          color: const Color(0xFF5F299E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // View/Edit course
                        },
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View course analytics
                        },
                        child: Text(
                          'View',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
    );
  }
}

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return const GroupsPage(isInDashboard: true);
      },
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildAnalyticCards(context),
              const SizedBox(height: 24),
              const Text(
                'Course Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Course Performance Chart')),
              ),
              const SizedBox(height: 24),
              const Text(
                'Student Engagement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Student Engagement Data')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticCard(
            context: context,
            title: 'Total Students',
            value: '105',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnalyticCard(
            context: context,
            title: 'Courses',
            value: '3',
            icon: Icons.school,
            color: const Color(0xFF5F299E),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
