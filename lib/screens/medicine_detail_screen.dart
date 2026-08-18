import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../providers/cart_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../layouts/responsive_layout.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  const MedicineDetailScreen({super.key});

  @override
  ConsumerState<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  int _quantity = 1;
  bool _qtySynced = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! MedicineModel) {
      return const ResponsiveLayout(
        currentRoute: '/medicine-detail',
        showFooter: false,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: Center(
            child: Text('No medicine data found.'),
          ),
        ),
      );
    }

    final medicine = args;
    final cart = ref.watch(cartProvider);
    final inCart = cart.any((item) => item.medicine.id == medicine.id);
    final cartQty = inCart
        ? cart.firstWhere((item) => item.medicine.id == medicine.id).quantity
        : 0;

    if (!_qtySynced) {
      _quantity = inCart ? cartQty : 1;
      _qtySynced = true;
    }

    final totalPrice = medicine.price * _quantity;

    return ResponsiveLayout(
      currentRoute: '/medicine-detail',
      showFooter: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        // appBar: AppBar(
        //   backgroundColor: AppColors.white,
        //   elevation: 0,
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back, color: AppColors.deepBlue),
        //     onPressed: () => Navigator.pop(context),
        //   ),
        //   // title: Text('Medicine Details', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
        //   // centerTitle: true,
        //   actions: [
        //     IconButton(
        //       icon: Stack(
        //         clipBehavior: Clip.none,
        //         children: [
        //           const Icon(Icons.shopping_cart_outlined, color: AppColors.deepBlue),
        //           if (cart.isNotEmpty)
        //             Positioned(
        //               right: -6,
        //               top: -6,
        //               child: Container(
        //                 padding: const EdgeInsets.all(4),
        //                 decoration: const BoxDecoration(
        //                   color: AppColors.error,
        //                   shape: BoxShape.circle,
        //                 ),
        //                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        //                 child: Text(
        //                   '${cart.length}',
        //                   textAlign: TextAlign.center,
        //                   style: AppTypography.bodyMedium.copyWith(
        //                     fontSize: 8,
        //                     color: AppColors.white,
        //                     fontWeight: FontWeight.bold,
        //                   ),
        //                 ),
        //               ),
        //             ),
        //         ],
        //       ),
        //       onPressed: () => Navigator.pushNamed(context, '/cart'),
        //     ),
        //     const SizedBox(width: 8),
        //   ],
        // ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                          border: Border.all(
                            color: AppColors.lightBlue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepBlue.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: medicine.image.isNotEmpty && medicine.image.startsWith('http')
                              ? Image.network(
                                  medicine.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppColors.iceBlue,
                                    child: const Icon(Icons.medication, color: AppColors.deepBlue, size: 70),
                                  ),
                                )
                              : Container(
                                  color: AppColors.iceBlue,
                                  child: const Icon(Icons.medication, color: AppColors.deepBlue, size: 70),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                      Row(
                      children: [
                        if (medicine.requiresPrescription)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long, size: 12, color: Colors.orange.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  'Prescription Required (Rx)',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 10,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (medicine.requiresPrescription) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: medicine.stock > 0
                                ? Colors.green.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            medicine.stock > 0 ? 'In Stock' : 'Out of Stock',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 10,
                              color: medicine.stock > 0 ? Colors.green.shade800 : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      medicine.name,
                      style: AppTypography.titleLarge.copyWith(fontSize: 22, color: AppColors.darkNavy),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          medicine.brand,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.mediumBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 6, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Text(
                          medicine.category,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Description & Indications',
                      style: AppTypography.titleLarge.copyWith(fontSize: 16, color: AppColors.deepBlue),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FCFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.mediumBlue.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        medicine.description.isNotEmpty
                            ? medicine.description
                            : 'No product description available. Always consult with a registered medical practitioner before starting any medication.',
                        style: AppTypography.bodyMedium.copyWith(
                          height: 1.5,
                          color: AppColors.darkNavy.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: AppColors.iceBlue, width: 1.5),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Price',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey),
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 22,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    if (medicine.stock > 0) ...[
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.iceBlue.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.mediumBlue.withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: Icon(
                                Icons.remove,
                                color: _quantity > 1 ? AppColors.deepBlue : AppColors.grey,
                                size: 16,
                              ),
                            ),
                            Text(
                              '$_quantity',
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBlue,
                              ),
                            ),
                            IconButton(
                              onPressed: _quantity < medicine.stock
                                  ? () => setState(() => _quantity++)
                                  : null,
                              icon: Icon(
                                Icons.add,
                                color: _quantity < medicine.stock ? AppColors.deepBlue : AppColors.grey,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final cartNotifier = ref.read(cartProvider.notifier);
                          if (inCart) {
                            cartNotifier.updateQuantity(medicine.id, _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cart updated successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            cartNotifier.add(medicine);
                            if (_quantity > 1) {
                              cartNotifier.updateQuantity(medicine.id, _quantity);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${medicine.name} added to cart!'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: AppColors.iceBlue,
                                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                          minimumSize: const Size(120, 44),
                        ),
                        child: Text(
                          inCart ? 'Update Cart' : 'Add to Cart',
                          style: AppTypography.buttonText.copyWith(fontSize: 14),
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Temporarily Unavailable',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
