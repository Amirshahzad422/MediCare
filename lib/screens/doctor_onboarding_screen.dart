import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/button.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class DoctorOnboardingScreen extends ConsumerStatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  ConsumerState<DoctorOnboardingScreen> createState() =>
      _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState
    extends ConsumerState<DoctorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSpecialty;
  String? _selectedCity;
  String? _selectedDegree;
  String? _selectedDuration = '30';
  int _businessStartHour = 8;
  int _businessEndHour = 18;

  final _otherSpecialtyController = TextEditingController();
  final _otherCityController = TextEditingController();
  final _otherDegreeController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _selectedDays = [];
  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> _durations = ['15', '30', '45', '60'];

  bool _isLoading = false;

  final List<String> _specialties = [
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Gynecologist',
    'Orthopedic',
    'Psychiatrist',
    'Ophthalmologist',
    'Endocrinologist',
    'Dentist',
    'General Physician',
    'Other'
  ];
  final List<String> _cities = [
    'New York',
    'Los Angeles',
    'Chicago',
    'San Francisco',
    'Boston',
    'Houston',
    'Seattle',
    'Miami',
    'Other'
  ];
  final List<String> _degrees = ['MBBS', 'MD', 'MS', 'BDS', 'FCPS', 'Other'];

  @override
  void dispose() {
    _otherSpecialtyController.dispose();
    _otherCityController.dispose();
    _otherDegreeController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort((a, b) => _allDays.indexOf(a).compareTo(_allDays.indexOf(b)));
    });
  }

  String _formatHour(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display $suffix';
  }

  List<String> _generateSlotsForBusinessHours(
      int durationMinutes,
      int startHour,
      int endHour,
      ) {
    final List<String> slots = [];
    final startMinutes = startHour * 60;
    final endMinutes = endHour * 60;

    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += durationMinutes) {
        final slotStart = hour * 60 + minute;
        final slotEnd = slotStart + durationMinutes;
        if (slotStart >= startMinutes && slotEnd <= endMinutes) {
          final period = hour < 12 ? 'AM' : 'PM';
          int displayHour = hour % 12;
          if (displayHour == 0) displayHour = 12;
          final displayMinute = minute.toString().padLeft(2, '0');
          slots.add('$displayHour:$displayMinute $period');
        }
      }
    }
    return slots;
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one available day.')),
      );
      return;
    }
    if (_businessEndHour <= _businessStartHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final finalSpecialty = _selectedSpecialty == 'Other'
        ? _otherSpecialtyController.text.trim()
        : _selectedSpecialty!;
    final finalCity = _selectedCity == 'Other'
        ? _otherCityController.text.trim()
        : _selectedCity!;
    final finalDegree = _selectedDegree == 'Other'
        ? _otherDegreeController.text.trim()
        : _selectedDegree!;
    final feeValue = double.tryParse(_feeController.text.trim()) ?? 0;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userProfile = ref.read(userProfileProvider).value;
    final String doctorName = userProfile?.name ?? user.displayName ?? 'Doctor';

    final String todayName = _allDays[DateTime.now().weekday - 1];
    final bool isAvailableToday = _selectedDays.contains(todayName);

    final duration = int.parse(_selectedDuration!);
    final generatedSlots = _generateSlotsForBusinessHours(
      duration,
      _businessStartHour,
      _businessEndHour,
    );

    final service = ref.read(profileServiceProvider);
    final success = await service.updateDoctorProfile(
      name: doctorName,
      specialty: finalSpecialty,
      fee: feeValue,
      city: finalCity,
      bio: _bioController.text.trim(),
      consultationDuration: duration,
      slots: generatedSlots,
      availableDays: _selectedDays,
      credentials: finalDegree,
      availableToday: isAvailableToday,
      isOnboardingComplete: true,
      photo:
      'https://i.pinimg.com/474x/9e/83/75/9e837528f01cf3f42119c5aeeed1b336.jpg?nii=t',
      businessStartHour: _businessStartHour,
      businessEndHour: _businessEndHour,
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
                'Welcome to MediCare, Doctor!',
                style: AppTypography.displayLarge.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your professional details so patients can find and book you.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              _buildDropdown(
                'Specialty',
                _specialties,
                _selectedSpecialty,
                Icons.medical_services_outlined,
                    (v) => setState(() => _selectedSpecialty = v),
              ),
              if (_selectedSpecialty == 'Other')
                _buildInput(
                  'Enter your specialty',
                  _otherSpecialtyController,
                  Icons.edit,
                  isRequired: true,
                ),
              _buildDropdown(
                'City',
                _cities,
                _selectedCity,
                Icons.location_city_outlined,
                    (v) => setState(() => _selectedCity = v),
              ),
              if (_selectedCity == 'Other')
                _buildInput(
                  'Enter your city',
                  _otherCityController,
                  Icons.edit,
                  isRequired: true,
                ),
              _buildDropdown(
                'Degrees / Credentials',
                _degrees,
                _selectedDegree,
                Icons.school_outlined,
                    (v) => setState(() => _selectedDegree = v),
              ),
              if (_selectedDegree == 'Other')
                _buildInput(
                  'Enter your degree',
                  _otherDegreeController,
                  Icons.edit,
                  isRequired: true,
                ),
              _buildInput(
                'Consultation Fee (\$)',
                _feeController,
                Icons.payments_outlined,
                isNumber: true,
                isRequired: true,
              ),
              _buildInput(
                'Short Biography',
                _bioController,
                Icons.description_outlined,
                maxLines: 3,
                isRequired: false,
              ),
              const Divider(height: 32, thickness: 1),
              Text(
                'Set Your Availability',
                style: AppTypography.titleLarge.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Days',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Select the days you are available for consultations.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day.substring(0, 3)),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.deepBlue,
                    backgroundColor: AppColors.iceBlue.withOpacity(0.3),
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.white : AppColors.deepBlue,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.deepBlue : AppColors.lightBlue,
                        width: 1,
                      ),
                    ),
                    onSelected: (_) => _toggleDay(day),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Consultation Duration',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'How long does each session usually last?',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildDropdownDuration(
                'Duration (Minutes)',
                _durations,
                _selectedDuration,
                Icons.timer_outlined,
                    (v) => setState(() => _selectedDuration = v),
              ),
              const SizedBox(height: 24),
              Text(
                'Business Hours',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Set the start and end time of your working day.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildHourDropdown(
                      'From',
                      _businessStartHour,
                          (v) => setState(() => _businessStartHour = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHourDropdown(
                      'To',
                      _businessEndHour,
                          (v) => setState(() => _businessEndHour = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SharedButton(
                label: 'Start Consulting',
                isLoading: _isLoading,
                onPressed: _completeOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String hint,
      List<String> items,
      String? currentValue,
      IconData icon,
      ValueChanged<String?> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.mediumBlue),
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
        validator: (v) => v == null || v.isEmpty ? 'Please select an option' : null,
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: AppTypography.bodyLarge),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownDuration(
      String hint,
      List<String> items,
      String? currentValue,
      IconData icon,
      ValueChanged<String?> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.mediumBlue),
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
        validator: (v) => v == null || v.isEmpty ? 'Please select an option' : null,
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text('$e Minutes', style: AppTypography.bodyLarge),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildHourDropdown(
      String label,
      int currentValue,
      ValueChanged<int?> onChanged,
      ) {
    final hours = List.generate(24, (i) => i);
    return DropdownButtonFormField<int>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
        ),
      ),
      validator: (v) => v == null ? 'Select hour' : null,
      items: hours
          .map((hour) => DropdownMenuItem(
        value: hour,
        child: Text(_formatHour(hour), style: AppTypography.bodyLarge),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInput(
      String hint,
      TextEditingController controller,
      IconData icon, {
        bool isNumber = false,
        int maxLines = 1,
        bool isRequired = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (v) =>
        isRequired && (v == null || v.isEmpty) ? 'This field is required' : null,
        style: AppTypography.bodyLarge,
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
}