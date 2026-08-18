import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedRole = 1;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    try {
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      if (await authService.isEmailRegistered(email)) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email is already registered. Please login instead.')),
        );
        return;
      }

      if (await authService.isPhoneRegistered(phone)) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This phone number is already registered.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushNamed(
        context, 
        '/otp',
        arguments: {
          'isRegistrationFlow': true,
          'name': _nameController.text.trim(),
          'email': email,
          'password': _passwordController.text.trim(),
          'phone': phone,
          'role': _selectedRole,
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.png',
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Register',
                          style: AppTypography.displayLarge.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please Register Before Login',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Full Name*',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: AppTypography.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Anna Grace',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.black38),
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.mediumBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                              return 'Name can only contain letters and spaces';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Email*',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          style: AppTypography.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'anna@gmail.com',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.black38),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.mediumBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Phone Number*',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          style: AppTypography.bodyLarge,
                          keyboardType: TextInputType.text, 
                          decoration: InputDecoration(
                            hintText: '+1 555 123 4567',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.black38),
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.mediumBlue),
                            errorMaxLines: 2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value.trim())) {
                              return 'Enter a valid number with country code\n(e.g. +15551234567)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Password*',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          style: AppTypography.bodyLarge,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.black38),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mediumBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.lightBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Select Your Role*',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment<int>(
                              value: 1,
                              label: Text('Patient'),
                              icon: Icon(Icons.person_outline),
                            ),
                            ButtonSegment<int>(
                              value: 2,
                              label: Text('Doctor'),
                              icon: Icon(Icons.medical_services_outlined),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedRole = newSelection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppColors.mediumBlue,
                            selectedForegroundColor: AppColors.white,
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.mediumBlue,
                            side: const BorderSide(color: AppColors.lightBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mediumBlue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                              : Text('Register', style: AppTypography.buttonText),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Have an account? ",
                              style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: Text(
                                'Login Here',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.mediumBlue,
                                  fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
    );
  }
}