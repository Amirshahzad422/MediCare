import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/button.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class PatientOnboardingScreen extends ConsumerStatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  ConsumerState<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState
    extends ConsumerState<PatientOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _addressController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userProfile = await ref.read(userProfileProvider.future);
    final patientName = userProfile?.name ?? user.displayName ?? 'Patient';
    final patientPhone = userProfile?.phone ?? '';

    final service = ref.read(profileServiceProvider);
    final success = await service.updatePatientProfile(
      name: patientName,
      phone: patientPhone,
      address: _addressController.text.trim(),
      gender: _selectedGender ?? '',
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      photo: '',
      email: user.email ?? '',
      isOnboardingComplete: true,
    );

    if (success) {
      ref.invalidate(userDocProvider);
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      await Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save details. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: AppTypography.titleLarge.copyWith(color: AppColors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to MediCare!',
                style: AppTypography.displayLarge.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your details so we can personalize your experience.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              _buildInput(
                'Address',
                _addressController,
                Icons.place_outlined,
                isRequired: false,
              ),
              _buildInput(
                'Age',
                _ageController,
                Icons.cake_outlined,
                isRequired: true,
                isNumber: true,
              ),
              _buildGenderDropdown(),
              const SizedBox(height: 32),
              SharedButton(
                label: 'Complete Profile',
                isLoading: _isLoading,
                onPressed: _completeOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String hint,
      TextEditingController controller,
      IconData icon, {
        bool isNumber = false,
        bool isRequired = false,
        TextInputType? textInputType,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType ?? (isNumber ? TextInputType.number : TextInputType.text),
        style: AppTypography.bodyLarge,
        validator: validator ??
            (isRequired
                ? (v) => v == null || v.trim().isEmpty ? 'This field is required' : null
                : null),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium,
          prefixIcon: Icon(icon, color: AppColors.mediumBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
          ),
        ),
      ),
    );
  }



  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.mediumBlue),
        decoration: InputDecoration(
          hintText: 'Gender',
          hintStyle: AppTypography.bodyMedium,
          prefixIcon: const Icon(Icons.person_outline, color: AppColors.mediumBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Please select a gender' : null,
        items: _genders.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(e, style: AppTypography.bodyLarge),
          );
        }).toList(),
        onChanged: (v) => setState(() => _selectedGender = v),
      ),
    );
  }
}