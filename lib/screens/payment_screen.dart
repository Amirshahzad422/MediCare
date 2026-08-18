import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../services/payment_service.dart';
import '../services/profile_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../layouts/responsive_layout.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _promoController = TextEditingController();
  double _discount = 0.0;
  bool _isPromoApplied = false;
  bool _isProcessing = false;
  String? _failureMessage;  

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    double discountAmt = 0.0;
    String msg = '';

    if (code == 'MEDICARE10') {
      discountAmt = 10.0;
      msg = 'Promo Code Applied: \$10 off!';
    } else if (code == 'FIRST20') {
      discountAmt = 20.0;
      msg = 'Promo Code Applied: \$20 off for first-time patients!';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Promo Code'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _discount = discountAmt;
      _isPromoApplied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _processPayment(DoctorModel doctor, DateTime date, String slot, String type, double total) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final paymentSuccess = await PaymentService().processPayment(total);
      if (!paymentSuccess) {
        throw Exception('Payment was declined or cancelled');
      }

      final newAppointment = AppointmentModel(
        id: '',
        patientId: user.uid,
        patientName: user.displayName ?? 'Patient',
        doctorId: doctor.id,
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        slot: slot,
        type: type,
        amount: total,
        status: 1,
        consultationDuration: doctor.consultationDuration,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('appointments').add(newAppointment.toMap());

      await ProfileService().incrementBookedCount(doctor.name);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Booking Confirmed!',
                  style: AppTypography.titleLarge.copyWith(fontSize: 22, color: AppColors.deepBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your appointment with ${doctor.name} on ${date.day}/${date.month}/${date.year} at $slot has been successfully booked.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.mediumBlue, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                      arguments: {'initialIndex': 1, 'appointmentsTabIndex': 1},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('View Appointments', style: AppTypography.buttonText),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failureMessage = 'Payment failed: ${e.toString()}. Please try again.';
        _isProcessing = false;
      });
    } finally {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    if (routeArgs == null || routeArgs is! Map<String, dynamic>) {
      return ResponsiveLayout(
        currentRoute: '/payment',
        child: Scaffold(
          backgroundColor: AppColors.white,
        body: Center(
          child: Text(
            'No booking data found. Please select a slot again.',
            style: AppTypography.bodyLarge,
          ),
        ),
        ),
      );
    }

    final args = routeArgs;
    final doctor = args['doctor'] as DoctorModel;
    final date = args['date'] as DateTime;
    final slot = args['slot'] as String;
    final type = args['type'] as String;

    final subtotal = doctor.fee;
    const bookingFee = 5.0;
    final total = subtotal + bookingFee - _discount;

    return ResponsiveLayout(
      currentRoute: '/payment',
      child: Scaffold(
        backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_failureMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _failureMessage!,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _failureMessage = null),
                      child: const Text('Dismiss & Retry',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.iceBlue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.name, style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                          Text(doctor.specialty, style: AppTypography.bodyMedium),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date & Time', style: AppTypography.bodyMedium),
                              Text(
                                '${date.day}/${date.month}/${date.year} at $slot',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Type', style: AppTypography.bodyMedium),
                              Text(
                                type,
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Promo Code', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _promoController,
                            style: AppTypography.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'Enter code (e.g. MEDICARE10)',
                              hintStyle: TextStyle(color: AppColors.lightBlue),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightBlue)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.deepBlue)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isPromoApplied ? null : _applyPromo,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text('Price Summary', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Consultation Fee', style: AppTypography.bodyLarge),
                        Text('\$${subtotal.toStringAsFixed(2)}', style: AppTypography.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Booking Service Fee', style: AppTypography.bodyLarge),
                        Text('\$5.00', style: AppTypography.bodyLarge),
                      ],
                    ),
                    if (_discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Promo Discount', style: AppTypography.bodyLarge.copyWith(color: Colors.green)),
                          Text('-\$${_discount.toStringAsFixed(2)}', style: AppTypography.bodyLarge.copyWith(color: Colors.green)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
                        Text('\$${total.toStringAsFixed(2)}', style: AppTypography.titleLarge.copyWith(fontSize: 20, color: AppColors.deepBlue)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _processPayment(doctor, date, slot, type, total),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : Text('Pay Now', style: AppTypography.buttonText),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}