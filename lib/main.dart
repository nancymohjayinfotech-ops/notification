import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/auth/FormCommonPageScreen.dart';
import 'package:fluttertest/student/screens/auth/LoginPageScreen.dart';
import 'package:fluttertest/student/screens/auth/PhonePageScreen.dart';
import 'package:fluttertest/student/screens/auth/SplashScreen.dart';
import 'package:fluttertest/student/screens/courses/AllCoursesPage.dart';
import 'package:provider/provider.dart';
import 'package:fluttertest/student/screens/courses/AddToCart.dart';
import 'package:fluttertest/student/screens/Home/CartPage.dart';
import 'package:fluttertest/student/screens/auth/UserProfileForm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fluttertest/student/screens/Home/Dashboard.dart';
import 'package:fluttertest/student/screens/categories/SubCategories/DevOP.dart';
import 'package:fluttertest/student/screens/categories/DeveloperPage.dart';
import 'package:fluttertest/student/screens/categories/SubCategories/DigitalMarketing.dart';
import 'package:fluttertest/student/screens/categories/InterestBasedPage.dart';
import 'package:fluttertest/student/screens/auth/SignUpPage.dart';
import 'package:fluttertest/student/screens/categories/TesterPage.dart';
import 'package:fluttertest/student/screens/auth/PhoneLoginPage.dart';
import 'package:fluttertest/event/main_event.dart' as event_app;
import 'package:fluttertest/instructor/pages/instructor_dashboard.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:fluttertest/student/providers/theme_provider.dart';
import 'package:fluttertest/student/providers/app_state_provider.dart';
import 'package:fluttertest/student/providers/navigation_provider.dart';
import 'package:fluttertest/student/providers/chat_provider.dart';
import 'package:fluttertest/student/services/favorites_service.dart';
import 'package:fluttertest/student/services/auth_service.dart';
import 'package:fluttertest/student/services/offers_service.dart';
import 'package:fluttertest/student/services/cart_api_service.dart';
import 'package:fluttertest/student/repositories/course_repository.dart';
import 'package:fluttertest/student/repositories/user_repository.dart';
import 'package:fluttertest/student/models/user_role.dart';
import 'package:fluttertest/instructor/pages/instructor_login_page.dart';
import 'package:fluttertest/instructor/pages/instructor_schedule_page.dart';
import 'package:fluttertest/instructor/pages/student_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertest/student/screens/courses/AllCoursesPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertest/event/main_event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertest/student/screens/event/event_details_page.dart';

import 'package:uuid/uuid.dart';

// Routes

// Event

import 'package:fluttertest/event/main_event.dart' as eventApp;
import '../../event/routes/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  await Firebase.initializeApp(); // Initialize Firebase in background

  print('🔔 Background message received: ${message.messageId}');

  print('Data: ${message.data}');

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if (kIsWeb || !Platform.isIOS && !Platform.isAndroid) {
  //   await Firebase.initializeApp(
  //     options: const FirebaseOptions(
  //       apiKey: "AIzaSyCMM9sLCT8IxhA8cuucp2P0Ou2KrCSAgag",

  //       authDomain: "testnotification-1ef05.firebaseapp.com",

  //       projectId: "testnotification-1ef05",

  //       storageBucket: "testnotification-1ef05.appspot.com",

  //       messagingSenderId: "746508962866",

  //       appId: "1:746508962866:web:f900d17aa110435ea7802b",

  //       measurementId: "G-NB635SFCHC",
  //     ),
  //   );
  // } else {
  //   await Firebase.initializeApp();
  // }
   await Firebase.initializeApp();
     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final prefs = await SharedPreferences.getInstance();
  final roleString = prefs.getString('user_role');

  if (roleString == UserRole.eventOrganizer.value) {
    runApp(eventApp.MyApp(sharedPreferences: prefs)); // ✅ Event Organizer app
  } else {
    print('🔄 Launching main app for role: $roleString');
    await runMainApp();
  }
}

// String getPlatform() {
//   if (kIsWeb) return "web";
//   try {
//     if (Platform.isAndroid) return "android";

//     if (Platform.isIOS) return "ios";
//   } catch (e) {
//     return "unknown";
//   }

//   return "unknown";
// }
String getPlatform() => "android";

Future<void> setupFCM(String roleString) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get device token
  String? token = await messaging.getToken();
  print("📱 FCM Token: $token");

  // Send token to backend
  if (token != null) {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    
    final url = Uri.parse('https://lms-latest-dsrn.onrender.com/api/device-tokens/register');

    final deviceId = Uuid().v4();
    prefs.setString('device_id', deviceId); 
    final body = {
      "token": token,
      "platform": "android",
      "deviceId": deviceId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(body),
      );
      print('✅ Token registered on backend: ${response.statusCode}');
      print("📤 Sending FCM registration request:");
      print("URL: $url");
      print("Headers: {Authorization: Bearer $accessToken}");
      print("Body: ${jsonEncode(body)}");
      print('✅ Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  // Subscribe to topics for group notifications
  await messaging.subscribeToTopic(roleString); // e.g., "student" or "instructor"
  await messaging.subscribeToTopic('all_users'); // optional general topic

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message: ${message.notification?.title}');
    final notification = message.notification;

    if (notification != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text("${notification.title}\n${notification.body}")),
      );
    }

    // Navigate if eventId exists
    final data = message.data;
    if (data['type'] == 'event' && data['eventId'] != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => EventDetailsPage(eventId: data['eventId'])),
      );
    }
  });

  // App opened via notification (background -> foreground)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'event' && data['eventId'] != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => EventDetailsPage(eventId: data['eventId'])),
      );
    }
  });

  // Check if app was opened from terminated state
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null && initialMessage.data['type'] == 'event') {
    final eventId = initialMessage.data['eventId'];
    if (eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (context) => EventDetailsPage(eventId: eventId)),
        );
      });
    }
  }
}

