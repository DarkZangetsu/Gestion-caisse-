import 'package:caisse/composants/button_recu_paye.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/src/consumer.dart';
import 'package:intl/intl.dart';

import 'handleTransfert.dart';

class TabBottomResume extends ConsumerWidget {
  const TabBottomResume({
    super.key,
    required this.totalReceived,
    required this.totalPaid,
  });

  final double totalReceived;
  final double totalPaid;

  // Ajoutez WidgetRef ref dans la méthode build
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final montantController = TextEditingController();
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
                const SizedBox(width: 10.0),
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
                const SizedBox(width: 10.0),
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
        Row(
          children: [
            const ButtonRecuPaye(
              initialType: "reçu",
              text: "Reçu",
              backgroundColor: Colors.green,
              icon: Icons.get_app,
            ),
            const SizedBox(width: 8),
            const ButtonRecuPaye(
              initialType: "payé",
              text: "Payé",
              backgroundColor: Colors.red,
              icon: Icons.payment,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz_outlined, color: Colors.white),
                label: const Text('Transferer',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => handleTransfer(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
