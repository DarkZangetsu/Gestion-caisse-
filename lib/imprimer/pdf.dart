import 'package:gestion_caisse_flutter/models/transaction.dart';
import 'package:gestion_caisse_flutter/providers/accounts_provider.dart';
import 'package:gestion_caisse_flutter/providers/transactions_provider.dart';
import 'package:gestion_caisse_flutter/providers/personnel_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../providers/chantiers_provider.dart';
import '../providers/payment_types_provider.dart';

class EnhancedTransaction {
  final Transaction transaction;
  final String accountName;
  final String chantierName;
  final String personnelName;
  final String paymentTypeName;

  EnhancedTransaction({
    required this.transaction,
    required this.accountName,
    required this.chantierName,
    required this.personnelName,
    required this.paymentTypeName,
  });
}

class ImpressionParPdf {
  static String _getAssociatedName(
      List<dynamic> items,
      String? id,
      String Function(dynamic) nameExtractor,
      ) {
    if (id == null || items.isEmpty) return '';

    try {
      for (var item in items) {
        if (item.id.toString() == id.toString()) {
          return nameExtractor(item);
        }
      }
      print('No matching item found for ID: $id');
      return ''; // Aucun élément trouvé
    } catch (e) {
      print('Error in _getAssociatedName: $e');
      return '';
    }
  }


  // Pre-fetch associated names for transactions
  static Future<List<EnhancedTransaction>> _prepareEnhancedTransactions(
      WidgetRef ref,
      List<Transaction> transactions,
      ) async {
    final accounts = ref.read(accountsStateProvider).value ?? [];
    final chantiers = ref.read(chantiersStateProvider).value ?? [];
    final personnels = ref.read(personnelStateProvider).value ?? [];
    final paymentTypes = ref.read(paymentTypesProvider).value ?? [];

    return transactions.map((transaction) {
      return EnhancedTransaction(
        transaction: transaction,
        accountName: _getAssociatedName(
          accounts,
          transaction.accountId,
              (account) => account.name,
        ),
        chantierName: _getAssociatedName(
          chantiers,
          transaction.chantierId,
              (chantier) => chantier.name,
        ),
        personnelName: _getAssociatedName(
          personnels,
          transaction.personnelId,
              (personnel) => personnel.name,
        ),
        paymentTypeName: _getAssociatedName(
          paymentTypes,
          transaction.paymentTypeId,
              (type) => type.name,
        ),
      );
    }).toList();
  }


