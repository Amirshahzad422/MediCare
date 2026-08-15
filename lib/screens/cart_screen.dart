import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/button.dart';
import '../components/empty_state.dart';
import '../components/modal.dart';
import '../layouts/responsive_layout.dart';
import '../providers/cart_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();
  bool _isPromoApplied = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo(CartNotifier notifier) {
    if (_promoController.text.trim().toUpperCase() == CartNotifier.promoCode) {
      setState(() => _isPromoApplied = true);
      AppModal.showSuccess(context, 'Promo code applied — \$10 off!');
    } else {
      AppModal.showError(context, 'Invalid promo code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(cartProvider.notifier);
    final cart = ref.watch(cartProvider);

    final subtotal = notifier.subtotal;
    final discount = _isPromoApplied ? CartNotifier.promoDiscount : 0.0;
    final deliveryFee = cart.isEmpty ? 0.0 : 4.99;
    final total = subtotal - discount + deliveryFee;

    return ResponsiveLayout(
      currentRoute: '/cart',
      child: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse the pharmacy and add medicines to get started.',
              actionLabel: 'Go to Pharmacy',
              onAction: () => Navigator.pushNamed(context, '/pharmacy'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'My Cart (${notifier.totalItems} items)',
                        style: AppTypography.titleLarge.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      ...cart.map((item) => _cartTile(item: item)),
                      const SizedBox(height: 12),
                      _promoSection(),
                      const SizedBox(height: 24),
                      Text('Price Summary', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                      const SizedBox(height: 12),
                      _summaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                      _summaryRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                      if (discount > 0)
                        _summaryRow(
                          'Promo Discount',
                          '-\$${discount.toStringAsFixed(2)}',
                          highlight: Colors.green,
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 20,
                              color: AppColors.deepBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SharedButton(
                    label: 'Proceed to Checkout',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/checkout',
                        arguments: {
                          'isPromoApplied': _isPromoApplied,
                          'discount': discount,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _cartTile({required CartItem item}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.medicine.image.isNotEmpty && item.medicine.image.startsWith('http')
                ? Image.network(
                    item.medicine.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.iceBlue,
                      child: const Icon(Icons.medication, color: AppColors.deepBlue),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: AppColors.iceBlue,
                    child: const Icon(Icons.medication, color: AppColors.deepBlue),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(fontSize: 14),
                ),
                Text(
                  '\$${item.medicine.price.toStringAsFixed(2)} each',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.iceBlue.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () =>
                      ref.read(cartProvider.notifier).decrement(item.medicine.id),
                  icon: const Icon(Icons.remove, color: AppColors.deepBlue, size: 18),
                ),
                Text(
                  '${item.quantity}',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    if (item.quantity < item.medicine.stock) {
                      ref.read(cartProvider.notifier).increment(item.medicine.id);
                    }
                  },
                  icon: const Icon(Icons.add, color: AppColors.deepBlue, size: 18),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => ref.read(cartProvider.notifier).remove(item.medicine.id),
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _promoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              enabled: !_isPromoApplied,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Promo code (try MEDICARE10)',
                hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 12),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.lightBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.lightBlue),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SharedButton(
            label: _isPromoApplied ? 'Applied' : 'Apply',
            variant: ButtonVariant.primary,
            width: 96,
            height: 42,
            expanded: false,
            onPressed: _isPromoApplied
                ? null
                : () => _applyPromo(ref.read(cartProvider.notifier)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? highlight}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyLarge),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(color: highlight),
          ),
        ],
      ),
    );
  }
}
