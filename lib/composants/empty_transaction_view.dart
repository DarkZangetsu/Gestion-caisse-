// Extracted widgets for better organization
import 'package:gestion_caisse_flutter/composants/boutons.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:flutter/material.dart';

class EmptyTransactionView extends StatelessWidget {
  const EmptyTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune transaction',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          MyButtons(
            backgroundColor: const Color(0xffea6b24),
            onPressed: () => Navigator.pushNamed(context, '/payement'),
            child: const MyText(
              texte: "Ajouter une transaction",
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}