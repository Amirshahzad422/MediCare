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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String? _selectedGender;
  int _age = 0;

  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.deepBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _age = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month ||
            (DateTime.now().month == picked.month &&
                DateTime.now().day < picked.day)) {
          _age--;
        }
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final service = ref.read(profileServiceProvider);
    final success = await service.updatePatientProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      gender: _selectedGender ?? '',
      age: _age,
      photo: '',
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
                'Full Name',
                _nameController,
                Icons.person_outline,
                isRequired: true,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              _buildInput(
                'Phone',
                _phoneController,
                Icons.phone_outlined,
                isRequired: false,
                textInputType: TextInputType.phone,
              ),
              _buildInput(
                'Address',
                _addressController,
                Icons.place_outlined,
                isRequired: false,
              ),
              _buildDateOfBirthField(),
              _buildGenderDropdown(),
              if (_age > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    'Age: $_age years',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.deepBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

  Widget _buildDateOfBirthField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date of Birth',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectDateOfBirth(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.mediumBlue),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirthController.text.isEmpty
                        ? 'Select date of birth'
                        : _dateOfBirthController.text,
                    style: AppTypography.bodyLarge.copyWith(
                      color: _dateOfBirthController.text.isEmpty
                          ? AppColors.lightBlue
                          : AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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