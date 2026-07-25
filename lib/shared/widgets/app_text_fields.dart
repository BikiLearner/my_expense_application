import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  // Input
  final TextInputType keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  // Colors
  final Color iconColor;
  final Color textColor;
  final Color labelColor;
  final Color hintColor;
  final Color fillColor;
  final Color enabledBorderColor;
  final Color focusedBorderColor;

  // Text styling
  final double fontSize;
  final FontWeight? fontWeight;

  // Border
  final double borderRadius;
  final double enabledBorderWidth;
  final double focusedBorderWidth;

  // Padding
  final EdgeInsetsGeometry contentPadding;

  // Other
  final bool filled;
  final bool enabled;
  final bool obscureText;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,

    // Input defaults
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.inputFormatters,

    // Current colors as defaults
    this.iconColor = const Color(0xFF64FFDA),
    this.textColor = Colors.white,
    this.labelColor = const Color(0xFF9E9E9E),
    this.hintColor = const Color(0xFF616161),
    this.fillColor = const Color(0xFF2C2C2C),
    this.enabledBorderColor = const Color(0xFF3C3C3C),
    this.focusedBorderColor = const Color(0xFF64FFDA),

    // Text defaults
    this.fontSize = 16,
    this.fontWeight,

    // Border defaults
    this.borderRadius = 12,
    this.enabledBorderWidth = 1,
    this.focusedBorderWidth = 2,

    // Padding
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),

    // Other
    this.filled = true,
    this.enabled = true,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      obscureText: obscureText,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        labelStyle: TextStyle(
          color: labelColor,
        ),

        hintStyle: TextStyle(
          color: hintColor,
        ),

        prefixIcon: Icon(
          icon,
          color: iconColor,
        ),

        filled: filled,
        fillColor: fillColor,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: enabledBorderColor,
            width: enabledBorderWidth,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: focusedBorderColor,
            width: focusedBorderWidth,
          ),
        ),

        contentPadding: contentPadding,
      ),
    );
  }
}