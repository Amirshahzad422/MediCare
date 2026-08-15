import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/button.dart';
import '../components/empty_state.dart';
import '../layouts/responsive_layout.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _paymentMethod = 'Card';
  bool _isProcessing = false;
  bool _addressInitialized = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(
    List<CartItem> cart,
    double subtotal,
    double discount,
    double deliveryFee,
    double total,
  ) async {
    final address = _addressController.text.trim();
    if (address.length < 8) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Invalid Address'),
          content: const Text('Please enter a complete delivery address (at least 8 characters).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 1));

    final orderService = ref.read(orderServiceProvider);
    final order = await orderService.placeOrder(
      items: ref.read(cartProvider.notifier).toOrderItems(),
      subtotal: subtotal + deliveryFee,
      discount: discount,
      total: total,
      address: address,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (order != null) {
      ref.read(cartProvider.notifier).clear();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Payment Successful'),
              ),
            ],
          ),
          content: Text(
            'Order ${order.orderNo} has been placed successfully.\n\n'
            'Track its status from the Orders screen.',
            style: AppTypography.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialIndex': 1}, // Navigate to Appointments screen or main flow
                );
                // Then push /orders route over dashboard
                Navigator.pushNamed(context, '/orders');
              },
              child: Text(
                'Track Order',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.deepBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Order Failed'),
          content: const Text('Failed to place order. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDocAsync = ref.watch(userDocProvider);
    userDocAsync.whenData((userDoc) {
      if (!_addressInitialized && userDoc != null) {
        final address = userDoc['address'] ?? '';
        if (address.isNotEmpty) {
          _addressController.text = address;
        }
        _addressInitialized = true;
      }
    });

    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final discount = args['discount'] as double? ?? 0.0;

    final subtotal = notifier.subtotal;
    final deliveryFee = cart.isEmpty ? 0.0 : 4.99;
    final total = subtotal - discount + deliveryFee;

    if (cart.isEmpty && !_isProcessing) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Cart is empty',
          subtitle: 'Add medicines to proceed to checkout.',
        ),
      );
    }

    return ResponsiveLayout(
      currentRoute: '/checkout',
      showFooter: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.deepBlue),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Checkout', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
          centerTitle: true,
        ),
        body: _isProcessing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.deepBlue),
                    const SizedBox(height: 16),
                    Text(
                      'Processing Payment & Placing Order...',
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Address
                    Text('Delivery Address', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Enter your complete delivery address...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.iceBlue, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.iceBlue, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    Text('Payment Method', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _methodTile('Card', Icons.credit_card),
                        const SizedBox(width: 12),
                        _methodTile('Wallet', Icons.account_balance_wallet),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.iceBlue, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Summary', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                          const Divider(height: 24),
                          ...cart.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity} × ${item.medicine.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '\$${(item.medicine.price * item.quantity).toStringAsFixed(2)}',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 24),
                          _summaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                          _summaryRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                          if (discount > 0)
                            _summaryRow(
                              'Promo Discount',
                              '-\$${discount.toStringAsFixed(2)}',
                              color: Colors.green,
                            ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: AppTypography.titleLarge.copyWith(
                                  fontSize: 18,
                                  color: AppColors.deepBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SharedButton(
                      label: 'Pay & Place Order',
                      onPressed: () => _placeOrder(cart, subtotal, discount, deliveryFee, total),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _methodTile(String label, IconData icon) {
    final selected = _paymentMethod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.deepBlue : AppColors.iceBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.deepBlue : AppColors.iceBlue,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.white : AppColors.deepBlue),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.deepBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
