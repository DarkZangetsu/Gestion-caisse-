import 'package:gestion_caisse_flutter/pages/payment_page.dart';
import 'package:flutter/material.dart';

class ButtonRecuPaye extends StatelessWidget {
  const ButtonRecuPaye({
    super.key,
    required this.text,
    this.backgroundColor,
    required this.initialType,
    this.icon,
  });

  final String text;
  final Color? backgroundColor;
  final String initialType;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(initialType: initialType),
          ),
        ),
      ),
    );
  }
}