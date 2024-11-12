import 'package:flutter/material.dart';

class MyTextfields extends StatelessWidget {
  MyTextfields({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.border,
    this.onChanged,
    this.prefix,
    this.contentPadding,
    required String? Function(dynamic value) validator,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final InputBorder? border;
  final void Function(String)? onChanged;
  final Widget? prefix;
  final EdgeInsetsGeometry? contentPadding;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: _formKey,
      onChanged: onChanged,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        prefix: prefix,
        hintText: hintText,
        isDense: true,
        contentPadding: contentPadding,
        border: border,
      ),
    );
  }
}
