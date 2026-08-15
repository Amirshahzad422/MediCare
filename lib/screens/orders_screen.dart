import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/empty_state.dart';
import '../components/loader.dart';
import '../layouts/responsive_layout.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../providers/medicines_provider.dart';
import '../providers/orders_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const List<({String label, List<String> statuses})> _groups = [
    (label: 'All', statuses: []),
    (label: 'Placed', statuses: ['Placed', 'placed']),
    (label: 'Packed', statuses: ['Packed', 'packed']),
    (label: 'Shipped', statuses: ['Shipped', 'shipped']),
    (label: 'Delivered', statuses: ['Delivered', 'delivered']),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return DefaultTabController(
      length: _groups.length,
      child: ResponsiveLayout(
        currentRoute: '/orders',
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text('My Orders', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: EdgeInsets.symmetric(horizontal: 16),
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.deepBlue,
                  labelColor: AppColors.deepBlue,
                  unselectedLabelColor: AppColors.grey,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Placed'),
                    Tab(text: 'Packed'),
                    Tab(text: 'Shipped'),
                    Tab(text: 'Delivered'),
                  ],
                ),
              ),
            ),
          ),
          body: ordersAsync.when(
            data: (orders) {
              final mappedOrders = orders.map((data) {
                return OrderModel.fromMap(data, data['id'] ?? '');
              }).toList();

              return TabBarView(
                children: _groups.map((group) {
                  final filtered = group.label == 'All'
                      ? mappedOrders
                      : mappedOrders
                          .where((order) => group.statuses.contains(order.status))
                          .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No ${group.label.toLowerCase()} orders',
                      subtitle: 'Orders in this stage will appear here.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _OrderCard(order: filtered[index]);
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingIndicator(),
            error: (err, stack) => const EmptyState(
              icon: Icons.cloud_off,
              title: 'Failed to load orders',
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.orderNo}',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(fontSize: 15),
                    ),
                    Text(
                      _formatDate(order.createdAt),
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.iceBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 10,
                    color: AppColors.deepBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatusTimeline(currentStatus: order.status),
          const SizedBox(height: 16),
          ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${item.name}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          if (order.items.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '+${order.items.length - 3} more items',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTypography.bodyLarge),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 16,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetail(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepBlue,
                    side: const BorderSide(color: AppColors.lightBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Order Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reorder(ref, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.replay, size: 18, color: Colors.white),
                  label: const Text('Reorder'),
                ),
              ),
            ],
          ),
          if (order.status != 'Delivered') ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _advanceStatus(context),
                icon: const Icon(Icons.speed, size: 16, color: AppColors.mediumBlue),
                label: Text(
                  'Simulate Next Status Update',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mediumBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _advanceStatus(BuildContext context) async {
    final statuses = OrderModel.statusFlow;
    final currentIndex = statuses.indexOf(order.status);
    if (currentIndex < statuses.length - 1) {
      final nextStatus = statuses[currentIndex + 1];
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .update({'status': nextStatus});
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ${order.orderNo}',
                style: AppTypography.titleLarge.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(order.createdAt)} • ${order.paymentMethod}',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Delivery Address', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(order.address, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              Text('Items', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity} × ${item.name}',
                          style: AppTypography.bodyMedium,
                        ),
                        Text(
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 28),
              _detailRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
              if (order.discount > 0)
                _detailRow(
                  'Discount',
                  '-\$${order.discount.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Total', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
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
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
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

  void _reorder(WidgetRef ref, BuildContext context) {
    final cartNotifier = ref.read(cartProvider.notifier);
    _addToCartFromOrder(ref, context, cartNotifier);
  }

  Future<void> _addToCartFromOrder(
      WidgetRef ref, BuildContext context, CartNotifier notifier) async {
    final medicines = await ref.read(medicinesOnceProvider.future);
    bool added = false;
    for (final item in order.items) {
      final match = medicines.where((m) => m.name == item.name).toList();
      if (match.isNotEmpty) {
        notifier.add(match.first, qty: item.quantity);
        added = true;
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added
            ? 'Added items to your cart. Review in the cart screen.'
            : 'Pharmacist stock unavailable for this order.'),
        backgroundColor: added ? AppColors.deepBlue : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (added) {
      Navigator.pushNamed(context, '/cart');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentIndex = OrderModel.statusFlow.indexOf(currentStatus);

    return Row(
      children: List.generate(OrderModel.statusFlow.length, (index) {
        final label = OrderModel.statusFlow[index];
        final reached = index <= currentIndex;
        final isLast = index == OrderModel.statusFlow.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  _statusDot(reached, index == currentIndex),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentIndex
                            ? AppColors.deepBlue
                            : AppColors.iceBlue,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 9,
                  color: reached ? AppColors.deepBlue : AppColors.grey,
                  fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statusDot(bool reached, bool isCurrent) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: reached ? AppColors.deepBlue : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: reached ? AppColors.deepBlue : AppColors.lightBlue,
          width: 2,
        ),
      ),
      child: isCurrent
          ? const Center(
              child: Icon(Icons.check, size: 9, color: AppColors.white),
            )
          : null,
    );
  }
}