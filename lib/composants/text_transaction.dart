import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            ? NumberFormat.currency(
                    locale: 'fr_FR', symbol: 'Ar', decimalDigits: 2)
                .format(transaction.amount)
            : '',
        color: color,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.right,
      ),
    );
  }
}
