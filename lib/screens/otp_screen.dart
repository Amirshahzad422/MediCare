import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/button.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../services/auth_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _forceResendingToken;
  
  Map<String, dynamic>? _registrationData;
  bool _initializedFromArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('phone')) {
        _phoneController.text = args['phone'];
        if (args['isRegistrationFlow'] == true) {
          _registrationData = args;
        }
        _initializedFromArgs = true;
        _codeSent = true; // Instantly show OTP UI
        // Schedule request code after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestCode();
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // If it's a login flow (not registration), verify the phone exists in DB FIRST.
    if (_registrationData == null) {
      final authService = AuthService();
      final isRegistered = await authService.isPhoneRegistered(phone);
      if (!isRegistered) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This number is not registered. Please register first.')),
          );
        }
        return;
      }
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential, phone);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.message}')),
            );
          }
        },
        codeSent: (verificationId, forceResendingToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _forceResendingToken = forceResendingToken;
              _codeSent = true;
              _isLoading = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        forceResendingToken: _forceResendingToken,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send code. Please try again.')),
        );
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential, String phone) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // We are already logged in (e.g., came from Registration).
        // Link the phone credential to this account.
        try {
          await currentUser.linkWithCredential(credential);
        } catch (e) {
          // Ignore if already linked
        }
        await _savePhoneNumber(phone);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number verified successfully!')),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // Logging in via "Continue with Phone"
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          await _savePhoneNumber(phone);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged in successfully!')),
            );
            
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            if (doc.exists) {
              final role = doc.data()?['role'] ?? 1;
              bool onboardingComplete = false;
              if (role == 2) {
                final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
                onboardingComplete = doctorDoc.data()?['isOnboardingComplete'] == true;
              } else {
                final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(user.uid).get();
                onboardingComplete = patientDoc.data()?['isOnboardingComplete'] == true;
              }
              if (!onboardingComplete) {
                final route = role == 2 ? '/doctor-onboarding' : '/patient-onboarding';
                Navigator.pushReplacementNamed(context, route);
              } else {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed. Please try again.')),
        );
      }
    }
  }



  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6‑digit code.')),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No verification in progress. Request a new code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      
      if (_registrationData != null) {
        _registrationData!['phone'] = _phoneController.text.trim(); // Update in case user changed it on this screen after a failed send
        final authService = AuthService();
        await authService.registerWithVerifiedPhone(credential, _registrationData!);
        if (mounted) {
          // Invalidate profile providers so they fetch the newly created Firestore document
          ref.invalidate(userProfileProvider);
          ref.invalidate(userDocProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          final role = _registrationData!['role'];
          final route = role == 2 ? '/doctor-onboarding' : '/patient-onboarding';
          Navigator.pushReplacementNamed(context, route);
        }
      } else {
        await _signInWithCredential(credential, _phoneController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    }
  }

  Future<void> _savePhoneNumber(String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      final existingDoc = query.docs.first;
      if (existingDoc.id != user.uid) {
        throw Exception('This phone number is already registered to another user.');
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'phone': phone}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          size: 42,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _codeSent ? 'Enter Verification Code' : 'Verify Your Number',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.white,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _codeSent 
                            ? 'We have sent a 6-digit code to your phone.' 
                            : 'We will send a 6-digit code to verify your device.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.iceBlue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _codeSent ? 'Enter OTP' : 'Phone Number',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 22,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _codeSent ? _codeController : _phoneController,
                        enabled: !_codeSent || !_isLoading,
                        keyboardType: _codeSent ? TextInputType.number : TextInputType.phone,
                        maxLength: _codeSent ? 6 : 15,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 22,
                          letterSpacing: _codeSent ? 8 : 0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: _codeSent ? '------' : '+92 300 1234567',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: Colors.black26,
                            letterSpacing: _codeSent ? 8 : 0,
                          ),
                          prefixIcon: _codeSent
                              ? null
                              : const Icon(Icons.phone_outlined, color: AppColors.mediumBlue),
                          counterText: '',
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
                      ),
                      const SizedBox(height: 28),
                      SharedButton(
                        label: _codeSent ? 'Verify OTP' : 'Send Code',
                        icon: _codeSent ? Icons.verified_outlined : Icons.send_outlined,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : (_codeSent ? _verify : _requestCode),
                      ),
                      const SizedBox(height: 16),
                      if (_codeSent)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                if (_registrationData != null) {
                                  Navigator.pop(context); // Go back to register screen
                                } else {
                                  setState(() {
                                    _codeSent = false;
                                    _codeController.clear();
                                    _verificationId = null;
                                  });
                                }
                              },
                              child: Text(
                                'Change Phone',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.mediumBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _requestCode();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code resent to your phone.')),
                                );
                              },
                              child: Text(
                                'Resend Code',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.mediumBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (!_codeSent)
                        TextButton(
                          onPressed: () {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/dashboard', (route) => false);
                            } else {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          child: Text(
                            'Continue without verification',
                            style: AppTypography.bodyMedium.copyWith(color: Colors.black38),
                          ),
                        ),
                    ],
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