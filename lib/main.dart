import 'package:gestion_caisse_flutter/check_connexion/widget_awesome_connexion.dart';
import 'package:gestion_caisse_flutter/pages/ChangePasswordPage.dart';
import 'package:gestion_caisse_flutter/pages/PersonnelPage.dart';
import 'package:gestion_caisse_flutter/pages/chantier_page.dart';
import 'package:gestion_caisse_flutter/pages/home_page.dart';
import 'package:gestion_caisse_flutter/pages/login_page.dart';
import 'package:gestion_caisse_flutter/pages/payment_page.dart';
import 'package:gestion_caisse_flutter/pages/payment_types_page.dart';
import 'package:gestion_caisse_flutter/pages/todolist_page.dart';
import 'package:gestion_caisse_flutter/pages/transaction.dart';
import 'package:gestion_caisse_flutter/providers/auth_guard.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_config.dart';
import 'mode/dark_mode.dart';
import 'mode/light_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = TodoNotificationService();
  await notificationService.initNotification();
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MaApplication(),
    ),
  );
}

class MaApplication extends ConsumerWidget {
  const MaApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeCourant = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeCourant,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const WidgetAwareConnexion(child: LoginPage()),
        '/': (context) => const WidgetAwareConnexion(child: AuthGuard(child: HomePage())),
        '/payement': (context) => const WidgetAwareConnexion(child: AuthGuard(child: PaymentPage())),
        '/chantier': (context) => const WidgetAwareConnexion(child: ChantierPage()),
        '/personnel': (context) => const WidgetAwareConnexion(child: PersonnelPage()),
        '/todos': (context) => const WidgetAwareConnexion(child: TodoListPage()),
        '/payment-types': (context) => const WidgetAwareConnexion(child: PaymentTypesPage()),
        '/change-password': (context) => const WidgetAwareConnexion(child: ChangePasswordPage()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/transaction') {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (context) => WidgetAwareConnexion(
              child: TransactionPage(
                chantierId: args['chantierId'] as String,
              ),
            ),
          );
        }
      },
    );
  }
}