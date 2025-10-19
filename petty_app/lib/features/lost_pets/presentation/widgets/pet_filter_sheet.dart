import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_filter_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

class PetFilterSheet extends ConsumerWidget {
  const PetFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(petFilterProvider);
    final filterNotifier = ref.read(petFilterProvider.notifier);

    final List<String> petTypes = [
      'Dog', 'Cat', 'Bird', 'Rabbit', 'Hamster', 'Fish', 'Turtle', 'Snake', 
      'Lizard', 'Horse', 'Ferret', 'Guinea Pig', 'Pig', 'Goat', 'Chicken', 
      'Duck', 'Other'
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Filter Pets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Filter
                    Row(
                      children: [
                        Expanded(
                          child: FilterChip(
                            selected: filter.isLost == true,
                            label: const Text('Lost'),
                            onSelected: (selected) {
                              filterNotifier.setLostFilter(
                                  selected ? true : null);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilterChip(
                            selected: filter.isLost == false,
                            label: const Text('Found'),
                            onSelected: (selected) {
                              filterNotifier.setLostFilter(
                                  selected ? false : null);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Gender Filter
                    Row(
                      children: [
                        Expanded(
                          child: FilterChip(
                            selected: filter.gender == 'male',
                            label: const Text('Male'),
                            onSelected: (selected) {
                              filterNotifier.setGenderFilter(
                                  selected ? 'male' : null);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilterChip(
                            selected: filter.gender == 'female',
                            label: const Text('Female'),
                            onSelected: (selected) {
                              filterNotifier.setGenderFilter(
                                  selected ? 'female' : null);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilterChip(
                            selected: filter.gender == 'unsure',
                            label: const Text('Unsure'),
                            onSelected: (selected) {
                              filterNotifier.setGenderFilter(
                                  selected ? 'unsure' : null);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Pet Type Filter
                    DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) => petTypes,
                      selectedItem: filter.petType,
                      onChanged: filterNotifier.setPetTypeFilter,
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Pet Type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: const PopupProps.menu(
                        showSelectedItems: true,
                        showSearchBox: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Time Range Filter
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: filter.startTime ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                filterNotifier.setTimeFilter(date, filter.endTime);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(filter.startTime != null
                                ? '${filter.startTime!.day}/${filter.startTime!.month}/${filter.startTime!.year}'
                                : 'Start Date'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: filter.endTime ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                filterNotifier.setTimeFilter(filter.startTime, date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(filter.endTime != null
                                ? '${filter.endTime!.day}/${filter.endTime!.month}/${filter.endTime!.year}'
                                : 'End Date'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: filterNotifier.clearFilters,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}