import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../components/button.dart';
import '../components/modal.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
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

  bool _isSaving = false;
  bool _availableToday = true;
  bool _synced = false;
  bool _uploadingPhoto = false;
  bool _isEditing = false;
  String _photoUrl = '';

  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _focusNodes = [];
  FocusNode? _firstErrorNode;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _credentialsController.dispose();
    _specialtyController.dispose();
    _feeController.dispose();
    _scrollController.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _clearFocusNodes() {
    for (final node in _focusNodes) {
      node.unfocus();
      node.dispose();
    }
    _focusNodes.clear();
  }

  FocusNode _createFocusNode() {
    final node = FocusNode();
    _focusNodes.add(node);
    return node;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final userDocAsync = ref.watch(userDocProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('Please log in to view your profile.'));
        }
        return userDocAsync.when(
          data: (doc) {
            if (!_synced) {
              _synced = true;
              _nameController.text = doc?['name'] ?? profile.name;
              _emailController.text = profile.email;
              _phoneController.text = doc?['phone'] ?? '';
              _addressController.text = doc?['address'] ?? '';
              _photoUrl = doc?['photo'] ?? '';
              _credentialsController.text = doc?['credentials'] ?? '';
              _specialtyController.text = doc?['specialty'] ?? '';
              _feeController.text = doc?['fee']?.toString() ?? '';
              _availableToday = doc?['availableToday'] ?? true;
            }

            final isDoctor = profile.role == 2;
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAvatarHeader(profile.name, isDoctor),
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
          error: (err, stack) => const Center(child: Text('Failed to load profile')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
      error: (err, stack) => const Center(child: Text('Failed to load profile')),
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
                border: Border.all(color: AppColors.iceBlue, width: 4),
              ),
              child: ClipOval(
                child: _photoUrl.isNotEmpty
                    ? Image.network(
                  _photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
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
                      : const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTypography.displayLarge.copyWith(fontSize: 22)),
        Text(
          isDoctor ? 'Doctor' : 'Patient',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.mediumBlue),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _formKey.currentState?.validate();
              for (final node in _focusNodes) {
                node.unfocus();
              }
            });
          } else {
            setState(() {
              _isEditing = true;
              _firstErrorNode = null;
            });
          }
        },
        icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, size: 18),
        label: Text(_isEditing ? 'Cancel Editing' : 'Edit Profile'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          side: const BorderSide(color: AppColors.deepBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildInfoFields(bool isDoctor) {
    _clearFocusNodes();

    final nameFocus = _createFocusNode();
    final phoneFocus = _createFocusNode();
    final addressFocus = _createFocusNode();
    final specialtyFocus = _createFocusNode();
    final credentialsFocus = _createFocusNode();
    final feeFocus = _createFocusNode();

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
            focusNode: nameFocus,
            readOnly: !_isEditing,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                _firstErrorNode ??= nameFocus;
                return 'Enter your name';
              }
              return null;
            },
          ),
          _buildField(
            'Email (read-only)',
            _emailController,
            Icons.email_outlined,
            focusNode: null,
            readOnly: true,
          ),
          _buildField(
            'Phone',
            _phoneController,
            Icons.phone_outlined,
            focusNode: phoneFocus,
            readOnly: !_isEditing,
            textInputType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final pattern = r'^\+?[0-9]{10,15}$';
              final regExp = RegExp(pattern);
              if (!regExp.hasMatch(v.trim())) {
                _firstErrorNode ??= phoneFocus;
                return 'Enter 10-15 digits, optionally with +';
              }
              return null;
            },
          ),
          if (!isDoctor)
            _buildField(
              'Address',
              _addressController,
              Icons.place_outlined,
              focusNode: addressFocus,
              readOnly: !_isEditing,
            ),

          if (isDoctor) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Professional Details'),
            _buildField(
              'Specialty',
              _specialtyController,
              Icons.local_hospital_outlined,
              focusNode: specialtyFocus,
              readOnly: !_isEditing,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  _firstErrorNode ??= specialtyFocus;
                  return 'Enter your specialty';
                }
                return null;
              },
            ),
            _buildField(
              'Credentials',
              _credentialsController,
              Icons.school_outlined,
              focusNode: credentialsFocus,
              readOnly: !_isEditing,
            ),
            _buildField(
              'Consultation Fee (\$)',
              _feeController,
              Icons.payments_outlined,
              focusNode: feeFocus,
              readOnly: !_isEditing,
              textInputType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) {
                  _firstErrorNode ??= feeFocus;
                  return 'Enter a valid number';
                }
                return null;
              },
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
            enabled: true, // always enabled so backspace works
            readOnly: readOnly,
            keyboardType: textInputType,
            style: AppTypography.bodyLarge,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.mediumBlue),
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
              filled: true,
              fillColor: readOnly ? AppColors.iceBlue.withOpacity(0.3) : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Available for consultations today', style: AppTypography.bodyMedium),
        Switch(
          value: _availableToday,
          activeThumbColor: AppColors.deepBlue,
          onChanged: _isEditing ? (v) => setState(() => _availableToday = v) : null,
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
                  onPressed: _isSaving ? null : () => _saveProfile(isDoctor),
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
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 18, color: Colors.red),
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
    if (file == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref('profile_photos/$uid/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
      AppModal.showSuccess(context, 'Photo uploaded successfully.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      AppModal.showError(context, 'Failed to upload photo. Please try again.');
    }
  }

  Future<void> _saveProfile(bool isDoctor) async {
    _firstErrorNode = null;

    if (!_formKey.currentState!.validate()) {
      if (_firstErrorNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_firstErrorNode);
          Scrollable.ensureVisible(
            _firstErrorNode!.context!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.2,
          );
        });
      }
      return;
    }

    setState(() => _isSaving = true);

    final service = ref.read(profileServiceProvider);
    final bool success;
    if (isDoctor) {
      success = await service.updateDoctorProfile(
        name: _nameController.text.trim(),
        specialty: _specialtyController.text.trim(),
        fee: double.tryParse(_feeController.text.trim()) ?? 0,
        credentials: _credentialsController.text.trim(),
        photo: _photoUrl,
        availableToday: _availableToday,
      );
    } else {
      success = await service.updatePatientProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photo: _photoUrl,
      );
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
      _synced = false;
    });

    if (success) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(userDocProvider);
      AppModal.showSuccess(context, 'Profile updated successfully.');
    } else {
      AppModal.showError(context, 'Failed to update profile. Please try again.');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}