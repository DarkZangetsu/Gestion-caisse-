// Créez une classe pour stocker les données du compte
import 'package:caisse/composants/textfields.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';

class CompteData {
  final String nom;
  final double? soldeInitial;
  final String type;
  final DateTime date;

  CompteData({
    required this.nom,
    this.soldeInitial,
    required this.type,
    required this.date,
  });
}

// Classe pour gérer le dialogue
class CompteDialog {
  static Future<CompteData?> afficherDialog(BuildContext context) async {
    String type = '+';
    DateTime selectedDate = DateTime.now();
    String compteNom = '';
    String? soldeInitial;

    return showDialog<CompteData>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(2),
        ),
        title: const SizedBox(
          width: double.infinity,
          child: MyText(
            texte: "Ajouter un compte",
            fontSize: 16,
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfields(
                  hintText: "Nom",
                  onChanged: (value) {
                    compteNom = value;
                  },
                ),
                const SizedBox(height: 8.0),
                MyTextfields(
                  hintText: "Solde d'ouverture [Facultatif]",
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    soldeInitial = value;
                  },
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Radio<String>(
                      value: '+',
                      groupValue: type,
                      onChanged: (String? value) {
                        setState(() {
                          type = value!;
                        });
                      },
                    ),
                    const Text('+'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: '-',
                      groupValue: type,
                      onChanged: (String? value) {
                        setState(() {
                          type = value!;
                        });
                      },
                    ),
                    const Text('-'),
                  ],
                ),
                const SizedBox(height: 8.0),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          TextButton(
            onPressed: () {
              if (compteNom.isNotEmpty) {
                Navigator.pop(
                  context,
                  CompteData(
                    nom: compteNom,
                    soldeInitial: soldeInitial != null ? double.tryParse(soldeInitial!) : null,
                    type: type,
                    date: selectedDate,
                  ),
                );
              }
            },
            child: const Text("SAUVEGARDER"),
          ),
        ],
      ),
    );
  }
}