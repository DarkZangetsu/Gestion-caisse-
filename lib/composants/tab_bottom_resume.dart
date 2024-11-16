import 'package:caisse/composants/button_recu_paye.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TabBottomResume extends StatelessWidget {
  const TabBottomResume({
    super.key,
    required this.totalReceived,
    required this.totalPaid,
  });

  final double totalReceived;
  final double totalPaid;
  //final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const MyText(
                  texte: "Total Reçu:",
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(
                  width: 10.0,
                ),
                MyText(
                  texte: NumberFormat.currency(
                    locale: 'fr_FR',
                    symbol: 'Ar',
                    decimalDigits: 2,
                  ).format(totalReceived),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ],
            ),
            Row(
              children: [
                const MyText(
                  texte: "Total Payé:",
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(
                  width: 10.0,
                ),
                MyText(
                  texte: NumberFormat.currency(
                    locale: 'fr_FR',
                    symbol: 'Ar',
                    decimalDigits: 2,
                  ).format(totalPaid),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            ButtonRecuPaye(
              initialType: "reçu",
              text: "Reçu",
              backgroundColor: Colors.green,
              icon: Icons.get_app,
            ),
            SizedBox(width: 8),
            ButtonRecuPaye(
              initialType: "payé",
              text: "Payé",
              backgroundColor: Colors.red,
              icon: Icons.payment,
            ),
          ],
        ),
      ],
    );
  }
}