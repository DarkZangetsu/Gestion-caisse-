import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/app_user.dart';
import '../models/accounts.dart';
import '../models/chantier.dart';
import '../models/personnel.dart';
import '../models/payment_method.dart';
import '../models/payment_type.dart';
import '../models/transaction.dart';
import '../models/todo.dart';
import '../config/supabase_config.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // User Methods
  // Fonction utilitaire pour hasher le mot de passe
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User Methods
  Future<AppUser?> createUser(String email, String password) async {
    try {
      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Créer l'utilisateur dans la table users
      final userData = {
        'email': email,
        'password': _hashPassword(password),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('users').insert(userData).select().single();

      return AppUser.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /*Future<AppUser?> signInUser(String email, String password) async {
    try {

      final hashedPassword = _hashPassword(password);
      print('Hashed password: $hashedPassword');

      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response == null) {
        throw Exception('Mot de passe incorrect');
      }

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error during login: $e'); 
      throw Exception('Erreur lors de la connexion');
    }
  }*/

  Future<AppUser?> signInUser(String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response == null) {
        throw 'Mot de passe incorrect';
      }

      return AppUser.fromJson(response);
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOutUser() async {
    // Ici vous pouvez implémenter une logique de déconnexion locale
    // comme effacer les données en cache ou les préférences utilisateur
  }

  Future<AppUser?> getCurrentUser(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return AppUser.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  Future<void> updateUserPassword(String userId, String newPassword) async {
    try {
      await _supabase
          .from('users')
          .update({'password': _hashPassword(newPassword)}).eq('id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  // Account Methods
  Future<List<Account>> getAccounts(String userId) async {
    try {
      final response =
          await _supabase.from('accounts').select().eq('user_id', userId);

      return (response as List).map((json) => Account.fromJson(json)).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      throw Exception('Erreur lors de la récupération des comptes: $e');
    }
  }

  Future<Account> createAccount(Account account) async {
    try {
      final response = await _supabase
          .from('accounts')
          .insert(account.toJson())
          .select()
          .single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création du compte: $e');
    }
  }

  Future<Account> updateAccount(Account account) async {
    try {
      final response = await _supabase
          .from('accounts')
          .update(account.toJson())
          .eq('id', account.id)
          .select()
          .single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du compte: $e');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _supabase.from('accounts').delete().eq('id', accountId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  // Chantier Methods
  Future<List<Chantier>> getChantiers(String userId) async {
    try {
      final response =
          await _supabase.from('chantiers').select().eq('user_id', userId);
      print("Réponse brute des chantiers : $response");
      return (response as List).map((json) => Chantier.fromJson(json)).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      throw Exception('Erreur lors de la récupération des chantiers');
    }
  }

  Future<Chantier> createChantier(Chantier chantier) async {
    try {
      print('Creating chantier: $chantier');
      final response = await _supabase
          .from('chantiers')
          .insert(chantier.toJson())
          .select()
          .single();
      print('Created chantier: ${Chantier.fromJson(response)}');
      return Chantier.fromJson(response);
    } catch (e) {
      print('Error creating chantier: $e');
      rethrow;
    }
  }

  Future<Chantier> updateChantier(Chantier chantier) async {
    try {
      final response = await _supabase
          .from('chantiers')
          .update(chantier.toJson())
          .eq('id', chantier.id)
          .select()
          .single();

      return Chantier.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du chantier: $e');
    }
  }

  Future<void> deleteChantier(String chantierId) async {
    try {
      await _supabase.from('chantiers').delete().eq('id', chantierId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du chantier: $e');
    }
  }

  // Personnel Methods
  Future<List<Personnel>> getPersonnel(String userId) async {
    try {
      final response =
          await _supabase.from('personnel').select().eq('user_id', userId);
      print("Réponse brute des personnel : $response");
      return (response as List)
          .map((json) => Personnel.fromJson(json))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      throw Exception('Erreur lors de la récupération du personnel: $e');
    }
  }

  Future<Personnel> createPersonnel(Personnel personnel) async {
    try {
      final response = await _supabase
          .from('personnel')
          .insert(personnel.toJson())
          .select()
          .single();

      return Personnel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création du personnel: $e');
    }
  }

  Future<Personnel> updatePersonnel(Personnel personnel) async {
    try {
      final response = await _supabase
          .from('personnel')
          .update(personnel.toJson())
          .eq('id', personnel.id)
          .select()
          .single();

      return Personnel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du personnel: $e');
    }
  }

  Future<void> deletePersonnel(String personnelId) async {
    try {
      await _supabase.from('personnel').delete().eq('id', personnelId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du personnel: $e');
    }
  }

  // Payment Methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _supabase.from('payment_methods').select();

      return (response as List)
          .map((json) => PaymentMethod.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des méthodes de paiement: $e');
    }
  }

  // Payment Type Methods
  Future<List<PaymentType>> getPaymentTypes() async {
    try {
      final response = await _supabase.from('payment_types').select();

      return (response as List)
          .map((json) => PaymentType.fromJson(json))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des types de paiement: $e');
    }
  }


  Future<PaymentType> createPaymentType(PaymentType paymentType) async {
    try {
      final response = await _supabase
          .from('payment_types')
          .insert(paymentType.toJson())
          .select()
          .single();

      return PaymentType.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création du type de paiement: $e');
    }
  }

  Future<PaymentType> updatePaymentType(PaymentType paymentType) async {
    try {
      final response = await _supabase
          .from('payment_types')
          .update(paymentType.toJson())
          .eq('id', paymentType.id)
          .select()
          .single();

      return PaymentType.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du type de paiement: $e');
    }
  }

  Future<void> deletePaymentType(String paymentTypeId) async {
    try {
      await _supabase.from('payment_types').delete().eq('id', paymentTypeId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du type de paiement: $e');
    }
  }

  // Transaction Methodse
  Future<List<Transaction>> getTransactions(String accountId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('account_id', accountId)
          .order('created_at', ascending: false); // true pour LIFO

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des transactions: $e');
    }
  }

  //New change
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final query = _supabase.from('transactions').select();

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des transactions: $e');
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await _supabase
          .from('transactions')
          .insert(transaction.toJson())
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la transaction: $e');
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final response = await _supabase
          .from('transactions')
          .update(transaction.toJson())
          .eq('id', transaction.id)
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la transaction: $e');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _supabase.from('transactions').delete().eq('id', transactionId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la transaction: $e');
    }
  }

  // Todos Methods
  Future<List<Todo>> getTodos(String accountId) async {
    try {
      final response =
          await _supabase.from('todos').select().eq('account_id', accountId);

      return (response as List).map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des todos: $e');
    }
  }

  Future<Todo> createTodo(Todo todo) async {
    try {
      print('Début createTodo dans DatabaseHelper');
      print(
          'Données à insérer: ${todo.toJson(forDatabase: true)}'); // Ajout de forDatabase: true ici

      final response = await _supabase
          .from('todos')
          .insert(
              todo.toJson(forDatabase: true)) // Ajout de forDatabase: true ici
          .select()
          .single();

      print('Réponse Supabase: $response');

      final createdTodo = Todo.fromJson(response);
      print('Todo créé avec succès: ${createdTodo.toJson()}');

      return createdTodo;
    } catch (e, stackTrace) {
      print('Erreur dans DatabaseHelper.createTodo: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la création du todo: $e');
    }
  }

  Future<Todo> updateTodo(Todo todo) async {
    try {
      final response = await _supabase
          .from('todos')
          .update(todo.toJson(forDatabase: true))
          .eq('id', todo.id)
          .select()
          .single();

      return Todo.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du todo: $e');
    }
  }

  Future<void> deleteTodo(String todoId) async {
    try {
      await _supabase.from('todos').delete().eq('id', todoId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du todo: $e');
    }
  }

  // Méthodes additionnelles utiles
  Future<List<Transaction>> getTransactionsByChantier(String chantierId) async {
    try {
      print('Database query for chantierId: $chantierId');

      final response = await _supabase
          .from('transactions')
          .select('*')
          .eq('chantier_id', chantierId)
          .order('transaction_date', ascending: false);

      print('Raw database response length: ${response.length}');

      return response
          .map((data) {
            try {
              return Transaction.fromJson(data);
            } catch (e) {
              print('Transaction parsing error: $e for data: $data');
              return null;
            }
          })
          .whereType<Transaction>()
          .toList();
    } catch (e) {
      print('Comprehensive database error: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByPersonnel(
      String personnelId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('personnel_id', personnelId)
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des transactions du personnel: $e');
    }
  }

  Future<List<Transaction>> getTransactionsByPaymentType(String paymentTypeId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('payment_type_id', paymentTypeId)
          .order('transaction_date', ascending: false);

      print('Transactions récupérées: $response'); // Debug print

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des transactions: $e');
      throw Exception('Erreur lors de la récupération des transactions du paymentType: $e');
    }
  }

  Future<List<Todo>> getTodosByChantier(String chantierId) async {
    try {

      final response =
          await _supabase.from('todos').select().eq('chantier_id', chantierId);

      return (response as List).map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des todos du chantier: $e');
    }
  }

  Future<List<Todo>> getPendingTodos(String accountId) async {
    try {
      final response = await _supabase
          .from('todos')
          .select()
          .eq('account_id', accountId)
          .eq('completed', false);

      return (response as List).map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des todos en attente: $e');
    }
  }


// Fonctionnalité en plus pour le calcule de la valeur de reste a payé a un personnel par type de paiment salaire :
  Future<double> getRemainingPaymentForPersonnel(String personnelId) async {
    try {
      // Récupérer le personnel avec son salaire max
      final personnelResponse = await _supabase
          .from('personnel')
          .select('salaire_max')
          .eq('id', personnelId)
          .single();

      double salaireMax = personnelResponse['salaire_max'] != null
          ? double.parse(personnelResponse['salaire_max'].toString())
          : 0.0;

      print('Salaire Max pour le personnel $personnelId: $salaireMax');

      // Récupérer les types de paiement avec "salaire" (case-insensitive)
      final paymentTypesResponse = await _supabase
          .from('payment_types')
          .select('id, name')
          .or('name.ilike.%salaire%,name.ilike.%salary%');

      List<String> salairePaymentTypeIds = (paymentTypesResponse as List)
          .map((type) => type['id'].toString())
          .toList();

      print('Types de paiement de salaire trouvés: $salairePaymentTypeIds');

      // Si aucun type de paiement de salaire n'est trouvé, retourner le salaire max
      if (salairePaymentTypeIds.isEmpty) {
        print('Aucun type de paiement de salaire trouvé');
        return salaireMax;
      }

      // Récupérer les transactions de salaire pour ce personnel
      final transactionsResponse = await _supabase
          .from('transactions')
          .select('id, amount, payment_type_id, transaction_date')
          .eq('personnel_id', personnelId)
          .filter('payment_type_id', 'in', salairePaymentTypeIds);

      // Log des détails des transactions
      print('Nombre de transactions de salaire: ${transactionsResponse.length}');
      for (var transaction in transactionsResponse) {
        print('Transaction - ID: ${transaction['id']}, '
            'Amount: ${transaction['amount']}, '
            'Payment Type ID: ${transaction['payment_type_id']}, '
            'Date: ${transaction['transaction_date']}');
      }

      // Calculer le montant total des salaires déjà payés
      double totalSalairePaye = (transactionsResponse as List)
          .map((transaction) => double.parse(transaction['amount'].toString()))
          .fold(0.0, (prev, amount) => prev + amount);

      print('Total Salaire Payé: $totalSalairePaye');

      // Calculer le reste à payer
      double resteAPayer = salaireMax - totalSalairePaye;
      print('Reste à Payer: $resteAPayer');

      return resteAPayer;
    } catch (e) {
      print('Erreur lors du calcul du reste à payer: $e');
      return 0.0; // Retourne 0 en cas d'erreur
    }
  }


  //Total des transaction recu ou bien payé par chantier  :
  Future<Map<String, double>> getChantierTransactionTotals(String chantierId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('amount, type')
          .eq('chantier_id', chantierId);

      double totalRecu = 0.0;
      double totalPaye = 0.0;

      for (var transaction in response) {
        double amount = double.parse(transaction['amount'].toString());
        String type = transaction['type'];

        if (type == 'reçu') {
          totalRecu += amount;
        } else if (type == 'payé') {
          totalPaye += amount;
        }
      }

      return {
        'totalRecu': totalRecu,
        'totalPaye': totalPaye,
        'solde': totalRecu - totalPaye
      };
    } catch (e) {
      print('Erreur lors du calcul des totaux du chantier: $e');
      return {
        'totalRecu': 0.0,
        'totalPaye': 0.0,
        'solde': 0.0
      };
    }
  }
}
