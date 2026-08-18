import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'button.dart';

enum DoctorSort { newest, feeLowToHigh, feeHighToLow, mostBooked }

enum AvailabilityFilter { any, today, thisWeek }

enum GenderFilter { any, male, female }

class DoctorFilterState {
  final String keyword;
  final String specialty;
  final String city;
  final RangeValues feeRange;
  final double minRating;
  final int minExperience;
  final AvailabilityFilter availability;
  final GenderFilter gender;
  final DoctorSort sort;

  const DoctorFilterState({
    this.keyword = '',
    this.specialty = 'All Specialties',
    this.city = 'All Cities',
    this.feeRange = const RangeValues(0, 5000),
    this.minRating = 0,
    this.minExperience = 0,
    this.availability = AvailabilityFilter.any,
    this.gender = GenderFilter.any,
    this.sort = DoctorSort.mostBooked,
  });

  DoctorFilterState copyWith({
    String? keyword,
    String? specialty,
    String? city,
    RangeValues? feeRange,
    double? minRating,
    int? minExperience,
    AvailabilityFilter? availability,
    GenderFilter? gender,
    DoctorSort? sort,
  }) {
    return DoctorFilterState(
      keyword: keyword ?? this.keyword,
      specialty: specialty ?? this.specialty,
      city: city ?? this.city,
      feeRange: feeRange ?? this.feeRange,
      minRating: minRating ?? this.minRating,
      minExperience: minExperience ?? this.minExperience,
      availability: availability ?? this.availability,
      gender: gender ?? this.gender,
      sort: sort ?? this.sort,
    );
  }

  bool get isActive {
    return keyword.isNotEmpty ||
        specialty != 'All Specialties' ||
        city != 'All Cities' ||
        feeRange != const RangeValues(0, 5000) ||
        minRating > 0 ||
        minExperience > 0 ||
        availability != AvailabilityFilter.any ||
        gender != GenderFilter.any;
  }

  static const List<String> specialties = [
    'All Specialties',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Gynecologist',
    'Orthopedic',
    'Psychiatrist',
    'Ophthalmologist',
    'Endocrinologist',
    'Dentist',
    'General Physician',
  ];

  static const List<String> cities = [
    'All Cities',
    'New York',
    'Los Angeles',
    'Chicago',
    'San Francisco',
    'Boston',
    'Houston',
    'Seattle',
    'Miami',
  ];

  static const List<DoctorSort> sortOptions = [
    DoctorSort.mostBooked,
    DoctorSort.newest,
    DoctorSort.feeLowToHigh,
    DoctorSort.feeHighToLow,
  ];
}

class FiltersPanel extends StatefulWidget {
  final DoctorFilterState initial;
  final List<String> specialties;
  final List<String> cities;
  final ValueChanged<DoctorFilterState> onApply;
  final VoidCallback onReset;

  const FiltersPanel({
    super.key,
    required this.initial,
    required this.onApply,
    required this.onReset,
    this.specialties = const [],
    this.cities = const [],
  });

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late String _keyword;
  late String _specialty;
  late String _city;
  late RangeValues _feeRange;
  late double _minRating;
  late int _minExperience;
  late AvailabilityFilter _availability;
  late GenderFilter _gender;
  late DoctorSort _sort;

  List<String> get _specialties =>
      widget.specialties.isEmpty ? DoctorFilterState.specialties : widget.specialties;

  List<String> get _cities =>
      widget.cities.isEmpty ? DoctorFilterState.cities : widget.cities;

  @override
  void initState() {
    super.initState();
    _copyFrom(widget.initial);
  }

  void _copyFrom(DoctorFilterState s) {
    _keyword = s.keyword;
    _specialty = s.specialty;
    _city = s.city;
    _feeRange = s.feeRange;
    _minRating = s.minRating;
    _minExperience = s.minExperience;
    _availability = s.availability;
    _gender = s.gender;
    _sort = s.sort;
  }

