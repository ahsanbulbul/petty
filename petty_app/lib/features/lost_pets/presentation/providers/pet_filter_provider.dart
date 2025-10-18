import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet_filter.dart';

final petFilterProvider = StateNotifierProvider<PetFilterNotifier, PetFilter>((ref) {
  return PetFilterNotifier();
});

class PetFilterNotifier extends StateNotifier<PetFilter> {
  PetFilterNotifier() : super(const PetFilter());

  void setLostFilter(bool? isLost) {
    state = state.copyWith(isLost: () => isLost);
  }

  void setGenderFilter(String? gender) {
    state = state.copyWith(gender: () => gender);
  }

  void setPetTypeFilter(String? petType) {
    state = state.copyWith(petType: () => petType);
  }

  void setTimeFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startTime: () => start,
      endTime: () => end,
    );
  }

  void clearFilters() {
    state = const PetFilter();
  }
}