import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/button.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _forceResendingToken;

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
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _savePhoneNumber(phone);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number verified successfully!')),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
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
      await _signInWithCredential(credential, _phoneController.text.trim());
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
                        'Verify Your Number',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.white,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We will send a 6-digit code to verify your device.',
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
                        keyboardType: TextInputType.number,
                        maxLength: _codeSent ? 6 : 15,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 22,
                          letterSpacing: _codeSent ? 8 : 0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: _codeSent ? '------' : '+1 555 123 4567',
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
                      TextButton(
                        onPressed: _codeSent
                            ? () => setState(() {
                          _codeSent = false;
                          _codeController.clear();
                          _verificationId = null;
                        })
                            : null,
                        child: Text(
                          _codeSent ? 'Change phone number / Resend' : 'Skip for now',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mediumBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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