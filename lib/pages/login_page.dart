import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _launchRuditechUrl() async {
    final Uri url = Uri.parse('https://ruditech.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        // Successful login - navigate to dashboard
        context.go('/dashboard');
      } else {
        // Login failed
        _showError('Login failed. Please check your credentials.');
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'An error occurred. Please try again.';
      
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email before logging in.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Top-left logo
              Positioned(
                top: 24,
                left: 24,
                child: Image.asset(
                  'assets/images/image.png',
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              // Main content
              SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Login Form
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                    const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Hi, welcome back!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Email Field
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Email',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF000000),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _emailController,
                                                keyboardType: TextInputType.emailAddress,
                                                enabled: !_isLoading,
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Please enter your email';
                                                  }
                                                  if (!value.contains('@')) {
                                                    return 'Please enter a valid email';
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  hintText: 'Enter your email',
                                                  hintStyle: const TextStyle(
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE5E7EB),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE5E7EB),
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFDC2626),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          // Password Field
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Password',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF000000),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                enabled: !_isLoading,
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Please enter your password';
                                                  }
                                                  if (value.length < 6) {
                                                    return 'Password must be at least 6 characters';
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  hintText: 'Enter your password',
                                                  hintStyle: const TextStyle(
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE5E7EB),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE5E7EB),
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFDC2626),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons.visibility_outlined
                                                          : Icons.visibility_off_outlined,
                                                      color: const Color(0xFF6B7280),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscurePassword = !_obscurePassword;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 32),
                                          // Login Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFDC2626),
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: const Color(0xFFDC2626).withOpacity(0.6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Login',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Support Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Having trouble?',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        TextButton(
                                          onPressed: () {},
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Get support',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF2563EB),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Built by',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: _launchRuditechUrl,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ruditech',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}

