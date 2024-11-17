import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caisse/providers/theme_provider.dart';
import 'package:caisse/composants/drawer_list_menu.dart';
import 'package:caisse/composants/texts.dart';

class MyDrawer extends ConsumerWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

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
              ],
            ),
          ),
          DrawerListMenu(
            icon: Icons.checklist,
            texte: "ToDo List",
            onTap: () => Navigator.pushNamed(context, '/todos'),
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
            icon: Icons.payment,
            texte: "Types de paiement",
            onTap: () => Navigator.pushNamed(context, '/payment-types'),
          ),
          // Commutateur pour mode sombre et clair
          SwitchListTile(
            activeColor: const Color(0xffea6b24),
            title: Text(isDarkMode ? "Mode clair" : "Mode sombre"),
            secondary: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            value: isDarkMode,
            onChanged: (value) {
              themeNotifier.toggleTheme(value);
            },
          ),
          const DrawerListMenu(
            icon: Icons.help_outline,
            texte: "Aide",
          ),
        ],
      ),
    );
  }
}
