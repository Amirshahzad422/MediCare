import 'package:flutter/material.dart';
import '../components/button.dart';
import '../components/modal.dart';
import '../layouts/responsive_layout.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isSending = false);
      AppModal.showSuccess(context, 'Message sent! Our team will get back to you shortly.');
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/contact',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact Us', style: AppTypography.displayLarge.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                Text(
                  'We would love to hear from you. Drop us a message or reach out through any channel below.',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.lightBlue),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    final info = _officeInfo();
                    final form = _messageForm();

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: info),
                          const SizedBox(width: 28),
                          Expanded(child: form),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [info, const SizedBox(height: 28), form],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _officeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Office & Clinic Info', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
        const SizedBox(height: 16),
        _infoTile(Icons.place_outlined, 'Address', '730 Mission Street, Suite 400\nSan Francisco, CA 94103'),
        _infoTile(Icons.phone_outlined, 'Phone', '+1 (800) 123-4567\nMon–Sat, 9am–9pm'),
        _infoTile(Icons.mail_outline, 'Email', 'care@medicare.com\nsupport@medicare.com'),
        const SizedBox(height: 20),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.iceBlue.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.iceBlue),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 44, color: AppColors.mediumBlue),
                const SizedBox(height: 8),
                Text('Map preview', style: AppTypography.bodyMedium),
                Text(
                  '730 Mission St, San Francisco',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.deepBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send a Message', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          _input(_nameController, 'Your Name', Icons.person_outline, validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter your name' : null),
          const SizedBox(height: 12),
          _input(_emailController, 'Your Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your email' : null),
          const SizedBox(height: 12),
          _input(
            _messageController,
            'Your message...',
            Icons.message_outlined,
            maxLines: 4,
            validator: (v) => v == null || v.trim().length < 10
                ? 'Message must be at least 10 characters'
                : null,
          ),
          const SizedBox(height: 20),
          SharedButton(
            label: 'Send Message',
            icon: Icons.send_outlined,
            isLoading: _isSending,
            onPressed: _isSending ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTypography.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium,
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
      ),
    );
  }
}