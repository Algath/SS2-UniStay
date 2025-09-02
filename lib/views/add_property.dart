import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unistay/viewmodels/add_property_vm.dart';
import 'package:unistay/widgets/property_form_card.dart';
import 'package:unistay/widgets/address_autocomplete.dart';
import 'package:unistay/widgets/amenities_selector.dart';
import 'package:unistay/widgets/photo_picker_widget.dart';
import 'package:unistay/widgets/availability_calendar.dart';

class AddPropertyPage extends StatefulWidget {
  static const route = '/add-property';
  const AddPropertyPage({super.key});

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
      create: (_) => AddPropertyViewModel(),
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
                          _buildSaveButton(vm),
                          PropertyFormCard.buildSpacing(isTablet: isTablet, isLandscape: isLandscape),
                          _buildAvailabilitySection(vm, isTablet, isLandscape),
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
      title: const Text(
        'Add Property',
        style: TextStyle(
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
            DropdownButtonFormField<String>(
              value: vm.type,
              decoration: PropertyFormCard.getInputDecoration('Property Type *'),
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
            : const Text(
          'Save Property',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(AddPropertyViewModel vm) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear any previous error
    vm.clearError();

    final success = await vm.saveProperty();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Failed to save property'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}