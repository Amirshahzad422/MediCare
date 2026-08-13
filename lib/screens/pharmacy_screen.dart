import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/empty_state.dart';
import '../components/loader.dart';
import '../models/medicine_model.dart';
import '../providers/cart_provider.dart';
import '../providers/medicines_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  List<String> get _categories => const [
        'All',
        'Analgesics',
        'Antibiotics',
        'Antipyretics',
        'Antacids',
        'Vitamins',
        'Cough & Cold',
        'First Aid',
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final totalItems = ref.watch(cartProvider.notifier).totalItems;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Pharmacy', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.deepBlue),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$totalItems',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.white, fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value.toLowerCase()),
                      style: AppTypography.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Search medicines...',
                        hintStyle: TextStyle(color: AppColors.lightBlue),
                        prefixIcon: Icon(Icons.search, color: AppColors.mediumBlue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _CartButton(
                  itemCount: totalItems,
                  onTap: () => Navigator.pushNamed(context, '/cart'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.deepBlue : AppColors.iceBlue.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.deepBlue : AppColors.lightBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: AppTypography.bodyMedium.copyWith(
                          color: selected ? AppColors.white : AppColors.deepBlue,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: medicinesAsync.when(
              data: (medicines) {
                final filtered = medicines.where((med) {
                  final matchesQuery = med.name.toLowerCase().contains(_query) ||
                      med.brand.toLowerCase().contains(_query) ||
                      med.category.toLowerCase().contains(_query);
                  final matchesCategory = _selectedCategory == 'All' ||
                      med.category == _selectedCategory;
                  return matchesQuery && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No medicines found',
                    subtitle: 'Try a different search or category.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isGrid = constraints.maxWidth >= 700;
                    if (isGrid) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _MedicineCard(medicine: filtered[index]),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _MedicineCard(
                        medicine: filtered[index],
                        horizontal: true,
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (err, stack) => EmptyState(
                icon: Icons.cloud_off,
                title: 'Failed to load medicines',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(medicinesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;

  const _CartButton({required this.itemCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(Icons.shopping_cart_outlined, color: AppColors.white),
            ),
            if (itemCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    '$itemCount',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 10,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends ConsumerWidget {
  final MedicineModel medicine;
  final bool horizontal;

  const _MedicineCard({required this.medicine, this.horizontal = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = horizontal
        ? Row(
            children: [
              _medicineImage(size: 72),
              const SizedBox(width: 12),
              Expanded(child: _infoColumn(context)),
              _addControls(ref),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _medicineImage(size: 84)),
              const SizedBox(height: 10),
              Expanded(child: _infoColumn(context)),
              const SizedBox(height: 8),
              _priceRow(ref),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _medicineImage({required double size}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        medicine.image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.iceBlue,
          child: const Icon(Icons.medication, color: AppColors.deepBlue, size: 30),
        ),
      ),
    );
  }

  Widget _infoColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (medicine.requiresPrescription)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rx',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 9,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              medicine.category,
              style: AppTypography.bodyMedium.copyWith(fontSize: 10),
            ),
          ],
        ),
        Text(
          medicine.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleLarge.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          medicine.brand,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _priceRow(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '\$${medicine.price.toStringAsFixed(2)}',
          style: AppTypography.titleLarge.copyWith(
            fontSize: 16,
            color: AppColors.deepBlue,
          ),
        ),
        _addControls(ref),
      ],
    );
  }

  Widget _addControls(WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inCart = cart.any((item) => item.medicine.id == medicine.id);
    final qty = inCart
        ? cart.firstWhere((item) => item.medicine.id == medicine.id).quantity
        : 0;

    if (!inCart) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          tooltip: 'Add to cart',
          onPressed: () => ref.read(cartProvider.notifier).add(medicine),
          icon: const Icon(Icons.add, color: AppColors.white, size: 20),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).decrement(medicine.id),
            icon: const Icon(Icons.remove, color: AppColors.deepBlue, size: 18),
          ),
          Text('$qty', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () {
              if (qty < medicine.stock) {
                ref.read(cartProvider.notifier).increment(medicine.id);
              }
            },
            icon: const Icon(Icons.add, color: AppColors.deepBlue, size: 18),
          ),
        ],
      ),
    );
  }
}