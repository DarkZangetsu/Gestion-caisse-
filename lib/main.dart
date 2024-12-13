import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart'; // Ajouté
import 'package:gestion_caisse_flutter/check_connexion/widget_awesome_connexion.dart';
import 'package:gestion_caisse_flutter/pages/ChangePasswordPage.dart';
import 'package:gestion_caisse_flutter/pages/PersonnelPage.dart';
import 'package:gestion_caisse_flutter/pages/chantier_page.dart';
import 'package:gestion_caisse_flutter/pages/home_page.dart';
import 'package:gestion_caisse_flutter/pages/login_page.dart';
import 'package:gestion_caisse_flutter/pages/payment_page.dart';
import 'package:gestion_caisse_flutter/pages/payment_types_page.dart';
import 'package:gestion_caisse_flutter/pages/splash.dart';
import 'package:gestion_caisse_flutter/pages/todolist_page.dart';
import 'package:gestion_caisse_flutter/pages/transaction.dart';
import 'package:gestion_caisse_flutter/pages/transaction_personnel.dart';
import 'package:gestion_caisse_flutter/providers/auth_guard.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:gestion_caisse_flutter/services/work_manager_service.dart';
import 'check_connexion/service_connexion_reseau.dart';
import 'config/supabase_config.dart';
import 'mode/dark_mode.dart';
import 'mode/light_mode.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeNotifications();
  await WorkManagerService.initialize();
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: ConnexionGlobale(
        child: MaApplication(),
      ),
    ),
  );
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
      home: const NotificationPermissionRequest(child: Splash()),
      routes: {
        '/login': (context) => const WidgetAwareConnexion(child: LoginPage()),
        '/home': (context) =>
        const WidgetAwareConnexion(child: AuthGuard(child: HomePage())),
        '/payement': (context) =>
        const WidgetAwareConnexion(child: AuthGuard(child: PaymentPage())),
        '/chantier': (context) =>
        const WidgetAwareConnexion(child: ChantierPage()),
        '/personnel': (context) =>
        const WidgetAwareConnexion(child: PersonnelPage()),
        '/todos': (context) =>
        const WidgetAwareConnexion(child: TodoListPage()),
        '/payment-types': (context) =>
        const WidgetAwareConnexion(child: PaymentTypesPage()),
        '/change-password': (context) =>
        const WidgetAwareConnexion(child: ChangePasswordPage()),
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
        if (settings.name == '/transaction-personnel') {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (context) => WidgetAwareConnexion(
              child: TransactionPersonnelPage(
                personnelId: args['personnelId'] as String,
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}

class NotificationPermissionRequest extends StatelessWidget {
  final Widget child;

  const NotificationPermissionRequest({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Demande de permission pour les notifications
      final status = await Permission.notification.status;

      if (status.isDenied || status.isPermanentlyDenied) {
        await Permission.notification.request();
      }
    });

    return child;
  }
}
