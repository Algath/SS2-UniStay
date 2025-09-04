import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unistay/viewmodels/add_property_vm.dart';
import 'package:unistay/widgets/property_form_card.dart';
import 'package:unistay/widgets/address_autocomplete.dart';
import 'package:unistay/widgets/amenities_selector.dart';
import 'package:unistay/widgets/photo_picker_widget.dart';
import 'package:unistay/widgets/availability_calendar.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/services/price_prediction_service.dart';

class AddPropertyPage extends StatefulWidget {
  static const route = '/add-property';
  final String? propertyId; // For edit mode
  
  const AddPropertyPage({
    super.key,
    this.propertyId,
  });

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = AddPropertyViewModel();
        // Load property data if in edit mode
        if (widget.propertyId != null) {
          vm.loadPropertyForEdit(widget.propertyId!);
        }
        return vm;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = isTablet
                  ? (isLandscape ? constraints.maxWidth * 0.8 : constraints.maxWidth * 0.9)
                  : double.infinity;

              return Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Consumer<AddPropertyViewModel>(
                    builder: (context, vm, _) => Form(
                      key: _formKey,
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? (isLandscape ? 48 : 32) : 20,
                          vertical: isTablet ? 32 : 24,
                        ),
                        children: [
                          _buildBasicInformationSection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildLocationSection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildPropertyDetailsSection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildAmenitiesSection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildDescriptionSection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildPhotosSection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildAvailabilitySection(vm, isTablet, isLandscape),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildSaveButton(vm),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2C3E50),
      elevation: 0,
      foregroundColor: Colors.white,
      title: Text(
        widget.propertyId != null ? 'Edit Property' : 'Add Property',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBasicInformationSection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Basic Information',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        PropertyFormCard.buildFormField(
          controller: vm.titleController,
          label: 'Property Title *',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        ),
        const SizedBox(height: 16),
        PropertyFormCard.buildResponsiveRow(
          children: [
            PropertyFormCard.buildFormField(
              controller: vm.priceController,
              label: 'Price (CHF/month) *',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final price = num.tryParse(v);
                if (price == null) return 'Enter valid number';
                return null;
              },
            ),
            // Removed predict button to avoid overflow; keep only price and type
            DropdownButtonFormField<String>(
              value: vm.type,
              decoration: PropertyFormCard.getInputDecoration('Property Type *'),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'room', child: Text('Single room')),
                DropdownMenuItem(value: 'whole', child: Text('Whole property')),
              ],
              onChanged: (v) => vm.setType(v ?? 'room'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Location',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        AddressAutocompleteField(
          streetController: vm.streetController,
          houseNumberController: vm.houseNumberController,
          cityController: vm.cityController,
          postcodeController: vm.postcodeController,
          onAddressSelected: vm.setAddress,
          onLocationSelected: vm.setPosition,
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsSection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Property Details',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        PropertyFormCard.buildResponsiveRow(
          children: [
            PropertyFormCard.buildFormField(
              controller: vm.sizeSqmController,
              label: 'Size (m²) *',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final size = int.tryParse(v);
                if (size == null) return 'Enter valid number';
                return null;
              },
            ),
            PropertyFormCard.buildFormField(
              controller: vm.roomsController,
              label: 'Number of Rooms *',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final rooms = int.tryParse(v);
                if (rooms == null) return 'Enter valid number';
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        PropertyFormCard.buildResponsiveRow(
          children: [
            PropertyFormCard.buildFormField(
              controller: vm.bathroomsController,
              label: 'Number of Bathrooms *',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final baths = int.tryParse(v);
                if (baths == null) return 'Enter valid number';
                return null;
              },
            ),
            Container(), // Spacer for consistent layout
          ],
        ),
        const SizedBox(height: 16),
        PropertyFormCard.buildToggleSwitch(
          title: 'Furnished',
          subtitle: vm.furnished ? 'Property is furnished' : 'Property is unfurnished',
          value: vm.furnished,
          onChanged: vm.setFurnished,
        ),
        const SizedBox(height: 12),
        PropertyFormCard.buildToggleSwitch(
          title: 'Charges Included',
          subtitle: vm.utilitiesIncluded
              ? 'Charges are included in price'
              : 'Charges paid separately',
          value: vm.utilitiesIncluded,
          onChanged: vm.setUtilitiesIncluded,
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Amenities',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        AmenitiesSelector(
          amenities: vm.amenities,
          onAmenityChanged: vm.updateAmenity,
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Description',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        PropertyFormCard.buildFormField(
          controller: vm.descriptionController,
          label: 'Property Description *',
          maxLines: 4,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().length < 10) return 'Description should be at least 10 characters';
            if (v.trim().length > 500) return 'Description should be less than 500 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotosSection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Photos',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        PhotoPickerWidget(
          uploadedPhotoUrls: vm.photoUrls,
          onPhotosChanged: vm.setPhotoUrls,
          maxPhotos: 3,
          showPhotoCount: true,
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(AddPropertyViewModel vm, bool isTablet, bool isLandscape) {
    return PropertyFormCard(
      title: 'Availability *',
      isTablet: isTablet,
      isLandscape: isLandscape,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isTablet ? (isLandscape ? 520 : 480) : 440,
          ),
          child: AvailabilityCalendar(
            onRangesSelected: vm.setAvailabilityRanges,
            initialRanges: vm.availabilityRanges,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AddPropertyViewModel vm) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E56CF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: vm.isSaving ? null : () => _handleSave(vm),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: vm.isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          widget.propertyId != null ? 'Update Property' : 'Save Property',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(AddPropertyViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    // 1) Fiyat tahmini dene, kullanıcıya inceleme penceresi göster
    final predicted = await _predictPriceIfPossible(vm);
    final accepted = await _showPriceReviewDialog(vm, predicted);
    if (accepted != true) return; // kullanıcı iptal etti

    // 2) Kaydet
    vm.clearError();
    final success = await vm.saveProperty();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.propertyId != null ? 'Property updated successfully!' : 'Property saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? (widget.propertyId != null ? 'Failed to update property' : 'Failed to save property')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<double?> _predictPriceIfPossible(AddPropertyViewModel vm) async {
    try {
      // Create a temporary Room object to use PricePredictionService
      // This ensures consistency with property detail page
      final tempRoom = Room(
        id: '',
        title: vm.titleController.text,
        price: num.tryParse(vm.priceController.text) ?? 0,
        street: vm.streetController.text,
        houseNumber: vm.houseNumberController.text,
        city: vm.cityController.text,
        postcode: vm.postcodeController.text,
        type: vm.type,
        furnished: vm.furnished,
        sizeSqm: int.tryParse(vm.sizeSqmController.text) ?? 0,
        rooms: int.tryParse(vm.roomsController.text) ?? 1,
        bathrooms: int.tryParse(vm.bathroomsController.text) ?? 1,
        description: vm.descriptionController.text,
        lat: 0.0,
        lng: 0.0,
        ownerUid: '',
        photoUrls: vm.photoUrls,
        walkMins: 10,
        utilitiesIncluded: vm.utilitiesIncluded,
        amenities: vm.selectedAmenities,
        availabilityRanges: vm.availabilityRanges,
      );

      // Use the same service as property detail page
      return await PricePredictionService().predictPrice(tempRoom);
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _showPriceReviewDialog(AddPropertyViewModel vm, double? predicted) async {
    final ctrl = TextEditingController(
      text: predicted != null ? predicted.toStringAsFixed(0) : vm.priceController.text,
    );
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Price Comparison'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (predicted != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF28A745), Color(0xFF20C997)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Price',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'CHF ${vm.priceController.text.isEmpty ? "0" : vm.priceController.text}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '/month',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFD7E14), Color(0xFFFF8C42)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Predicted Price',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'CHF ${predicted.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '/month',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Final listing price (CHF)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final val = num.tryParse(ctrl.text.trim());
                if (val != null) {
                  vm.priceController.text = val.toString();
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save and publish'),
            ),
          ],
        );
      },
    );
  }
}