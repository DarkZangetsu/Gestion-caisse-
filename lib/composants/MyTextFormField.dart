import 'package:flutter/material.dart';

class MyTextFormField extends StatelessWidget {
  const MyTextFormField({
    super.key,
    required TextEditingController budgetController,
    this.labelText, this.validator, this.onChanged, this.keyboardType,
  }) : _budgetController = budgetController;

  final TextEditingController _budgetController;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      controller: _budgetController,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.wallet),
      ),
      //keyboardType: const TextInputType.numberWithOptions(decimal: true),
      keyboardType: keyboardType,
    );
  }
}