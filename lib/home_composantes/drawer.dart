import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:gestion_caisse_flutter/composants/drawer_list_menu.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';

class MyDrawer extends ConsumerWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return LayoutBuilder(
      builder: (context, constraints) {

        final double logoHeight = _getResponsiveDimension(constraints.maxWidth, 100, 80);
        final double logoWidth = _getResponsiveDimension(constraints.maxWidth, 120, 100);
        final double titleFontSize = _getResponsiveDimension(constraints.maxWidth, 22, 20);
        final double itemFontSize = _getResponsiveDimension(constraints.maxWidth, 16, 14);
        final double iconSize = _getResponsiveDimension(constraints.maxWidth, 24, 20);
        final double horizontalPadding = _getResponsiveDimension(constraints.maxWidth, 16, 8);
        final double verticalPadding = _getResponsiveDimension(constraints.maxWidth, 8, 4);

        return Drawer(
          child: SafeArea(
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
                        height: logoHeight,
                        child: Image.asset(
                          'img/Logo.png',
                          color: Colors.white,
                          width: logoWidth,
                          fit: BoxFit.contain, // Ensures logo scales properly
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      MyText(
                        texte: "Menu Principal",
                        color: Colors.white,
                        fontSize: titleFontSize,
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
                  constraints: constraints,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.business,
                  texte: "Chantier",
                  onTap: () => Navigator.pushNamed(context, '/chantier'),
                  constraints: constraints,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  texte: "Personnel",
                  onTap: () => Navigator.pushNamed(context, '/personnel'),
                  constraints: constraints,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.payment,
                  texte: "Types de paiement",
                  onTap: () => Navigator.pushNamed(context, '/payment-types'),
                  constraints: constraints,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: SwitchListTile(
                    activeColor: const Color(0xffea6b24),
                    title: Text(
                      isDarkMode ? "Mode clair" : "Mode sombre",
                      style: TextStyle(
                        fontSize: itemFontSize,
                      ),
                    ),
                    secondary: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: iconSize,
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
                  constraints: constraints,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  texte: "Aide",
                  onTap: () {/* Implement help navigation */},
                  constraints: constraints,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for consistent drawer item styling with responsive sizing
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String texte,
        VoidCallback? onTap,
        required BoxConstraints constraints,
      }) {
    final horizontalPadding = _getResponsiveDimension(constraints.maxWidth, 8, 4);
    final verticalPadding = _getResponsiveDimension(constraints.maxWidth, 4, 2);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: DrawerListMenu(
        icon: icon,
        texte: texte,
        onTap: onTap,
      ),
    );
  }

  // Responsive calculation method
  double _getResponsiveDimension(
      double screenWidth,
      double wideScreenValue,
      double normalScreenValue
      ) {
    // Gradually interpolate between normal and wide screen values
    return normalScreenValue +
        (wideScreenValue - normalScreenValue) *
            ((screenWidth - 320) / (1200 - 320)).clamp(0, 1);
  }
}