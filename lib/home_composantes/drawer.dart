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
    final screenWidth = MediaQuery.of(context).size.width;

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
                  height: screenWidth > 600 ? 100 : 80,
                  child: Image.asset(
                    'img/Logo.png',
                    color: Colors.white,
                    width: screenWidth > 600 ? 120 : 100,
                  ),
                ),
                SizedBox(height: screenWidth > 600 ? 10 : 5),
                MyText(
                  texte: "Menu Principal",
                  color: Colors.white,
                  fontSize: screenWidth > 600 ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.checklist,
            texte: "ToDo List",
            onTap: () => Navigator.pushNamed(context, '/todos'),
            screenWidth: screenWidth,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.business,
            texte: "Chantier",
            onTap: () => Navigator.pushNamed(context, '/chantier'),
            screenWidth: screenWidth,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            texte: "Personnel",
            onTap: () => Navigator.pushNamed(context, '/personnel'),
            screenWidth: screenWidth,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.payment,
            texte: "Types de paiement",
            onTap: () => Navigator.pushNamed(context, '/payment-types'),
            screenWidth: screenWidth,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 16 : 8,
              vertical: screenWidth > 600 ? 8 : 4,
            ),
            child: SwitchListTile(
              activeColor: const Color(0xffea6b24),
              title: Text(
                isDarkMode ? "Mode clair" : "Mode sombre",
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 16 : 14,
                ),
              ),
              secondary: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: screenWidth > 600 ? 24 : 20,
              ),
              value: isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme(value);
              },
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.lock_reset,
            texte: "Changer mot de passe",
            onTap: () => Navigator.pushNamed(context, '/change-password'),
            screenWidth: screenWidth,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            texte: "Aide",
            onTap: () {/* Implement help navigation */},
            screenWidth: screenWidth,
          ),
        ],
      ),
    );
  }

  // Helper method for consistent drawer item styling
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String texte,
    VoidCallback? onTap,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 8 : 4,
        vertical: screenWidth > 600 ? 4 : 2,
      ),
      child: DrawerListMenu(
        icon: icon,
        texte: texte,
        onTap: onTap,
      ),
    );
  }
}
