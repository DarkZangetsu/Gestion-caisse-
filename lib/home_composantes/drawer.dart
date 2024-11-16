import 'package:caisse/composants/drawer_list_menu.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xffea6b24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 80,
                  child: Image.asset(
                    'img/Logo.png',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const MyText(
                  texte: "Menu Principal",
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          DrawerListMenu(
            icon: Icons.business,
            texte: "Chantier",
            onTap: () => Navigator.pushNamed(context, '/chantier'),
          ),
          DrawerListMenu(
            icon: Icons.people,
            texte: "Personnel",
            onTap: () => Navigator.pushNamed(context, '/personnel'),
          ),
          DrawerListMenu(
            icon: Icons.checklist,
            texte: "ToDo List",
            onTap: () => Navigator.pushNamed(context, '/todos'),
          ),
          DrawerListMenu(
            icon: Icons.payment,
            texte: "Types de paiement",
            onTap: () => Navigator.pushNamed(context, '/payment-types'),
          ),
          const DrawerListMenu(icon: Icons.settings, texte: "Paramètres"),
          const DrawerListMenu(icon: Icons.help_outline, texte: "Aide"),
        ],
      ),
    );
  }
}