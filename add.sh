#!/bin/bash

# Property Detail Page Refactoring - File Creation Script
# Creates all necessary widget files and directories for the refactor

set -e  # Exit on any error

echo "🚀 Creating Property Detail Widget Files..."

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in a Flutter project root directory"
    echo "Please run this script from your Flutter project root"
    exit 1
fi

# Create the property_detail widgets directory
echo "📁 Creating widgets/property_detail directory..."
mkdir -p lib/widgets/property_detail

# Create core widget files
echo "🎨 Creating core widget files..."

# Property Image Widget
touch lib/widgets/property_detail/property_image_widget.dart

# Property Header Widget
touch lib/widgets/property_detail/property_header_widget.dart

# Property Address Widget
touch lib/widgets/property_detail/property_address_widget.dart

# Property Features Widget
touch lib/widgets/property_detail/property_features_widget.dart

# Property Amenities Widget
touch lib/widgets/property_detail/property_amenities_widget.dart

# Property Description Widget
touch lib/widgets/property_detail/property_description_widget.dart

# Availability Widgets
touch lib/widgets/property_detail/availability_calendar_widget.dart
touch lib/widgets/property_detail/availability_summary_widget.dart

# Property Actions Widget
touch lib/widgets/property_detail/property_actions_widget.dart

# Transit/Transport Widgets
echo "🚌 Creating transport widgets..."
touch lib/widgets/property_detail/connections_section_widget.dart
touch lib/widgets/property_detail/itinerary_card_widget.dart

# Utility Widgets
echo "🔧 Creating utility widgets..."
touch lib/widgets/property_detail/feature_row_widget.dart
touch lib/widgets/property_detail/section_header_widget.dart

# Create service file
echo "⚙️ Creating price prediction service..."
touch lib/services/price_prediction_service.dart

# Create index file for easier imports
echo "📦 Creating index file..."
cat > lib/widgets/property_detail/index.dart << 'EOF'
// Property Detail Widgets Index
// Import this file to get access to all property detail widgets

export 'property_image_widget.dart';
export 'property_header_widget.dart';
export 'property_address_widget.dart';
export 'property_features_widget.dart';
export 'property_amenities_widget.dart';
export 'property_description_widget.dart';
export 'availability_calendar_widget.dart';
export 'availability_summary_widget.dart';
export 'property_actions_widget.dart';
export 'connections_section_widget.dart';
export 'itinerary_card_widget.dart';
export 'feature_row_widget.dart';
export 'section_header_widget.dart';
EOF

# Check if availability_calendar.dart exists in widgets/ and needs to be moved
if [ -f "lib/widgets/availability_calendar.dart" ]; then
    echo "📅 Found existing availability_calendar.dart - you may want to:"
    echo "   - Move logic from lib/widgets/availability_calendar.dart"
    echo "   - To lib/widgets/property_detail/availability_calendar_widget.dart"
    echo "   - Then delete the old file"
fi

# Summary
echo ""
echo "✅ Successfully created all widget files!"
echo ""
echo "📋 Created files:"
echo "   lib/widgets/property_detail/"
echo "   ├── property_image_widget.dart"
echo "   ├── property_header_widget.dart"
echo "   ├── property_address_widget.dart"
echo "   ├── property_features_widget.dart"
echo "   ├── property_amenities_widget.dart"
echo "   ├── property_description_widget.dart"
echo "   ├── availability_calendar_widget.dart"
echo "   ├── availability_summary_widget.dart"
echo "   ├── property_actions_widget.dart"
echo "   ├── connections_section_widget.dart"
echo "   ├── itinerary_card_widget.dart"
echo "   ├── feature_row_widget.dart"
echo "   ├── section_header_widget.dart"
echo "   └── index.dart"
echo ""
echo "   lib/services/"
echo "   └── price_prediction_service.dart"
echo ""
echo "🚧 Next steps:"
echo "   1. Start with simple widgets (feature_row_widget.dart, section_header_widget.dart)"
echo "   2. Move logic from property_detail.dart to respective widget files"
echo "   3. Create service implementations"
echo "   4. Update main property_detail.dart to use new widgets"
echo "   5. Test each widget individually"
echo ""
echo "💡 Tip: Use 'import 'package:unistay/widgets/property_detail/index.dart';'"
echo "   in your main file to import all widgets at once"
echo ""
echo "Happy refactoring! 🎉"