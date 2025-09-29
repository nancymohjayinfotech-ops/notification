import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validation_utils.dart';
import '../../core/utils/error_handler.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate email
    final emailError = ValidationUtils.validateEmail(email);
    if (emailError != null) {
      ErrorHandler.showErrorSnackBar(context, emailError);
      return;
    }

    // Validate password
    final passwordError = ValidationUtils.validatePassword(password);
    if (passwordError != null) {
      ErrorHandler.showErrorSnackBar(context, passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.adminLogin(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        ErrorHandler.showSuccessSnackBar(context, AppStrings.loginSuccessful);

        // Navigate to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          result['message'] ?? AppStrings.loginFailed,
        );
      }
    } catch (e) {
      final errorMessage = ErrorHandler.handleApiError(e);
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo and Title
              const Column(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: Color(0xFF9C27B0),
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.welcomeBack,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.signInToContinue,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: AppStrings.email,
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              // Password Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: AppStrings.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
              ),
              const SizedBox(height: 24),
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        AppStrings.login,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
           
              const SizedBox(height: 20),
              // Forgot Password
              // TextButton(
              //   onPressed: () {},
              //   child: const Text(
              //     'Forgot Password?',
              //     style: TextStyle(color: Color(0xFF9C27B0)),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
