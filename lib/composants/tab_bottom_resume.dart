
import 'package:caisse/composants/button_recu_paye.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';

class TabBottomResume extends StatelessWidget {
  const TabBottomResume({
    super.key,
    required this.totalReceived,
    required this.totalPaid,
    required this.totalBalance,
  });

  final double totalReceived;
  final double totalPaid;
  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              texte: "Total Reçu: ${totalReceived.toStringAsFixed(2)}",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            MyText(
              texte: "Total Payé: ${totalPaid.toStringAsFixed(2)}",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MyText(
                texte: "Solde Total:",
                fontSize: 16,
                fontWeight: FontWeight.bold),
            MyText(
              texte: totalBalance.toStringAsFixed(2),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: totalBalance >= 0 ? Colors.green : Colors.red,
            ),
          ],
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