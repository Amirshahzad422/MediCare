import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../components/filters.dart';

/// Notifier that manages the doctor filter state.
class DoctorFilterNotifier extends StateNotifier<DoctorFilterState> {
  DoctorFilterNotifier() : super(DoctorFilterState());

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
  }

  void setSpecialty(String specialty) {
    state = state.copyWith(specialty: specialty);
  }

  void setCity(String city) {
    state = state.copyWith(city: city);
  }

  void setFeeRange(RangeValues feeRange) {
    state = state.copyWith(feeRange: feeRange);
  }

  void setMinRating(double minRating) {
    state = state.copyWith(minRating: minRating);
  }

  void setMinExperience(int minExperience) {
    state = state.copyWith(minExperience: minExperience);
  }

  void setAvailability(AvailabilityFilter availability) {
    state = state.copyWith(availability: availability);
  }

  void setGender(GenderFilter gender) {
    state = state.copyWith(gender: gender);
  }

  void setSort(DoctorSort sort) {
    state = state.copyWith(sort: sort);
  }

  void replace(DoctorFilterState newState) {
    state = newState;
  }

  DoctorFilterState applyFilters() => state;
}

/// Holds the active Doctor filter state for the Doctors screen.
/// Used by the Doctors screen to apply advanced filters and sort criteria.
final doctorFiltersProvider =
    StateNotifierProvider<DoctorFilterNotifier, DoctorFilterState>((ref) {
  return DoctorFilterNotifier();
});