import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  String? _secretKey;
  bool _isInitialized = false;

  Future<void> initializeStripe() async {
    if (_isInitialized) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('appSettings').doc('stripe').get();
      if (!doc.exists) {
        throw Exception("Stripe keys not found in Firestore.");
      }

      final data = doc.data()!;
      final pubKey = data['publishableKey'] ?? '';
      _secretKey = data['secretKey'] ?? '';

      if (pubKey.isEmpty || _secretKey!.isEmpty) {
        throw Exception("Stripe keys are empty.");
      }

      Stripe.publishableKey = pubKey;
      Stripe.merchantIdentifier = 'com.example.medi_care';
      await Stripe.instance.applySettings();
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> processPayment(double amount, {String currency = 'USD'}) async {
    try {
      await initializeStripe();

      final int amountInCents = (amount * 100).round();

      final paymentIntentData = await _createPaymentIntent(amountInCents, currency);
      
      if (paymentIntentData == null) {
        throw Exception("Failed to create PaymentIntent");
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'MediCare',
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF1E3A8A), 
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;

    } on StripeException catch (e) {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(int amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card'
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (err) {
      return null;
    }
  }
}
