import 'package:caisse/composants/text_transaction.dart';
import 'package:caisse/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(transaction.transactionDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty)
                      Text(
                        transaction.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text_transaction(
                text: 'reçu',
                transaction: transaction,
                color: Colors.green,
              ),
              Text_transaction(
                text: 'payé',
                transaction: transaction,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}