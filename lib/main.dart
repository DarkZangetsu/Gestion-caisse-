import 'package:caisse/pages/ChangePasswordPage.dart';
import 'package:caisse/pages/PersonnelPage.dart';
import 'package:caisse/pages/transaction.dart';
import 'package:caisse/providers/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_config.dart';
import 'providers/theme_provider.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/payment_page.dart';
import 'pages/chantier_page.dart';
import 'pages/todolist_page.dart';
import 'pages/payment_types_page.dart';
import 'providers/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/': (context) => const AuthGuard(child: HomePage()),
        '/payement': (context) => const AuthGuard(child: PaymentPage()),
        '/chantier': (context) => const ChantierPage(),
        '/personnel': (context) => const PersonnelPage(),
        '/todos':(context) => const TodoListPage(),
        '/payment-types':(context) => const PaymentTypesPage(),
        '/change-password':(context) => const ChangePasswordPage(),
      },
      onGenerateRoute: (settings) {
        if(settings.name == '/transaction') {
          final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
                builder: (context) => TransactionPage(
                    chantierId: args['chantierId'] as String,
                ) ,
            );
        }
      }
    );
  }
}
