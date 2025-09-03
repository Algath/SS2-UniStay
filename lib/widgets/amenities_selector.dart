import 'package:flutter/material.dart';

class AmenitiesSelector extends StatefulWidget {
  final Map<String, bool> amenities;
  final Function(String, bool) onAmenityChanged;
  final List<String>? customAmenities;

  const AmenitiesSelector({
    super.key,
    required this.amenities,
    required this.onAmenityChanged,
    this.customAmenities,
  });

  @override
  State<AmenitiesSelector> createState() => _AmenitiesSelectorState();
}

class _AmenitiesSelectorState extends State<AmenitiesSelector> {
  static const List<String> _defaultAmenities = [
    'Internet',
    'Private bathroom',
    'Kitchen access',
    'Parking',
  ];

  List<String> get _availableAmenities {
    if (widget.customAmenities != null) {
      return widget.customAmenities!;
    }
    return _defaultAmenities;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select all available amenities:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        _buildAmenitiesGrid(),
        const SizedBox(height: 16),
        _buildSelectedAmenitiesSummary(),
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableAmenities.map((amenity) {
        final isSelected = widget.amenities[amenity] ?? false;
        return _buildAmenityChip(amenity, isSelected);
      }).toList(),
    );
  }

  Widget _buildAmenityChip(String amenity, bool isSelected) {
    return FilterChip(
      label: Text(
        amenity,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        widget.onAmenityChanged(amenity, selected);
      },
      selectedColor: Colors.blue[50],
      checkmarkColor: Colors.blue[700],
      showCheckmark: true,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildSelectedAmenitiesSummary() {
    final selectedAmenities = widget.amenities.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedAmenities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Text(
              'No amenities selected',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Selected amenities (${selectedAmenities.length})',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: selectedAmenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  amenity,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Helper method to get selected amenities as a list
  static List<String> getSelectedAmenities(Map<String, bool> amenities) {
    return amenities.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Helper method to validate amenities selection
  static String? validateAmenities(Map<String, bool> amenities) {
    final selectedCount = amenities.values.where((selected) => selected).length;

    if (selectedCount == 0) {
      return 'Please select at least one amenity';
    }

    if (selectedCount > 15) {
      return 'Please select no more than 15 amenities';
    }

    return null; // No validation errors
  }
}