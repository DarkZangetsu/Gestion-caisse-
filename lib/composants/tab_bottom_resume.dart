import 'package:caisse/composants/MyTextFormField.dart';
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
                icon:
                    const Icon(Icons.swap_horiz_outlined, color: Colors.white),
                label: const Text('Transferer',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      title: const Text("Transfert d'argent"),
                      content: SingleChildScrollView(
                        child: Form(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Champ pour saisir le montant
                              MyTextFormField(
                                budgetController: montantController,
                                keyboardType: TextInputType.number,
                                labelText: "Montant",
                              ),
                              const SizedBox(height: 16),
                              // Première liste déroulante
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: "Compte source",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: "Compte 1",
                                      child: Text("Compte 1")),
                                  DropdownMenuItem(
                                      value: "Compte 2",
                                      child: Text("Compte 2")),
                                  DropdownMenuItem(
                                      value: "Compte 3",
                                      child: Text("Compte 3")),
                                ],
                                onChanged: (value) {
                                  // Gérer la sélection
                                },
                              ),
                              const SizedBox(height: 16),
                              // Deuxième liste déroulante
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: "Compte destination",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: "Compte A",
                                      child: Text("Compte A")),
                                  DropdownMenuItem(
                                      value: "Compte B",
                                      child: Text("Compte B")),
                                  DropdownMenuItem(
                                      value: "Compte C",
                                      child: Text("Compte C")),
                                ],
                                onChanged: (value) {
                                  // Gérer la sélection
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: MyText(texte: "Annuler", color: Colors.grey[800],),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffea6b24),
                          ),
                          onPressed: () {
                            // Action pour confirmer le transfert
                          },
                          child: const MyText(texte: "Confirmer", color: Colors.white,),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
