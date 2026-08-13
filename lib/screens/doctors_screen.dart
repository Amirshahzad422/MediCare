import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';
import '../components/button.dart';
import '../components/doctor_card.dart';
import '../components/empty_state.dart';
import '../components/filters.dart';
import '../components/loader.dart';
import '../components/modal.dart';
import '../components/search_bar.dart';
import '../providers/doctor_provider.dart';
import '../providers/filters_provider.dart';

import '../styles/colors.dart';
import '../styles/typography.dart';
import '../layouts/responsive_layout.dart';

class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  static const int _pageSize = 6;

  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  int _visibleCount = _pageSize;
  bool _loadingMore = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> _applyFilters(List<DoctorModel> doctors, DoctorFilterState filter) {
    final query = filter.keyword.trim().toLowerCase();

    final filtered = doctors.where((doctor) {
      if (query.isNotEmpty &&
          !doctor.name.toLowerCase().contains(query) &&
          !doctor.specialty.toLowerCase().contains(query) &&
          !doctor.city.toLowerCase().contains(query)) {
        return false;
      }
      if (filter.specialty != 'All Specialties' &&
          doctor.specialty.toLowerCase() != filter.specialty.toLowerCase()) {
        return false;
      }
      if (filter.city != 'All Cities' && doctor.city != filter.city) {
        return false;
      }
      if (doctor.fee < filter.feeRange.start || doctor.fee > filter.feeRange.end) {
        return false;
      }
      if (doctor.rating < filter.minRating) {
        return false;
      }
      if (doctor.experience < filter.minExperience) {
        return false;
      }
      if (filter.availability == AvailabilityFilter.today && !doctor.availableToday) {
        return false;
      }
      if (filter.gender != GenderFilter.any &&
          doctor.gender.toLowerCase() != filter.gender.name.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sort) {
      case DoctorSort.newest:
        filtered.sort((a, b) {
          final aDate = a.createdAt?.toUtc() ?? DateTime(1900);
          final bDate = b.createdAt?.toUtc() ?? DateTime(1900);
          return bDate.compareTo(aDate);
        });
        break;
      case DoctorSort.feeLowToHigh:
        filtered.sort((a, b) => a.fee.compareTo(b.fee));
        break;
      case DoctorSort.feeHighToLow:
        filtered.sort((a, b) => b.fee.compareTo(a.fee));
        break;
      case DoctorSort.mostBooked:
        filtered.sort((a, b) => b.bookedCount.compareTo(a.bookedCount));
        break;
    }
    return filtered;
  }

  Future<void> _openFilters(DoctorFilterState current) async {
    final result = await AppModal.showBottomSheet<DoctorFilterState>(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      child: FiltersPanel(
        initial: current,
        onApply: (state) {
          Navigator.pop(context, state);
        },
        onReset: () {},
      ),
    );
    if (result != null) {
      ref.read(doctorFiltersProvider.notifier).replace(result);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _visibleCount += _pageSize;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsListProvider);
    final filters = ref.watch(doctorFiltersProvider);

    return ResponsiveLayout(
      currentRoute: '/doctors',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(doctorFiltersProvider.notifier)
                          .replace(filters.copyWith(keyword: value));
                    },
                    onFilterTap: () => _openFilters(filters),
                  ),
                ),
                const SizedBox(width: 12),
                _toggleButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (filters.isActive)
                  _activeChip(
                    label: '${filters.specialty != 'All Specialties' ? filters.specialty : filters.city}'
                        '${filters.minRating > 0 ? ' • ${filters.minRating}+★' : ''}',
                    onTap: () => _openFilters(filters),
                  ),
                const Spacer(),
                _sortDropdown(filters),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) {
                final visible = _applyFilters(doctors, filters);
                final page = visible.take(_visibleCount).toList();

                if (visible.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No doctors found',
                    subtitle: filters.isActive
                        ? 'Try adjusting your filters or search query.'
                        : 'Please try again later.',
                    actionLabel: filters.isActive ? 'Reset Filters' : null,
                    onAction: () {
                      if (filters.isActive) {
                        _searchController.clear();
                        ref.read(doctorFiltersProvider.notifier)
                            .replace(const DoctorFilterState());
                      }
                    },
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${visible.length} doctor${visible.length == 1 ? '' : 's'} available',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_isGridView)
                      _grid(visible, page)
                    else
                      _list(visible, page),
                    if (visible.length > _visibleCount) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: SharedButton(
                          label: 'Load More',
                          variant: ButtonVariant.outline,
                          width: 200,
                          height: 48,
                          isLoading: _loadingMore,
                          onPressed: _loadingMore ? null : _loadMore,
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => _isGridView
                  ? const SingleChildScrollView(child: DoctorGridSkeleton())
                  : const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(children: [
                        DoctorCardSkeleton(),
                        SizedBox(height: 16),
                        DoctorCardSkeleton(),
                        SizedBox(height: 16),
                        DoctorCardSkeleton(),
                      ]),
                    ),
              error: (err, stack) => EmptyState(
                icon: Icons.cloud_off,
                title: 'Failed to load doctors',
                subtitle: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(doctorsListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconToggle(Icons.grid_view, _isGridView, () {
            setState(() => _isGridView = true);
          }),
          _iconToggle(Icons.view_list, !_isGridView, () {
            setState(() => _isGridView = false);
          }),
        ],
      ),
    );
  }

  Widget _iconToggle(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.deepBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: active ? AppColors.white : AppColors.deepBlue),
      ),
    );
  }

  Widget _activeChip({required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 11,
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.tune, size: 14, color: AppColors.white),
          ],
        ),
      ),
    );
  }

  Widget _sortDropdown(DoctorFilterState filters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort, size: 16, color: AppColors.mediumBlue),
          SizedBox(
            width: 160,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DoctorSort>(
                value: filters.sort,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.deepBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                items: DoctorFilterState.sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(
                      _sortLabel(option),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(doctorFiltersProvider.notifier)
                        .replace(filters.copyWith(sort: value));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(DoctorSort sort) {
    switch (sort) {
      case DoctorSort.newest:
        return 'Newest';
      case DoctorSort.feeLowToHigh:
        return 'Fee: Low to High';
      case DoctorSort.feeHighToLow:
        return 'Fee: High to Low';
      case DoctorSort.mostBooked:
        return 'Most Booked';
    }
  }

  Widget _grid(List<DoctorModel> all, List<DoctorModel> page) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: page.length,
      itemBuilder: (context, index) => _gridCard(page[index]),
    );
  }

  Widget _list(List<DoctorModel> all, List<DoctorModel> page) {
    return Column(
      children: page.map((doctor) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => _openDoctor(doctor),
            child: DoctorCard(doctor: doctor, onBookTap: () => _openBooking(doctor)),
          ),
        );
      }).toList(),
    );
  }

  Widget _gridCard(DoctorModel doctor) {
    return GestureDetector(
      onTap: () => _openDoctor(doctor),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipOval(
                child: Image.network(
                  doctor.photo,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 84,
                    height: 84,
                    color: AppColors.iceBlue,
                    child: const Icon(Icons.person, color: AppColors.deepBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              doctor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLarge.copyWith(fontSize: 15),
            ),
            Text(
              doctor.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  doctor.rating.toString(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${doctor.experience} Yrs',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${doctor.fee.toStringAsFixed(0)}',
              style: AppTypography.titleLarge.copyWith(
                fontSize: 16,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openBooking(doctor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Book Now',
                  style: AppTypography.buttonText.copyWith(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDoctor(DoctorModel doctor) {
    Navigator.pushNamed(context, '/doctor-details', arguments: doctor);
  }

  void _openBooking(DoctorModel doctor) {
    Navigator.pushNamed(context, '/doctor-details', arguments: doctor);
  }
}