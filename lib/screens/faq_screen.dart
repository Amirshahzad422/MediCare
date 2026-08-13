import 'package:flutter/material.dart';
import '../layouts/responsive_layout.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _expandedIndex;

  static const List<({String q, String a})> _faqs = [
    (
      q: 'How do I book a consultation?',
      a: 'Search for a doctor by specialty or city, open their profile, pick an available date and slot, '
          'choose your consultation type (video, chat or in-person) and complete payment. Your appointment '
          'is confirmed instantly and appears in the Appointments tab.'
    ),
    (
      q: 'How does the video consultation work?',
      a: 'At the scheduled time, open your appointment and tap "Join Consultation". You will enter a live '
          'one-on-one call with mute, camera toggle and in-call chat. Your device camera permission is '
          'required for the first use.'
    ),
    (
      q: 'How do I receive my prescription?',
      a: 'After the consultation, the doctor issues a digital prescription linked to your appointment. '
          'You can view and download it from the Prescriptions screen at any time.'
    ),
    (
      q: 'Can I order medicines from my prescription?',
      a: 'Yes. Open any prescription and tap "Order Prescribed Medicines". The matching items are sent to '
          'your cart — confirm your delivery address and payment, then track the order from the Orders screen.'
    ),
    (
      q: 'How do I get a discount?',
      a: 'Use the promo code MEDICARE10 during checkout for \$10 off your consultation or pharmacy order.'
    ),
    (
      q: 'Can I cancel or reschedule an appointment?',
      a: 'Open the appointment in the Appointments tab. Upcoming appointments can be cancelled, and the '
          'same screen lets you rebook another slot with the doctor.'
    ),
    (
      q: 'Is my medical data secure?',
      a: 'All data is stored in Google Firebase with authentication, role-based access and Firebase '
          'security rules. Only you and the doctors you consult can see your records.'
    ),
    (
      q: 'Which devices are supported?',
      a: 'MediCare is a single Flutter codebase that runs on Android, iOS, web and desktop — your data '
          'and appointments sync across all devices automatically.'
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = _faqs
        .where((faq) =>
            query.isEmpty ||
            faq.q.toLowerCase().contains(query) ||
            faq.a.toLowerCase().contains(query))
        .toList();

    return ResponsiveLayout(
      currentRoute: '/faq',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Frequently Asked Questions', style: AppTypography.displayLarge.copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'Everything you need to know about consultations, prescriptions and orders.',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.lightBlue),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.iceBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: AppTypography.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Search questions...',
                      hintStyle: TextStyle(color: AppColors.lightBlue),
                      prefixIcon: Icon(Icons.search, color: AppColors.mediumBlue),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No questions match your search.', style: AppTypography.bodyLarge),
                    ),
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final faq = entry.value;
                    final isOpen = _expandedIndex == index;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.iceBlue, width: 1.5),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        leading: isOpen
                            ? const Icon(Icons.help, color: AppColors.deepBlue, size: 22)
                            : Icon(Icons.help_outline, color: AppColors.lightBlue, size: 22),
                        title: Text(
                          faq.q,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        iconColor: AppColors.deepBlue,
                        collapsedIconColor: AppColors.lightBlue,
                        onExpansionChanged: (expanded) =>
                            setState(() => _expandedIndex = expanded ? index : null),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq.a,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.darkNavy,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}