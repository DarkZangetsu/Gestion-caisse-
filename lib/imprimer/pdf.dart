import 'package:caisse/models/transaction.dart';
import 'package:caisse/providers/accounts_provider.dart';
import 'package:caisse/providers/transactions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class ImpressionParPdf {
  static Future<void> generatePdf(List<Transaction> transactions,
      double totalReceived, double totalPaid, double totalBalance) async {
    final pdf = pw.Document();

    // Chargement de l'image locale
    final logoImage = await imageFromAssetBundle('img/Logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo
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
                        'Rapport des Transactions',
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

              // Tableau des transactions
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
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // En-tête du tableau
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue100,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Date',
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
                    // Lignes de données
                    ...transactions.map((transaction) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(transaction.transactionDate),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              transaction.type == 'reçu'
                                  ? transaction.amount.toStringAsFixed(2)
                                  : '-',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              transaction.type == 'payé'
                                  ? transaction.amount.toStringAsFixed(2)
                                  : '-',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Résumé
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

  static void onTapPdf(WidgetRef ref, String selectedTimeframeFilter,
      DateTime? startDate, DateTime? endDate) async {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final transactionsAsync = ref.watch(transactionsStateProvider);

    if (transactionsAsync.hasValue) {
      final transactions = transactionsAsync.value!
          .where((t) => t.accountId == selectedAccount?.id)
          .toList();

      // Appliquer le filtre en fonction du choix de l'utilisateur
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
          filteredTransactions, totalReceived, totalPaid, totalBalance);
    }
  }

// Ajoutez cette méthode pour filtrer les transactions
  static List<Transaction> _filterTransactions(List<Transaction> transactions,
      String timeframeFilter, DateTime? startDate, DateTime? endDate) {
    DateTime now = DateTime.now();

    return transactions.where((transaction) {
      // Vérification de la plage de dates
      bool matchesDateRange = true;

      if (startDate != null && endDate != null) {
        // Créer des DateTime pour le début et la fin de la journée
        final startDateTime =
            DateTime(startDate.year, startDate.month, startDate.day);
        final endDateTime =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

        matchesDateRange = transaction.transactionDate.isAfter(startDateTime) &&
            transaction.transactionDate.isBefore(endDateTime);
      }

      // Vérification du filtre temporel
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
          matchesTimeframe = true; // Inclure toutes les transactions
      }

      return matchesDateRange && matchesTimeframe;
    }).toList();
  }
}
