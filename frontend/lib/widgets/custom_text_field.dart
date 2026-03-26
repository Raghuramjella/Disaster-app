import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.controller,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF2E7D32)),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
