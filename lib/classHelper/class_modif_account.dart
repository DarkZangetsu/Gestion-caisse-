import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../composants/boutons.dart';
import '../composants/textfields.dart';
import '../composants/texts.dart';
import '../models/accounts.dart';
import '../providers/accounts_provider.dart';

class ModifierCompteDialog extends ConsumerStatefulWidget {
  final Account compte;

  const ModifierCompteDialog({Key? key, required this.compte}) : super(key: key);

  @override
  ConsumerState<ModifierCompteDialog> createState() => _ModifierCompteDialogState();
}

class _ModifierCompteDialogState extends ConsumerState<ModifierCompteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _soldeController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.compte.name);
    _soldeController = TextEditingController(
      text: widget.compte.solde.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _soldeController.dispose();
    super.dispose();
  }

  void _modifierCompte() {
    if (!_formKey.currentState!.validate()) return;

    final updatedCompte = Account(
      id: widget.compte.id,
      userId: widget.compte.userId,
      name: _nomController.text,
      solde: double.parse(_soldeController.text),
      createdAt: widget.compte.createdAt,
      updatedAt: DateTime.now(),
    );

    ref.read(accountsStateProvider.notifier).updateAccount(updatedCompte).then((_) {
      Navigator.pop(context, true);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification du compte: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.grey, width: 1.0),
        borderRadius: BorderRadius.circular(2),
      ),
      title: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))
        ),
        child: const MyText(
          texte: "Modifier un compte",
          fontSize: 16,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextfields(
              controller: _nomController,
              hintText: "Nom",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le nom du compte est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            MyTextfields(
              controller: _soldeController,
              hintText: "Solde initial [Obligatoire]",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le solde initial est obligatoire';
                }
                if (double.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const MyText(texte: "ANNULER"),
        ),
        MyButtons(
          backgroundColor: const Color(0xffea6b24),
          onPressed: _modifierCompte,
          child: const MyText(texte: "SAUVEGARDER", color: Colors.white,),
        ),
      ],
    );
  }
}