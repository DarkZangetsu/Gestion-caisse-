import 'package:gestion_caisse_flutter/composants/empty_transaction_view.dart';
import 'package:gestion_caisse_flutter/composants/tab_header.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/home_composantes/transaction_row.dart';
import 'package:gestion_caisse_flutter/models/transaction.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:gestion_caisse_flutter/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/selected_chantier_provider.dart';

class TransactionPage extends ConsumerStatefulWidget {
  final String chantierId;
  const TransactionPage({super.key, required this.chantierId});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  static const filterChoice = [
    "Tous",
    "Quotidien",
    "Hebdomadaire",
    "Mensuel",
    "Annuel"
  ];

  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  String _selectedTimeframeFilter = 'Tous';
  int _selectedFilterIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Loading transactions for chantierId: ${widget.chantierId}');
      ref
          .read(transactionStateProvider.notifier)
          .loadTransactionsByChantier(widget.chantierId);
    });
  }

  @override
  void dispose() {
    ref.read(transactionStateProvider.notifier).resetTransactions();
    super.dispose();
  }

  void _resetDate() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _showResetSnackBar();
  }

  void _showResetSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plage de dates réinitialisée')),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        setState(() => _searchQuery = '');
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  bool _isWithinTimeframe(DateTime date, String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'Quotidien':
        return _isSameDay(date, now);
      case 'Hebdomadaire':
        return _isInCurrentWeek(date, now);
      case 'Mensuel':
        return _isInCurrentMonth(date, now);
      case 'Annuel':
        return date.year == now.year;
      default:
        return true;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isInCurrentWeek(DateTime date, DateTime now) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  bool _isInCurrentMonth(DateTime date, DateTime now) {
    return date.year == now.year && date.month == now.month;
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2222),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => _buildDatePickerTheme(context, child),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildDatePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xffea6b24),
              onPrimary: Colors.white,
            ),
      ),
      child: Column(
        children: [
          if (child != null) Expanded(child: child),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _resetDate();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Réinitialiser',
                    style: TextStyle(color: Color(0xffea6b24)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((transaction) {
      final matchesChantier = transaction.chantierId == widget.chantierId;
      final matchesDateRange = _isWithinDateRange(transaction.transactionDate);
      final matchesSearchQuery = _matchesSearchQuery(transaction);
      final matchesTimeframe = _isWithinTimeframe(
        transaction.transactionDate,
        _selectedTimeframeFilter,
      );

      return matchesChantier &&
          matchesDateRange &&
          matchesSearchQuery &&
          matchesTimeframe;
    }).toList();
  }

  bool _isWithinDateRange(DateTime date) {
    if (_startDate == null || _endDate == null) return true;

    final startDateTime =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDateTime =
        DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

    return date.isAtSameMomentAs(startDateTime) ||
        date.isAtSameMomentAs(endDateTime) ||
        (date.isAfter(startDateTime) && date.isBefore(endDateTime));
  }

  bool _matchesSearchQuery(Transaction transaction) {
    return _searchQuery.isEmpty ||
        transaction.description
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ==
            true;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final transactionsAsync = ref.watch(transactionsStateProvider);
    bool _isSearching = false;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xffea6b24),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Transactions', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(
              Icons.date_range_outlined,
              color: Colors.white,
            ),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(isDarkMode),
            Expanded(
              child: _buildTransactionsList(transactionsAsync, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 60,
      color: const Color(0xffea6b24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterChoice.length,
        itemBuilder: (context, index) => _buildChoiceChip(index, isDarkMode),
      ),
    );
  }

  Widget _buildChoiceChip(int index, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        selectedColor: const Color(0xffea6b24),
        labelPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: Colors.white),
        label: Text(
          filterChoice[index],
          style: TextStyle(
            color: _selectedFilterIndex == index
                ? Colors.white
                : isDarkMode
                    ? Colors.grey[300]
                    : Colors.black,
            fontSize: 14.0,
          ),
        ),
        selected: _selectedTimeframeFilter == filterChoice[index],
        onSelected: (selected) => _onFilterSelected(selected, index),
      ),
    );
  }

  void _onFilterSelected(bool selected, int index) {
    setState(() {
      _selectedFilterIndex = selected ? index : 0;
      _selectedTimeframeFilter = selected ? filterChoice[index] : 'Tous';
    });
  }

  Widget _buildTransactionsList(
    AsyncValue<List<Transaction>> transactionsAsync,
    bool isDarkMode,
  ) {
    return transactionsAsync.when(
      data: (transactions) =>
          _buildTransactionsContent(transactions, isDarkMode),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('Erreur lors du chargement des transactions'),
      ),
    );
  }

  Widget _buildTransactionsContent(
      List<Transaction> transactions, bool isDarkMode) {
    if (transactions.isEmpty) return const EmptyTransactionView();

    final filteredTransactions = _filterTransactions(transactions);
    if (filteredTransactions.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsFound();
    }

    final totals = _calculateTotals(filteredTransactions);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildTransactionsTable(filteredTransactions, isDarkMode),
          ),
        ),
        _buildBottomSummary(totals.received, totals.paid, isDarkMode),
      ],
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé pour "$_searchQuery"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  ({double received, double paid}) _calculateTotals(
      List<Transaction> transactions) {
    var totalReceived = 0.0;
    var totalPaid = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == 'reçu') {
        totalReceived += transaction.amount;
      } else {
        totalPaid += transaction.amount;
      }
    }

    return (received: totalReceived, paid: totalPaid);
  }

  Widget _buildTransactionsTable(
      List<Transaction> transactions, bool isDarkMode) {
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final headerColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.2);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(headerColor!, textColor),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) => TransactionRow(
                transaction: transactions[index],
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(Color headerColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          TabHeader(
            flex: 2,
            text: 'Date',
            color: textColor,
          ),
          TabHeader(
            flex: 1,
            text: 'Reçu',
            textAlign: TextAlign.right,
            color: textColor,
          ),
          TabHeader(
            flex: 1,
            text: 'Payé',
            textAlign: TextAlign.right,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(
      double totalReceived, double totalPaid, bool isDarkMode) {
    final backgroundColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const MyText(
                    texte: "Total Reçu:",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  MyText(
                    texte: NumberFormat.currency(
                      locale: 'fr_FR',
                      symbol: 'Ar',
                      decimalDigits: 2,
                    ).format(totalReceived),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ],
              ),
              Row(
                children: [
                  const MyText(
                    texte: "Total Payé:",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  MyText(
                    texte: NumberFormat.currency(
                      locale: 'fr_FR',
                      symbol: 'Ar',
                      decimalDigits: 2,
                    ).format(totalPaid),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 8.0,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText(
                texte: 'Balance: ',
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(
                width: 4.0,
              ),
              MyText(
                  texte: "0.0 Ar", fontSize: 22.0, fontWeight: FontWeight.bold),
            ],
          )
        ],
      ),
    );
  }
}