  static Future<void> generatePdf(
      WidgetRef ref,
      List<Transaction> transactions,
      double totalReceived,
      double totalPaid,
      double totalBalance
      ) async {
    // Pre-fetch enhanced transactions
    final enhancedTransactions = await _prepareEnhancedTransactions(ref, transactions);

    final pdf = pw.Document();

    final logoImage = await imageFromAssetBundle('img/Logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logoImage),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Rapport des Transactions Détaillé',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Enhanced Transaction Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue100,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Détails',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Reçu',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Payé',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Transaction rows
                    ...enhancedTransactions.map((enhancedTransaction) {
                      final transaction = enhancedTransaction.transaction;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(transaction.transactionDate),
                                ),
                                if (enhancedTransaction.accountName.isNotEmpty)
                                  pw.Text(
                                    '${enhancedTransaction.accountName}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                if (enhancedTransaction.chantierName.isNotEmpty)
                                  pw.Text(
                                    '${enhancedTransaction.chantierName}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                if (enhancedTransaction.personnelName.isNotEmpty)
                                  pw.Text(
                                    '${enhancedTransaction.personnelName}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                if (enhancedTransaction.paymentTypeName.isNotEmpty)
                                  pw.Text(
                                    '${enhancedTransaction.paymentTypeName}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                if (transaction.description != null &&
                                    transaction.description!.isNotEmpty)
                                  pw.Text(
                                      transaction.description!,
                                      style: const pw.TextStyle(fontSize: 9)
                                  ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: transaction.type == 'reçu'
                                ? pw.Text(
                              transaction.amount.toStringAsFixed(2),
                              style: pw.TextStyle(color: PdfColors.green700),
                            )
                                : pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: transaction.type == 'payé'
                                ? pw.Text(
                              transaction.amount.toStringAsFixed(2),
                              style: pw.TextStyle(color: PdfColors.red700),
                            )
                                : pw.Text(''),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // Summary section
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Résumé',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Reçu:'),
                        pw.Text(
                          '${totalReceived.toStringAsFixed(2)} Ar',
                          style: const pw.TextStyle(color: PdfColors.green700),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Payé:'),
                        pw.Text(
                          '${totalPaid.toStringAsFixed(2)} Ar',
                          style: const pw.TextStyle(color: PdfColors.red700),
                        ),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Solde Total:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${totalBalance.toStringAsFixed(2)} Ar',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: totalBalance >= 0
                                ? PdfColors.green700
                                : PdfColors.red700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdf.save(),
    );
  }

  // Rest of the code remains the same as in the previous implementation
  static void onTapPdf(WidgetRef ref, String selectedTimeframeFilter,
      DateTime? startDate, DateTime? endDate) async {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final transactionsAsync = ref.watch(transactionsStateProvider);

    if (transactionsAsync.hasValue) {
      final transactions = transactionsAsync.value!
          .where((t) => t.accountId == selectedAccount?.id)
          .toList();

      // Apply filter based on user's choice
      final filteredTransactions = _filterTransactions(
          transactions, selectedTimeframeFilter, startDate, endDate);

      // Calculate totals based on filtered transactions
      double totalReceived = 0;
      double totalPaid = 0;

      for (var transaction in filteredTransactions) {
        if (transaction.type == 'reçu') {
          totalReceived += transaction.amount;
        } else {
          totalPaid += transaction.amount;
        }
      }

      final balance = totalReceived - totalPaid;
      final totalBalance = balance + (selectedAccount?.solde ?? 0.0);

      await generatePdf(
          ref,
          filteredTransactions,
          totalReceived,
          totalPaid,
          totalBalance
      );
    }
  }

  // Transaction filtering method remains the same as in the previous implementation
  static List<Transaction> _filterTransactions(List<Transaction> transactions,
      String timeframeFilter, DateTime? startDate, DateTime? endDate) {
    DateTime now = DateTime.now();

    return transactions.where((transaction) {
      // Date range verification
      bool matchesDateRange = true;

      if (startDate != null && endDate != null) {
        // Create DateTime for the start and end of the day
        final startDateTime =
        DateTime(startDate.year, startDate.month, startDate.day);
        final endDateTime =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

        matchesDateRange = transaction.transactionDate.isAfter(startDateTime) &&
            transaction.transactionDate.isBefore(endDateTime);
      }

      // Timeframe verification
      bool matchesTimeframe = true;
      switch (timeframeFilter) {
        case 'Quotidien':
          matchesTimeframe = transaction.transactionDate.year == now.year &&
              transaction.transactionDate.month == now.month &&
              transaction.transactionDate.day == now.day;
          break;
        case 'Hebdomadaire':
          matchesTimeframe = transaction.transactionDate
              .isAfter(now.subtract(Duration(days: now.weekday - 1))) &&
              transaction.transactionDate
                  .isBefore(now.add(Duration(days: 7 - now.weekday)));
          break;
        case 'Mensuel':
          matchesTimeframe = transaction.transactionDate.year == now.year &&
              transaction.transactionDate.month == now.month;
          break;
        case 'Annuel':
          matchesTimeframe = transaction.transactionDate.year == now.year;
          break;
        case 'Tous':
        default:
          matchesTimeframe = true;
      }

      return matchesDateRange && matchesTimeframe;
    }).toList();
  }
}