// Initialize AuthService
Future<void> runMainApp() async {
  // final authService = AuthService();
  // print('🔄 Initializing AuthService...');
  // await authService.initialize();
  // await setupFCM(authService);
  
  final prefs = await SharedPreferences.getInstance();

  final roleString = prefs.getString('user_role') ?? 'student';

  await setupFCM(roleString);
  // Main app for Students and Instructors

  runApp(
    MultiProvider(
      providers: [
        // State Providers
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AppStateProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        // ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => FavoritesService()),
        ChangeNotifierProvider(create: (context) => OffersService()),
        // ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (context) => CartApiService()),

        // Repository Providers
        Provider<CourseRepository>(create: (context) => CourseRepositoryImpl()),
        Provider<UserRepository>(create: (context) => UserRepositoryImpl()),
      ],
      child: const ScreenPage(),
    ),
  );
}

class ScreenPage extends StatelessWidget {
  const ScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthService>(
      builder: (context, themeProvider, authService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),

          routes: {
            '/loginpage': (context) => LoginPageScreen(), //create me
            '/phonesignup': (context) => PhonePageScreeen(), //create me
            '/formcommon': (context) =>
                FormCommonPageScreen(userRole: 'instructor'), //create me
            '/phonelogin': (context) => PhoneLoginPage(),

            //create me
            '/userprofileform': (context) => UserProfileForm(),
            '/signuppage': (context) => Signuppage(
              initialRole: UserRole.everyone, // <-- Provide required argument
              isSignUp: true,
            ),
            '/interestpage': (context) => InterestBasedPage(),
            '/developerpage': (context) => DeveloperPages(),
            '/testerpage': (context) => TesterPages(),
            '/digitalmarketingpage': (context) => DigitalMarketingPages(),
            '/devoppage': (context) => DevOpPages(),
            '/dashboard': (context) => Dashboard(),
            '/addtocart': (context) => AddToCartPage(
              courseTitle: 'Sample Course',
              courseAuthor: 'Sample Author',
              courseImage: 'assets/images/developer.png',
              coursePrice: '\$99.00',
            ),
            '/cart': (context) => CartPage(),
            '/all-courses': (context) =>
                AllCoursesPage(selectedLanguage: 'English'),
            '/instructorlogin': (context) => const InstructorLoginPage(),
            '/instructorschedule': (context) => const InstructorSchedulePage(),
            '/instructordashboard': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final instructorName = args is String ? args : 'Instructor';
              return InstructorDashboard(instructorName: instructorName);
            },
            '/studentpage': (context) =>
                const StudentPage(isInDashboard: false),
          },
        );
      },
    );
  }
}

// AuthWrapper to check authentication state on app startup
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget? _homeWidget;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check user role first
      final userRole = prefs.getString('user_role');
      print('🔄 Hot reload detected - User role: $userRole');

      if (userRole == 'instructor') {
        // Check if instructor is logged in
        final isInstructorLoggedIn = await InstructorAuthService.isLoggedIn();

        if (isInstructorLoggedIn) {
          final instructorName =
              prefs.getString('instructorName') ?? 'Instructor';
          final verificationStatus = prefs.getBool('verification_status');

          print('🔄 Instructor session found');
          print('🔄 Instructor name: $instructorName');
          print('🔄 Verification status: $verificationStatus');

          setState(() {
            _homeWidget = InstructorDashboard(
              instructorName: instructorName,
              initialVerificationStatus: verificationStatus,
            );
            _isLoading = false;
          });
          return;
        }
      } else if (userRole == 'event' || userRole == 'event_organizer') {
        // Check if event organizer is logged in
        final accessToken = prefs.getString('access_token');

        if (accessToken != null && accessToken.isNotEmpty) {
          final organizerName =
              prefs.getString('organizerName') ?? 'Event Organizer';
          final verificationStatus =
              prefs.getBool('verification_status') ?? false;

          print('🔄 Event organizer session found');
          print('🔄 Organizer name: $organizerName');
          print('🔄 Verification status: $verificationStatus');

          setState(() {
            _homeWidget = event_app.MainPage(
              organizerName: organizerName,
              initialVerificationStatus: verificationStatus,
            );
            _isLoading = false;
          });
          return;
        }
      } else if (userRole == 'student') {
        // Check if student is logged in
        final accessToken = prefs.getString('access_token');

        if (accessToken != null && accessToken.isNotEmpty) {
          print('🔄 Student session found');

          setState(() {
            _homeWidget = Dashboard(); // Student dashboard
            _isLoading = false;
          });
          return;
        }
      }

      // No valid session found, go to login page
      print('🔄 No valid session found, redirecting to login');
      setState(() {
        _homeWidget = const LoginPageScreen();
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking auth state: $e');
      // Default to login page on error
      setState(() {
        _homeWidget = const LoginPageScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5F299E)),
        ),
      );
    }

    return _homeWidget ?? const LoginPageScreen();
  }
}
