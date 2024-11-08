import 'package:caisse/classHelper/class_account.dart';
import 'package:caisse/composants/boutons.dart';
import 'package:caisse/composants/texts.dart';
import 'package:caisse/pages/home_page.dart';
import 'package:flutter/material.dart';

class ModificationPage extends StatefulWidget {
  const ModificationPage({super.key});

  @override
  State<ModificationPage> createState() => _ModificationPageState();
}

class _ModificationPageState extends State<ModificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(texte: "Comptes", color: Colors.white,),
        backgroundColor: Colors.blue,
        actions: [
          MyButtons(
            backgroundColor: Colors.blue,
            elevation: 0,
            onPressed: () async {
              final CompteData? result = await CompteDialog.afficherDialog(context);

              if (result != null) {
                ListAccount.comptes.add(result.nom);
              }
            },
            child: const MyText(texte: "Ajouter un compte", color: Colors.white,),
          ),
        ],
      ),
    );
  }
}