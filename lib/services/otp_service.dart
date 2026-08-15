import 'dart:convert';
import 'package:http/http.dart' as http;

class OtpService {
  static const String baseUrl = 'http://192.168.1.105:5000';

  static Future<void> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to send OTP');
    }
  }

  static Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Invalid OTP');
    }
  }
}