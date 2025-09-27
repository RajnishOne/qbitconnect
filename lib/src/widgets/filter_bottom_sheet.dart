import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qbitconnect/src/utils/local_extensions.dart';

import '../state/app_state_manager.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String selectedFilterType = 'Status'; // Default to Status

  // Temporary filter selections
  String? _tempFilter;
  String? _tempCategory;
  String? _tempSort;
  String? _tempSortDirection;

  @override
  void initState() {
    super.initState();
    // Initialize temporary values with current app state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      _tempFilter = appState.activeFilter;
      _tempCategory = appState.activeCategory;
      _tempSort = appState.activeSort;
      _tempSortDirection = appState.sortDirection;
    });
  }

  void _applyFilters() {
    final appState = context.read<AppState>();

    // Apply the temporary selections
    if (_tempFilter != null && _tempFilter != appState.activeFilter) {
      appState.setFilter(_tempFilter!);
    }
    if (_tempCategory != null && _tempCategory != appState.activeCategory) {
      appState.setCategory(_tempCategory!);
    }
    if (_tempSort != null && _tempSort != appState.activeSort) {
      appState.setSort(_tempSort!);
    }
    if (_tempSortDirection != null &&
        _tempSortDirection != appState.sortDirection) {
      appState.setSortDirection(_tempSortDirection!);
    }

    // Close the bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort & Filter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Two Column Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Section - Filter Types
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FilterTypeItem(
                          title: 'Status',
                          isSelected: selectedFilterType == 'Status',
                          onTap: () =>
                              setState(() => selectedFilterType = 'Status'),
                        ),
                        FilterTypeItem(
                          title: 'Category',
                          isSelected: selectedFilterType == 'Category',
                          onTap: () =>
                              setState(() => selectedFilterType = 'Category'),
                        ),
                        FilterTypeItem(
                          title: 'Sort',
                          isSelected: selectedFilterType == 'Sort',
                          onTap: () =>
                              setState(() => selectedFilterType = 'Sort'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Section - Filter Options
                  Expanded(
                    child: selectedFilterType == 'Status'
                        ? StatusFilters(
                            appState: appState,
                            tempFilter: _tempFilter,
                            onFilterChanged: (filter) =>
                                setState(() => _tempFilter = filter),
                          )
                        : selectedFilterType == 'Category'
                        ? CategoryFilters(
                            appState: appState,
                            tempCategory: _tempCategory,
                            onCategoryChanged: (category) =>
                                setState(() => _tempCategory = category),
                          )
                        : SortOptions(
                            appState: appState,
                            tempSort: _tempSort,
                            tempSortDirection: _tempSortDirection,
                            onSortChanged: (sort) =>
                                setState(() => _tempSort = sort),
                            onSortDirectionChanged: (direction) =>
                                setState(() => _tempSortDirection = direction),
                          ),
                  ),
                ],
              ),
            ),
            // Apply Filter Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: Text('Apply Filter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterTypeItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterTypeItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                )
              : Border(left: BorderSide(color: Colors.transparent, width: 3)),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class StatusFilters extends StatelessWidget {
  final AppState appState;
  final String? tempFilter;
  final Function(String) onFilterChanged;

  const StatusFilters({
    super.key,
    required this.appState,
    required this.tempFilter,
    required this.onFilterChanged,
  });

  Widget _buildCustomRadio(
    BuildContext context,
    String value,
    String? selectedValue,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 12,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              ...appState.filterCounts.entries.map((entry) {
                return ListTile(
                  title: Text('${entry.key.capitalize()} (${entry.value})'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: _buildCustomRadio(
                    context,
                    entry.key,
                    tempFilter ?? appState.activeFilter,
                  ),
                  onTap: () => onFilterChanged(entry.key),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoryFilters extends StatelessWidget {
  final AppState appState;
  final String? tempCategory;
  final Function(String) onCategoryChanged;

  const CategoryFilters({
    super.key,
    required this.appState,
    required this.tempCategory,
    required this.onCategoryChanged,
  });

  Widget _buildCustomRadio(
    BuildContext context,
    String value,
    String? selectedValue,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onCategoryChanged(value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 12,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              ListTile(
                title: Text('all (${appState.categoryCounts['all'] ?? 0})'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: _buildCustomRadio(
                  context,
                  'all',
                  tempCategory ?? appState.activeCategory,
                ),
                onTap: () => onCategoryChanged('all'),
              ),
              ...appState.allCategories.map((category) {
                final count = appState.categoryCounts[category] ?? 0;
                return ListTile(
                  title: Text('$category ($count)'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: _buildCustomRadio(
                    context,
                    category,
                    tempCategory ?? appState.activeCategory,
                  ),
                  onTap: () => onCategoryChanged(category),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class SortOptions extends StatelessWidget {
  final AppState appState;
  final String? tempSort;
  final String? tempSortDirection;
  final Function(String) onSortChanged;
  final Function(String) onSortDirectionChanged;

  const SortOptions({
    super.key,
    required this.appState,
    required this.tempSort,
    required this.tempSortDirection,
    required this.onSortChanged,
    required this.onSortDirectionChanged,
  });

  Widget _buildCustomRadio(
    BuildContext context,
    String value,
    String? selectedValue,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onSortChanged(value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 12,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'value': 'name', 'label': 'Name'},
      {'value': 'size', 'label': 'Size'},
      {'value': 'progress', 'label': 'Progress'},
      {'value': 'dlspeed', 'label': 'Download Speed'},
      {'value': 'upspeed', 'label': 'Upload Speed'},
      {'value': 'priority', 'label': 'Priority'},
      {'value': 'num_seeds', 'label': 'Seeds'},
      {'value': 'num_leechs', 'label': 'Peers'},
      {'value': 'ratio', 'label': 'Ratio'},
      {'value': 'eta', 'label': 'ETA'},
      {'value': 'state', 'label': 'State'},
      {'value': 'added_on', 'label': 'Added Date'},
      {'value': 'completion_on', 'label': 'Completion Date'},
    ];

    final currentSort = tempSort ?? appState.activeSort;
    final currentSortDirection = tempSortDirection ?? appState.sortDirection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort Direction Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'asc',
                      label: Text('A→Z'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment<String>(
                      value: 'desc',
                      label: Text('Z→A'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {currentSortDirection},
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isNotEmpty) {
                      onSortDirectionChanged(newSelection.first);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.primaryContainer;
                      }
                      return Theme.of(context).colorScheme.surface;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.onPrimaryContainer;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                    side: WidgetStateProperty.resolveWith<BorderSide?>((
                      Set<WidgetState> states,
                    ) {
                      return BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // Sort Field Options
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Sort By:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ...sortOptions.map((option) {
                final isSelected = currentSort == option['value']!;
                return ListTile(
                  title: Text(option['label']!),
                  leading: _buildCustomRadio(
                    context,
                    option['value']!,
                    currentSort,
                  ),
                  trailing: isSelected
                      ? Icon(
                          currentSortDirection == 'asc'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    onSortChanged(option['value']!);
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
