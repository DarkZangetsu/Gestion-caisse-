import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../composants/MyTextFormField.dart';
import '../composants/texts.dart';
import '../models/accounts.dart';
import '../providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';

void handleTransfer(BuildContext context, WidgetRef ref) {
  final montantController = TextEditingController();
  Account? sourceAccount;
  Account? destinationAccount;

  // Récupérer la liste des comptes depuis l'état
  final accountsState = ref.watch(accountsStateProvider);

  accountsState.when(
    data: (accounts) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text("Transfert d'argent"),
          content: SingleChildScrollView(
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextFormField(
                    budgetController: montantController,
                    keyboardType: TextInputType.number,
                    labelText: "Montant",
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Account>(
                    decoration: InputDecoration(
                      labelText: "Compte source",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: accounts.map((account) => DropdownMenuItem(
                      value: account,
                      child: Text(account.name),
                    )).toList(),
                    onChanged: (value) {
                      sourceAccount = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Account>(
                    decoration: InputDecoration(
                      labelText: "Compte destination",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: accounts.map((account) => DropdownMenuItem(
                      value: account,
                      child: Text(account.name),
                    )).toList(),
                    onChanged: (value) {
                      destinationAccount = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: MyText(texte: "Annuler", color: Colors.grey[800]),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffea6b24),
              ),
              onPressed: () async {
                if (sourceAccount != null &&
                    destinationAccount != null &&
                    montantController.text.isNotEmpty) {
                  try {
                    final amount = double.parse(montantController.text);
                    await ref.read(transactionsStateProvider.notifier).createTransferTransaction(
                      sourceAccountId: sourceAccount!.id,
                      destinationAccountId: destinationAccount!.id,
                      amount: amount,
                      sourceAccountName: sourceAccount!.name,
                      destinationAccountName: destinationAccount!.name,
                    );

                    Navigator.of(context).pop();

                    // Rafraîchir les transactions pour les deux comptes
                    await ref.read(transactionsStateProvider.notifier).loadTransactions();
                        //.loadTransactions(sourceAccount!.id);
                    await ref.read(transactionsStateProvider.notifier).loadTransactions();
                        //.loadTransactions(destinationAccount!.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transfert effectué avec succès')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors du transfert: $e')),
                    );
                  }
                }
              },
              child: const MyText(texte: "Confirmer", color: Colors.white),
            ),
          ],
        ),
      );
    },
    loading: () => const CircularProgressIndicator(),
    error: (error, stack) => Text('Erreur: $error'),
  );
}