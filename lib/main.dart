import 'package:caisse/pages/PersonnelPage.dart';
import 'package:caisse/pages/chantier_page.dart';
import 'package:caisse/pages/payment_types_page.dart';
import 'package:caisse/pages/todolist_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/home_page.dart';
import 'pages/payment_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_guard.dart';
import 'config/supabase_config.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/': (context) => const AuthGuard(child: HomePage()),
        '/payement': (context) => const AuthGuard(child: PaymentPage()),
        '/chantier': (context) => const ChantierPage(),
        '/personnel': (context) => const PersonnelPage(),
        '/todos':(context) => const TodoListPage(),
        '/payment-types':(context) => const PaymentTypesPage(),
      },
    );
  }
}