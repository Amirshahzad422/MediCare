import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/empty_state.dart';
import '../components/loader.dart';
import '../components/medicine_card.dart';
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

  bool _argumentsProcessed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsProcessed) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List<dynamic>) {
        _addPrescribedMedicinesToCart(args);
      }
      _argumentsProcessed = true;
    }
  }

  Future<void> _addPrescribedMedicinesToCart(List<dynamic> prescribed) async {
    try {
      final catalog = await ref.read(medicinesOnceProvider.future);
      int addedCount = 0;
      for (final item in prescribed) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        final match = catalog.where((m) => m.name.toLowerCase() == name).toList();
        if (match.isNotEmpty) {
          ref.read(cartProvider.notifier).add(match.first);
          addedCount++;
        }
      }
      if (addedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $addedCount prescribed medicine(s) to cart!'),
            backgroundColor: AppColors.deepBlue,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: AppColors.white,
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding prescribed medicines to cart: $e');
    }
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
                            MedicineCard(medicine: filtered[index]),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => MedicineCard(
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
