import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertest/event/src/group_page/group_detail_page.dart';
import 'package:fluttertest/event/src/user_management/user_management_page.dart';
import 'package:fluttertest/instructor/pages/groups_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student/screens/auth/LoginPageScreen.dart';
import 'src/features/presentation/auth/login_screen.dart';
import 'src/features/presentation/auth/otp_verification_screen.dart';
import 'src/features/presentation/home_page.dart';
import 'src/features/presentation/event_organizer_profile_page.dart';
import 'src/group_page/group_page.dart';
import 'src/event_management/provider/event_provider.dart';
import 'src/event_management/event_local_datasource.dart';
import 'src/event_management/event_repository_impl.dart';
import 'src/core/providers/user_profile_provider.dart';
import 'src/group_page/provider/group_provider.dart';
import 'src/core/services/event_auth_service.dart';
import 'src/core/services/event_api_service.dart';
import 'src/user_management/enrollment_api_service.dart';
import 'src/user_management/enrollment_provider.dart';
import 'src/core/api/api_client.dart';
import 'src/widgets/app_header.dart';
import 'src/core/providers/dashboard_provider.dart';
import 'package:fluttertest/instructor/pages/notifications_page.dart';
import './src/group_page/group_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(MyApp(sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiProvider(
          providers: [
            // API Client Provider
            Provider<ApiClient>(create: (_) => ApiClient(sharedPreferences)),
            // Auth Service Provider
            ProxyProvider<ApiClient, EventAuthService>(
              update: (_, apiClient, __) =>
                  EventAuthService(apiClient, sharedPreferences),
            ),
            // Dashboard Provider
            ChangeNotifierProvider<DashboardProvider>(
              create: (_) => DashboardProvider(),
            ),
            // Event API Service Provider
            ProxyProvider<ApiClient, EventApiService>(
              update: (_, apiClient, __) => EventApiService(apiClient),
            ),
            // Event Provider
            ChangeNotifierProvider<EventProvider>(
              create: (context) {
                final apiClient = ApiClient(sharedPreferences);
                final eventApiService = EventApiService(apiClient);
                return EventProvider(
                  eventRepository: EventRepositoryImpl(
                    localDataSource: EventLocalDataSourceImpl(
                      sharedPreferences: sharedPreferences,
                    ),
                    apiService: eventApiService,
                  ),
                );
              },
            ),
            // User Profile Provider
            ChangeNotifierProvider<UserProfileProvider>(
              create: (context) {
                final apiClient = ApiClient(sharedPreferences);
                final authService = EventAuthService(
                  apiClient,
                  sharedPreferences,
                );
                return UserProfileProvider(authService);
              },
            ),
            // Group Provider
            ChangeNotifierProvider<GroupProvider>(
              create: (_) => GroupProvider(),
            ),
            // Enrollment API Service Provider
            ProxyProvider<ApiClient, EnrollmentApiService>(
              update: (_, apiClient, __) => EnrollmentApiService(apiClient),
            ),
            // Enrollment Provider
            ChangeNotifierProvider<EnrollmentProvider>(
              create: (context) {
                final apiClient = ApiClient(sharedPreferences);
                final enrollmentService = EnrollmentApiService(apiClient);
                return EnrollmentProvider(enrollmentService);
              },
            ),
          ],
          child: MaterialApp(
            title: 'Event App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
              '/verify-otp': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                return OtpVerificationScreen(
                  phoneNumber: args['phoneNumber'],
                  role: args['role'],
                );
              },
              '/home': (context) => const MainPage(),
            },
          ),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final String? organizerName;
  final bool? initialVerificationStatus;

  const MainPage({
    super.key,
    this.organizerName,
    this.initialVerificationStatus,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool? _isVerified;
  String? _verificationMessage;

  @override
  void initState() {
    super.initState();

    // Set initial verification status if passed from OTP
    if (widget.initialVerificationStatus != null) {
      _isVerified = widget.initialVerificationStatus;
      print(
        "🔍 INITIAL VERIFICATION STATUS FROM OTP: ${widget.initialVerificationStatus}",
      );
    }

    // TODO: Add fetchProfile() method to get fresh verification status from backend
  }

  // Request verification method for event organizers
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

      // Get access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

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

      // Make API call to request verification using ApiClient
      final apiClient = ApiClient(prefs);
      print('🔵 Making API call to: /user/request-verification');

      final response = await apiClient.post('/user/request-verification', {});

      print('🟢 API call completed');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Print response for debugging
      print('🔵 Verification API Response Status: ${response.statusCode}');
      print('🔵 Verification API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response to get success status and message
        try {
          final responseData = jsonDecode(response.body);
          final success = responseData['success'] ?? false;
          final message =
              responseData['message'] ?? 'Verification request processed';

          print('🔵 API Response - Success: $success, Message: $message');

          if (success) {
            print(
              '🔵 Verification request successful - Now checking verification status',
            );

            if (mounted) {
              setState(() {
                _verificationMessage = message.isNotEmpty
                    ? message
                    : 'Verification request sent successfully! Checking status...';
              });
            }

            // Immediately check current status first
            await _checkVerificationStatus();

            // If still not verified, start polling
            if (_isVerified != true) {
              _pollForVerificationStatus();
            }
          } else {
            // Show the API message for unsuccessful requests
            if (mounted) {
              setState(() {
                _verificationMessage = message.isNotEmpty
                    ? message
                    : 'Unable to process verification request';
              });
            }
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          if (mounted) {
            setState(() {
              _verificationMessage =
                  'Verification request sent successfully! Checking status...';
            });
          }
        }
      } else {
        // Handle HTTP error responses - try to parse message from response body
        String errorMessage =
            'Connection error: Server returned error ${response.statusCode}. Please try again.';

        try {
          final errorData = jsonDecode(response.body);
          final apiMessage = errorData['message'];
          if (apiMessage != null && apiMessage.toString().isNotEmpty) {
            errorMessage = apiMessage.toString();
          }
        } catch (e) {
          print('🔴 Failed to parse error response: $e');
          // Keep the default error message
        }

        if (mounted) {
          setState(() {
            _verificationMessage = errorMessage;
          });
        }
      }
    } catch (e) {
      print('❌ Error in _requestVerification: $e');
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _verificationMessage =
              'Something went wrong. Please check your connection and try again.';
        });
      }
    }
  }

  // Check verification status method
  Future<void> _checkVerificationStatus() async {
    try {
      print('🔄 Checking verification status...');

      // Fetch fresh profile data to check verification status
      await _fetchProfile();

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

  // Fetch profile data to get verification status
  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);

      final response = await apiClient.get('/user/profile');

      if (response.statusCode == 200) {
        // Parse and update verification status from profile
        final isVerified = prefs.getBool('is_verified') ?? false;
        _isVerified = isVerified;
        print('🔄 Profile fetched - Verification status: $isVerified');
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
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

  // List of page titles for the header
  final List<String> _pageTitles = [
    'Home',
    'User Management',
    'Groups',
    'Profile',
  ];

  // List of pages for navigation
  final List<Widget> _pages = [
    const HomePage(),
    const UserManagementPage(),
    const GroupsPagenew(),
    const EventOrganizerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      const Icon(Icons.home_outlined, size: 30, color: Colors.white),
      const Icon(Icons.person_outline, size: 30, color: Colors.white),
      const Icon(Icons.group_outlined, size: 30, color: Colors.white),
      const Icon(Icons.account_circle_outlined, size: 30, color: Colors.white),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Scaffold(
            appBar: AppHeader(
              title: _pageTitles[_selectedIndex],
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Handle notifications
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: _pages[_selectedIndex],
            bottomNavigationBar: CurvedNavigationBar(
              items: items,
              index: _selectedIndex,
              height: 60.0, // Using fixed height instead of .h extension
              color: Colors.black,
              buttonBackgroundColor: Colors.red,
              backgroundColor: Colors.transparent, // Changed to transparent
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              letIndexChange: (index) => true,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
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
                          'Your event organizer account needs to be verified to access all features. Please complete the verification process.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
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
                                // Refresh button - logout user and clear everything
                                setState(() {
                                  _verificationMessage = 'Logging out...';
                                });

                                try {
                                  // Clear all stored data using ApiClient
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final apiClient = ApiClient(prefs);

                                  // Clear tokens and user data
                                  await apiClient.clearTokens();

                                  // Clear all SharedPreferences
                                  await prefs.clear();

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
                        // Message area below buttons
                        if (_verificationMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _verificationMessage!.contains('success') ||
                                      _verificationMessage!.contains('sent') ||
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
                                  : _verificationMessage!.contains('Error') ||
                                        _verificationMessage!.contains(
                                          'Connection',
                                        )
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              border: Border.all(
                                color:
                                    _verificationMessage!.contains('success') ||
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
                                    : _verificationMessage!.contains('Error') ||
                                          _verificationMessage!.contains(
                                            'Connection',
                                          )
                                    ? Colors.orange
                                    : Colors.red,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _verificationMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _verificationMessage!.contains('success') ||
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
                                    ? Colors.green.shade700
                                    : _verificationMessage!.contains('Error') ||
                                          _verificationMessage!.contains(
                                            'Connection',
                                          )
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
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
  }
}
