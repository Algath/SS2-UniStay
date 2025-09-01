#!/bin/bash

# Create directories if they don't exist
echo "Creating directory structure..."

# Ensure we're in the lib directory
if [ ! -d "lib" ]; then
    echo "Error: This script should be run from the Flutter project root directory"
    exit 1
fi

cd lib

# Create directories if they don't exist
mkdir -p models
mkdir -p services
mkdir -p widgets
mkdir -p viewmodels

# Create model files
echo "Creating model files..."
touch models/address_suggestion.dart
touch models/property_data.dart

# Create service files
echo "Creating service files..."
touch services/address_service.dart
touch services/property_service.dart

# Create widget files
echo "Creating widget files..."
touch widgets/property_form_card.dart
touch widgets/address_autocomplete.dart
touch widgets/amenities_selector.dart
touch widgets/photo_picker_widget.dart
touch widgets/availability_calendar.dart

# Create an enhanced viewmodel if it doesn't exist
if [ ! -f "viewmodels/add_property_vm.dart" ]; then
    touch viewmodels/add_property_vm.dart
fi

echo "File structure created successfully!"
echo ""
echo "Files created/verified:"
echo "- models/address_suggestion.dart"
echo "- models/property_data.dart"
echo "- services/address_service.dart"
echo "- services/property_service.dart"
echo "- widgets/property_form_card.dart"
echo "- widgets/address_autocomplete.dart"
echo "- widgets/amenities_selector.dart"
echo "- widgets/photo_picker_widget.dart"
echo "- widgets/availability_calendar.dart"
echo "- viewmodels/add_property_vm.dart"
echo ""
echo "Now you can copy the file contents from Claude's response into each file."