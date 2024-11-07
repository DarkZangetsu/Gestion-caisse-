import 'package:flutter/material.dart';

class MyTextfields extends StatelessWidget {
  const MyTextfields({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        hintText: hintText,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderSide: const BorderSide(width: 0, color: Colors.grey),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
