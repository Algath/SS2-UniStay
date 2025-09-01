import 'package:flutter/material.dart';

class PropertyFormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isTablet;
  final bool isLandscape;

  const PropertyFormCard({
    super.key,
    required this.title,
    required this.children,
    this.isTablet = false,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        isTablet
            ? (isLandscape ? 32 : 28)
            : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(
            height: isTablet
                ? (isLandscape ? 24 : 20)
                : 16,
          ),
          ...children,
        ],
      ),
    );
  }

  /// Get input decoration for form fields
  static InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  /// Create a toggle switch with consistent styling
  static Widget buildToggleSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Create spacing between form sections
  static Widget buildSpacing({bool isTablet = false, bool isLandscape = false}) {
    return SizedBox(
      height: isTablet
          ? (isLandscape ? 32 : 24)
          : 16,
    );
  }

  /// Create a row with responsive spacing
  static Widget buildResponsiveRow({
    required List<Widget> children,
    double spacing = 16,
    List<int>? flex,
  }) {
    final widgets = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (flex != null && flex.length > i) {
        widgets.add(Expanded(flex: flex[i], child: children[i]));
      } else {
        widgets.add(Expanded(child: children[i]));
      }

      if (i < children.length - 1) {
        widgets.add(SizedBox(width: spacing));
      }
    }
    return Row(children: widgets);
  }

  /// Create a standard form field with validation
  static Widget buildFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
    Widget? suffixIcon,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: getInputDecoration(label).copyWith(
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
    );
  }
}