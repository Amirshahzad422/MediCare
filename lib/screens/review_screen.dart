import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../components/button.dart';
import '../providers/review_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(userProfileProvider).value;
    final isDoctor = profile?.role == 2;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          isDoctor ? 'My Reviews' : 'Write a Review',
          style: AppTypography.titleLarge.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isDoctor && user != null)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.deepBlue),
              onPressed: () => _showAddReviewBottomSheet(context),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login to view reviews.'))
          : isDoctor
          ? _buildDoctorReviews(user.uid)
          : _buildPatientContent(context),
    );
  }

  Widget _buildDoctorReviews(String doctorId) {
    final reviewsAsync = ref.watch(doctorReviewsProvider(doctorId));
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: AppColors.lightBlue),
                const SizedBox(height: 16),
                Text('No reviews yet', style: AppTypography.bodyLarge),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.iceBlue),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.deepBlue,
                child: Text(
                  review.rating.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                review.patientName,
                style: AppTypography.titleLarge.copyWith(fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.comment, style: AppTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(review.createdAt),
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.mediumBlue),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
      error: (err, stack) => Center(child: Text('Error loading reviews', style: AppTypography.bodyLarge)),
    );
  }

  Widget _buildPatientContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 64, color: AppColors.lightBlue),
          const SizedBox(height: 16),
          Text('You haven\'t written any reviews yet.', style: AppTypography.bodyLarge),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddReviewBottomSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Write a Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const AddReviewSheet(),
    );
  }
}

class AddReviewSheet extends ConsumerStatefulWidget {
  const AddReviewSheet({super.key});

  @override
  ConsumerState<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<AddReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _doctorIdController = TextEditingController();
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _doctorIdController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Write a Review', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor ID', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _doctorIdController,
                  style: AppTypography.bodyLarge,
                  decoration: _inputDecoration('Enter doctor ID'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Doctor ID required' : null,
                ),
                const SizedBox(height: 12),
                Text('Rating', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text('Comment', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _commentController,
                  style: AppTypography.bodyLarge,
                  maxLines: 3,
                  decoration: _inputDecoration('Write your review...'),
                ),
                const SizedBox(height: 20),
                SharedButton(
                  label: 'Submit Review',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitReview,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.lightBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final service = ref.read(reviewServiceProvider);
    try {
      await service.addReview(
        doctorId: _doctorIdController.text.trim(),
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}