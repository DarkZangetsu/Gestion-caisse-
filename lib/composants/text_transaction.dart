import 'package:caisse/composants/texts.dart';
import 'package:caisse/models/transaction.dart';
import 'package:flutter/material.dart';

class Text_transaction extends StatelessWidget {
  const Text_transaction({
    super.key,
    required this.transaction,
    required this.text,
    this.color,
  });

  final Transaction transaction;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MyText(
        texte: transaction.type == text
            ? transaction.amount.toStringAsFixed(2)
            : '',
        color: color,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.right,
      ),
    );
  }
}