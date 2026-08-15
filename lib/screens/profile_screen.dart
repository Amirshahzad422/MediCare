import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../components/button.dart';
import '../components/modal.dart';
import '../models/doctor_model.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _credentialsController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _feeController = TextEditingController();
  final _cityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;
  bool _availableToday = true;
  bool _synced = false;
  bool _uploadingPhoto = false;
  bool _isEditing = false;
  String _photoUrl = '';
  
  // Patient fields
  String _gender = '';
  final _ageController = TextEditingController();

  List<String> _currentSlots = [];
  List<String> _currentAvailableDays = [];
  int _currentDuration = 30;
  int _businessStartHour = 8;
  int _businessEndHour = 18;

  final ScrollController _scrollController = ScrollController();
  FocusNode? _firstErrorNode;
  
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _specialtyFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _credentialsFocus = FocusNode();
  final _experienceFocus = FocusNode();
  final _feeFocus = FocusNode();
  final _bioFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _credentialsController.dispose();
    _specialtyController.dispose();
    _feeController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _scrollController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _specialtyFocus.dispose();
    _cityFocus.dispose();
    _credentialsFocus.dispose();
    _experienceFocus.dispose();
    _feeFocus.dispose();
    _bioFocus.dispose();

    super.dispose();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _synced = false;
    });

    ref.invalidate(userProfileProvider);
    ref.invalidate(userDocProvider);

    final profile = await ref.read(userProfileProvider.future);

    if (profile?.role == 2) {
      ref.invalidate(doctorProfileProvider);
      await ref.read(doctorProfileProvider.future);
    }

    await ref.read(userDocProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Center(
            child: Text('Please log in to view your profile.'),
          );
        }

        final isDoctor = profile.role == 2;
        final userDocAsync = ref.watch(userDocProvider);
        final doctorDocAsync =
        isDoctor ? ref.watch(doctorProfileProvider) : null;

        return userDocAsync.when(
          data: (userDoc) {
            if (userDoc == null) {
              return const Center(
                child: Text('Profile data not found.'),
              );
            }

            if (isDoctor && doctorDocAsync != null) {
              return doctorDocAsync.when(
                data: (doctorDoc) {
                  return _buildProfileContent(
                    profile,
                    userDoc,
                    doctorDoc,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.deepBlue,
                  ),
                ),
                error: (err, stack) => const Center(
                  child: Text('Failed to load doctor profile'),
                ),
              );
            }

            return _buildProfileContent(
              profile,
              userDoc,
              null,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.deepBlue,
            ),
          ),
          error: (err, stack) => const Center(
            child: Text('Failed to load profile'),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.deepBlue,
        ),
      ),
      error: (err, stack) => const Center(
        child: Text('Failed to load profile'),
      ),
    );
  }

  Widget _buildProfileContent(
      dynamic profile,
      Map<String, dynamic> userDoc,
      DoctorModel? doctorDoc,
      ) {
    final isDoctor = profile.role == 2;

    if (isDoctor && doctorDoc == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Doctor profile not found.\nPlease complete your onboarding.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/doctor-onboarding',
                );
              },
              child: const Text('Go to Onboarding'),
            ),
          ],
        ),
      );
    }

    if (!_synced) {
      _synced = true;

      _nameController.text = userDoc['name'] ?? profile.name;
      _emailController.text = profile.email;
      _phoneController.text = userDoc['phone'] ?? '';
      _addressController.text = userDoc['address'] ?? '';
      _photoUrl = userDoc['photo'] ?? '';
      
      if (!isDoctor) {
        _gender = userDoc['gender'] ?? '';
        _ageController.text = (userDoc['age'] ?? 0).toString();
      }

      if (isDoctor && doctorDoc != null) {
        _specialtyController.text = doctorDoc.specialty;
        _cityController.text = doctorDoc.city;
        _credentialsController.text = doctorDoc.qualifications;
        _experienceController.text = doctorDoc.experience.toString();
        _feeController.text = doctorDoc.fee.toStringAsFixed(0);
        _bioController.text = doctorDoc.bio;
        _availableToday = doctorDoc.availableToday;
        _currentSlots = doctorDoc.slots;
        _currentAvailableDays = doctorDoc.availableDays;
        _currentDuration = doctorDoc.consultationDuration;
        _businessStartHour = doctorDoc.businessStartHour;
        _businessEndHour = doctorDoc.businessEndHour;
      }
    }

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      color: AppColors.deepBlue,
      backgroundColor: AppColors.white,
      displacement: 30,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarHeader(
                    profile.name,
                    isDoctor,
                  ),
                  const SizedBox(height: 24),
                  _buildEditToggle(),
                  const SizedBox(height: 16),
                  _buildInfoFields(isDoctor),
                  const SizedBox(height: 24),
                  _buildActionButtons(isDoctor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarHeader(String name, bool isDoctor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.iceBlue,
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: _photoUrl.isNotEmpty
                    ? Image.network(
                  _photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) =>
                      _defaultAvatar(isDoctor),
                )
                    : _defaultAvatar(isDoctor),
              ),
            ),
            if (_isEditing)
              GestureDetector(
                onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.deepBlue,
                  ),
                  child: _uploadingPhoto
                      ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.camera_alt,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
          ),
        ),
        Text(
          isDoctor ? 'Doctor' : 'Patient',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.mediumBlue,
          ),
        ),
        if (_uploadingPhoto)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Uploading photo...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mediumBlue,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _defaultAvatar(bool isDoctor) {
    return Container(
      color: AppColors.iceBlue,
      child: Icon(
        isDoctor ? Icons.medical_services : Icons.person,
        size: 48,
        color: AppColors.deepBlue,
      ),
    );
  }

  Widget _buildEditToggle() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          if (_isEditing) {
            setState(() {
              _isEditing = false;
              _synced = false;
              _firstErrorNode = null;
            });

              // Unfocus all fields
              _nameFocus.unfocus();
              _emailFocus.unfocus();
              _phoneFocus.unfocus();
              _addressFocus.unfocus();
              _specialtyFocus.unfocus();
              _cityFocus.unfocus();
              _credentialsFocus.unfocus();
              _feeFocus.unfocus();
              _bioFocus.unfocus();
          } else {
            setState(() {
              _isEditing = true;
              _firstErrorNode = null;
            });
          }
        },
        icon: Icon(
          _isEditing ? Icons.close : Icons.edit_outlined,
          size: 18,
        ),
        label: Text(
          _isEditing ? 'Cancel Editing' : 'Edit Profile',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          side: const BorderSide(
            color: AppColors.deepBlue,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFields(bool isDoctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          _buildField(
            'Full Name',
            _nameController,
            Icons.person_outline,
            focusNode: _nameFocus,
            readOnly: !_isEditing,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                _firstErrorNode ??= _nameFocus;
                return 'Enter your name';
              }
              return null;
            },
          ),
          _buildField(
            'Email',
            _emailController,
            Icons.email_outlined,
            focusNode: _emailFocus,
            readOnly: true,
            textInputType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                _firstErrorNode ??= _emailFocus;
                return 'Enter your email';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(v.trim())) {
                _firstErrorNode ??= _emailFocus;
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          _buildField(
            'Phone',
            _phoneController,
            Icons.phone_outlined,
            focusNode: _phoneFocus,
            readOnly: true,
            textInputType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                _firstErrorNode ??= _phoneFocus;
                return 'Please enter your phone number';
              }

              final pattern = r'^\+[1-9]\d{6,14}$';
              final regExp = RegExp(pattern);

              if (!regExp.hasMatch(v.trim())) {
                _firstErrorNode ??= _phoneFocus;
                return 'Enter a valid number with country code\n(e.g. +15551234567)';
              }

              return null;
            },
          ),
          if (!isDoctor) ...[
            _buildField(
              'Address',
              _addressController,
              Icons.place_outlined,
              focusNode: _addressFocus,
              readOnly: !_isEditing,
            ),
            _buildField(
              'Age',
              _ageController,
              Icons.cake_outlined,
              readOnly: !_isEditing,
              textInputType: TextInputType.number,
            ),
            _buildGenderDropdown(),
          ],
          if (isDoctor) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Professional Details'),
            _buildField(
              'Specialty',
              _specialtyController,
              Icons.local_hospital_outlined,
              focusNode: _specialtyFocus,
              readOnly: !_isEditing,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  _firstErrorNode ??= _specialtyFocus;
                  return 'Enter your specialty';
                }
                return null;
              },
            ),
            _buildField(
              'City',
              _cityController,
              Icons.location_city_outlined,
              focusNode: _cityFocus,
              readOnly: !_isEditing,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  _firstErrorNode ??= _cityFocus;
                  return 'Enter your city';
                }
                return null;
              },
            ),
            _buildField(
              'Qualifications',
              _credentialsController,
              Icons.school_outlined,
              focusNode: _credentialsFocus,
              readOnly: !_isEditing,
            ),
            _buildField(
              'Experience (Years)',
              _experienceController,
              Icons.timeline,
              focusNode: _experienceFocus,
              readOnly: !_isEditing,
              textInputType: TextInputType.number,
            ),
            _buildField(
              'Consultation Fee (\$)',
              _feeController,
              Icons.payments_outlined,
              focusNode: _feeFocus,
              readOnly: !_isEditing,
              textInputType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return null;
                }

                if (double.tryParse(v.trim()) == null) {
                  _firstErrorNode ??= _feeFocus;
                  return 'Enter a valid number';
                }

                return null;
              },
            ),
            _buildField(
              'Biography',
              _bioController,
              Icons.description_outlined,
              focusNode: _bioFocus,
              readOnly: !_isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityToggle(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon, {
        FocusNode? focusNode,
        bool readOnly = false,
        TextInputType? textInputType,
        String? Function(String?)? validator,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: true,
            readOnly: readOnly,
            keyboardType: textInputType,
            style: AppTypography.bodyLarge,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: AppColors.mediumBlue,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.lightBlue,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.lightBlue,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.deepBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: readOnly
                  ? AppColors.iceBlue.withOpacity(0.3)
                  : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IgnorePointer(
        ignoring: !_isEditing,
        child: DropdownButtonFormField<String>(
          value: _gender.isNotEmpty ? _gender : null,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.mediumBlue),
          decoration: InputDecoration(
            hintText: 'Gender',
            hintStyle: AppTypography.bodyMedium,
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.mediumBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBlue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBlue),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
            ),
            fillColor: _isEditing ? null : AppColors.lightBlue.withValues(alpha: 0.1),
            filled: !_isEditing,
          ),
          validator: (v) => v == null || v.isEmpty ? 'Please select a gender' : null,
          items: ['Male', 'Female', 'Other'].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e, style: AppTypography.bodyLarge),
            );
          }).toList(),
          onChanged: (v) => setState(() => _gender = v ?? ''),
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Available for consultations today',
          style: AppTypography.bodyMedium,
        ),
        Switch(
          value: _availableToday,
          activeThumbColor: AppColors.deepBlue,
          onChanged: _isEditing
              ? (v) => setState(() => _availableToday = v)
              : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDoctor) {
    return Column(
      children: [
        if (_isEditing) ...[
          Row(
            children: [
              Expanded(
                child: SharedButton(
                  label: 'Save Changes',
                  icon: Icons.save_outlined,
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () => _saveProfile(isDoctor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(
              color: Colors.red,
            ),
            minimumSize: const Size(
              double.infinity,
              50,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (file == null) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    setState(() {
      _uploadingPhoto = true;
    });

    try {
      final bytes = await file.readAsBytes();

      final ref = FirebaseStorage.instance.ref().child(
        'profile_photos/$uid/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final url = await ref.getDownloadURL();

      if (!mounted) {
        return;
      }

      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });

      AppModal.showSuccess(
        context,
        'Photo uploaded successfully.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _uploadingPhoto = false;
      });

      AppModal.showError(
        context,
        'Failed to upload photo. Please try again.',
      );
    }
  }

  Future<void> _saveProfile(bool isDoctor) async {
    _firstErrorNode = null;

    if (!_formKey.currentState!.validate()) {
      if (_firstErrorNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final node = _firstErrorNode;

          if (node == null || node.context == null) {
            return;
          }

          FocusScope.of(context).requestFocus(node);

          Scrollable.ensureVisible(
            node.context!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.2,
          );
        });
      }

      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authService = AuthService();
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    if (await authService.isEmailRegistered(_emailController.text.trim(), excludeUid: userUid)) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppModal.showError(context, 'This email is already registered to another account.');
      }
      return;
    }

    if (await authService.isPhoneRegistered(_phoneController.text.trim(), excludeUid: userUid)) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppModal.showError(context, 'This phone number is already registered to another account.');
      }
      return;
    }

    final service = ref.read(profileServiceProvider);
    bool success = false;

    try {
      final patientUpdate = await service.updatePatientProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photo: _photoUrl,
        gender: _gender,
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        isOnboardingComplete: true,
      );

      if (!patientUpdate) {
        throw Exception('Failed to update personal info');
      }

      if (isDoctor) {
        final doctorUpdate = await service.updateDoctorProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          specialty: _specialtyController.text.trim(),
          city: _cityController.text.trim(),
          bio: _bioController.text.trim(),
          fee: double.tryParse(_feeController.text.trim()) ?? 0,
          experience: int.tryParse(_experienceController.text.trim()) ?? 0,
          qualifications: _credentialsController.text.trim(),
          photo: _photoUrl,
          availableToday: _availableToday,
          slots: _currentSlots,
          availableDays: _currentAvailableDays,
          consultationDuration: _currentDuration,
          businessStartHour: _businessStartHour,
          businessEndHour: _businessEndHour,
          isOnboardingComplete: true,
        );

        success = doctorUpdate;
      } else {
        success = patientUpdate;
      }

      if (!success) {
        throw Exception('Failed to update profile');
      }

      ref.invalidate(userProfileProvider);
      ref.invalidate(userDocProvider);

      if (isDoctor) {
        ref.invalidate(doctorProfileProvider);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      AppModal.showSuccess(
        context,
        'Profile updated successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      AppModal.showError(
        context,
        'Failed to update profile. Please try again.',
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }
}