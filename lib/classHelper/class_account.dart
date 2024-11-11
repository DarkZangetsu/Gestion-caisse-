import 'package:caisse/composants/boutons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/accounts.dart';
import '../providers/accounts_provider.dart';
import '../composants/textfields.dart';
import '../composants/texts.dart';
import '../providers/users_provider.dart';

class CompteDialog extends ConsumerStatefulWidget {
  const CompteDialog({Key? key}) : super(key: key);

  static Future<bool?> afficherDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => const CompteDialog(),
    );
  }

  @override
  ConsumerState<CompteDialog> createState() => _CompteDialogState();
}

class _CompteDialogState extends ConsumerState<CompteDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nom;
  String? _soldeInitial;
  final _uuid = const Uuid();

  void _sauvegarderCompte() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final userId = ref.read(currentUserProvider)?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur non connecté')),
      );
      return;
    }

    final nouveauCompte = Account(
      id: _uuid.v4(),
      userId: userId,
      name: _nom,
      solde: _soldeInitial != null ? double.tryParse(_soldeInitial!) : null,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(accountsStateProvider.notifier).createAccount(nouveauCompte).then((_) {
      Navigator.pop(context, true);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du compte: $error')),
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
          texte: "Ajouter un compte",
          fontSize: 16,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextfields(
              hintText: "Nom",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le nom du compte est requis';
                }
                return null;
              },
              onChanged: (value) {
                _nom = value;
              },
            ),
            const SizedBox(height: 16),
            MyTextfields(
              hintText: "Solde initial [Facultatif]",
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                }
                return null;
              },
              onChanged: (value) {
                _soldeInitial = value;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const MyText(texte: "ANNULER", color: Colors.black,),
        ),
        MyButtons(
          backgroundColor: const Color(0xffea6b24),
          onPressed: _sauvegarderCompte,
          child: const MyText(texte: "SAUVEGARDER", color: Colors.white,),
        ),
      ],
    );
  }
}