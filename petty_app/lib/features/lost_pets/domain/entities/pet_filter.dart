class PetFilter {
  final bool? isLost; // null means show both
  final String? gender; // null means show both
  final String? petType;
  final DateTime? startTime;
  final DateTime? endTime;

  const PetFilter({
    this.isLost,
    this.gender,
    this.petType,
    this.startTime,
    this.endTime,
  });

  PetFilter copyWith({
    bool? Function()? isLost,
    String? Function()? gender,
    String? Function()? petType,
    DateTime? Function()? startTime,
    DateTime? Function()? endTime,
  }) {
    return PetFilter(
      isLost: isLost != null ? isLost() : this.isLost,
      gender: gender != null ? gender() : this.gender,
      petType: petType != null ? petType() : this.petType,
      startTime: startTime != null ? startTime() : this.startTime,
      endTime: endTime != null ? endTime() : this.endTime,
    );
  }

  // Check if any filter is active
  bool get isActive => isLost != null || 
    gender != null || 
    petType != null || 
    startTime != null || 
    endTime != null;
}