  DoctorFilterState _state() {
    return DoctorFilterState(
      keyword: _keyword,
      specialty: _specialty,
      city: _city,
      feeRange: _feeRange,
      minRating: _minRating,
      minExperience: _minExperience,
      availability: _availability,
      gender: _gender,
      sort: _sort,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters & Sort', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
              TextButton(
                onPressed: () {
                  widget.onApply(const DoctorFilterState());
                },
                child: Text(
                  'Reset',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Keyword'),
          TextField(
            controller: TextEditingController(text: _keyword),
            onChanged: (v) => _keyword = v,
            style: AppTypography.bodyLarge,
            decoration: _inputDecoration(
              hint: 'Search by name or symptom...',
              icon: Icons.search,
            ),
          ),
          const SizedBox(height: 20),
          _label('Specialty'),
          _dropdown<String>(
            value: _specialty,
            items: _specialties,
            onChanged: (v) => setState(() => _specialty = v),
          ),
          const SizedBox(height: 20),
          _label('City'),
          _dropdown<String>(
            value: _city,
            items: _cities,
            onChanged: (v) => setState(() => _city = v),
          ),
          const SizedBox(height: 24),
          _label('Consultation Fee Range'),
          RangeSlider(
            values: _feeRange,
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppColors.deepBlue,
            inactiveColor: AppColors.iceBlue,
            labels: RangeLabels(
              '\$${_feeRange.start.toStringAsFixed(0)}',
              '\$${_feeRange.end.toStringAsFixed(0)}',
            ),
            onChanged: (v) => setState(() => _feeRange = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${_feeRange.start.toStringAsFixed(0)}', style: AppTypography.bodyMedium),
              Text('\$${_feeRange.end.toStringAsFixed(0)}', style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Minimum Rating'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<double>(
                      initialValue: _minRating,
                      isExpanded: true,
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.darkNavy),
                      decoration: _inputDecoration(hint: '', icon: Icons.star_border),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Any rating')),
                        DropdownMenuItem(value: 3.5, child: Text('3.5+')),
                        DropdownMenuItem(value: 4.0, child: Text('4.0+')),
                        DropdownMenuItem(value: 4.5, child: Text('4.5+')),
                      ],
                      onChanged: (v) => setState(() => _minRating = v ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Experience'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _minExperience,
                      isExpanded: true,
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.darkNavy),
                      decoration: _inputDecoration(hint: '', icon: Icons.work_outline),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Any')),
                        DropdownMenuItem(value: 5, child: Text('5+ Yrs')),
                        DropdownMenuItem(value: 10, child: Text('10+ Yrs')),
                        DropdownMenuItem(value: 15, child: Text('15+ Yrs')),
                      ],
                      onChanged: (v) => setState(() => _minExperience = v ?? 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _label('Availability'),
          const SizedBox(height: 8),
          _chipRow<AvailabilityFilter>(
            options: const [
              (AvailabilityFilter.any, 'Any Day'),
              (AvailabilityFilter.today, 'Today'),
              (AvailabilityFilter.thisWeek, 'This Week'),
            ],
            selected: _availability,
            onSelect: (v) => setState(() => _availability = v),
          ),
          const SizedBox(height: 24),
          _label('Sort By'),
          const SizedBox(height: 8),
          DropdownButtonFormField<DoctorSort>(
            initialValue: _sort,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.darkNavy),
            decoration: _inputDecoration(hint: '', icon: Icons.sort),
            items: const [
              DropdownMenuItem(value: DoctorSort.mostBooked, child: Text('Most Booked')),
              DropdownMenuItem(value: DoctorSort.newest, child: Text('Newest')),
              DropdownMenuItem(value: DoctorSort.feeLowToHigh, child: Text('Fee: Low to High')),
              DropdownMenuItem(value: DoctorSort.feeHighToLow, child: Text('Fee: High to Low')),
            ],
            onChanged: (v) => setState(() => _sort = v ?? DoctorSort.mostBooked),
          ),
          const SizedBox(height: 28),
          SharedButton(
            label: 'Apply Filters',
            onPressed: () => widget.onApply(_state()),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkNavy),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium,
      prefixIcon: Icon(icon, color: AppColors.mediumBlue, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.darkNavy),
      decoration: _inputDecoration(hint: '', icon: Icons.arrow_drop_down),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _chipRow<T>({
    required List<(T, String)> options,
    required T selected,
    required ValueChanged<T> onSelect,
  }) {
    return Row(
      children: options.map((entry) {
        final (value, label) = entry;
        final isSelected = value == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepBlue : AppColors.iceBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.deepBlue : AppColors.lightBlue.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12,
                  color: isSelected ? AppColors.white : AppColors.deepBlue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}