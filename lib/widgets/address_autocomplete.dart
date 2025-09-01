import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:unistay/models/address_suggestion.dart';
import 'package:unistay/services/address_service.dart';
import 'package:unistay/widgets/property_form_card.dart';

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController streetController;
  final TextEditingController houseNumberController;
  final TextEditingController cityController;
  final TextEditingController postcodeController;
  final Function(AddressSuggestion) onAddressSelected;
  final Function(ll.LatLng) onLocationSelected;

  const AddressAutocompleteField({
    super.key,
    required this.streetController,
    required this.houseNumberController,
    required this.cityController,
    required this.postcodeController,
    required this.onAddressSelected,
    required this.onLocationSelected,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  List<AddressSuggestion> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        // Hide suggestions when focus is lost (with delay to allow for selection)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddresses(query);
    });
  }

  Future<void> _searchAddresses(String query) async {
    if (query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final suggestions = await AddressService.searchAddresses(query);

      if (mounted) {
        setState(() {
          _addressSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isSearchingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressSuggestions = [];
          _showSuggestions = false;
          _isSearchingAddress = false;
        });
      }
    }
  }

  void _selectAddress(AddressSuggestion suggestion) {
    setState(() {
      // Update individual controllers
      widget.streetController.text = suggestion.road ?? suggestion.displayName;
      widget.houseNumberController.text = suggestion.houseNumber ?? '';
      widget.cityController.text = suggestion.city ?? '';
      widget.postcodeController.text = suggestion.postcode ?? '';

      // Clear search field and hide suggestions
      _searchController.clear();
      _showSuggestions = false;
    });

    // Notify parent widgets
    widget.onAddressSelected(suggestion);
    widget.onLocationSelected(ll.LatLng(suggestion.lat, suggestion.lon));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Address Search Field
            PropertyFormCard.buildFormField(
              controller: _searchController,
              label: 'Search Swiss addresses (optional)',
              hintText: 'Start typing to search for addresses...',
              suffixIcon: _isSearchingAddress
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : const Icon(Icons.search),
              onChanged: _onAddressChanged,
            ),

            const SizedBox(height: 16),

            // Address Suggestions Dropdown
            if (_showSuggestions && _addressSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _addressSuggestions.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final suggestion = _addressSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      title: Text(
                        suggestion.displayName,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectAddress(suggestion),
                    );
                  },
                ),
              ),

            // Manual Address Input Fields
            PropertyFormCard.buildResponsiveRow(
              children: [
                PropertyFormCard.buildFormField(
                  controller: widget.streetController,
                  label: 'Street *',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                PropertyFormCard.buildFormField(
                  controller: widget.houseNumberController,
                  label: 'No. *',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              flex: [3, 1],
            ),

            const SizedBox(height: 16),

            PropertyFormCard.buildResponsiveRow(
              children: [
                PropertyFormCard.buildFormField(
                  controller: widget.cityController,
                  label: 'City *',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                PropertyFormCard.buildFormField(
                  controller: widget.postcodeController,
                  label: 'Postcode *',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              flex: [2, 1],
            ),
          ],
        ),
      ],
    );
  }
}