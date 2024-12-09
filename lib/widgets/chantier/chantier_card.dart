import 'package:flutter/material.dart';
import 'package:gestion_caisse_flutter/models/chantier.dart';
import 'package:intl/intl.dart';

class ChantierCard extends StatelessWidget {
  final Chantier chantier;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRefresh;

  const ChantierCard({
    super.key,
    required this.chantier,
    required this.onTap,
    required this.onDelete,
    this.onRefresh,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatBudget(double? budget) {
    if (budget == null) return 'N/A';
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'Ar',
      decimalDigits: 2,
    ).format(budget);
  }

  Color _getStatusColor(BuildContext context) {
    if (chantier.endDate == null || chantier.startDate == null) {
      return Colors.grey;
    }

    final now = DateTime.now();
    if (now.isBefore(chantier.startDate!)) {
      return Colors.orange;
    } else if (now.isAfter(chantier.endDate!)) {
      return Colors.red;
    }
    return Colors.green;
  }

  String _getStatus() {
    if (chantier.endDate == null || chantier.startDate == null) {
      return 'Non planifié';
    }

    final now = DateTime.now();
    if (now.isBefore(chantier.startDate!)) {
      return 'À venir';
    } else if (now.isAfter(chantier.endDate!)) {
      return 'Terminé';
    }
    return 'En cours';
  }

  Widget _buildDateRange(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.date_range,
            size: isSmallScreen ? 16 : 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Période',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatDate(chantier.startDate),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: isSmallScreen ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _formatDate(chantier.endDate),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.primary,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0,
        vertical: 8.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  chantier.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showOptionsMenu(context);
                          },
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        //color: _getStatusColor(context).withOpacity(0.1),
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),

                      ),
                      child: Text(
                        _getStatus(),
                        style: TextStyle(
                          color: _getStatusColor(context),
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _buildInfoItem(
                          context,
                          Icons.account_balance_wallet,
                          'Budget',
                          _formatBudget(chantier.budgetMax),
                          isSmallScreen,
                        ),
                        if (chantier.startDate != null ||
                            chantier.endDate != null)
                          _buildDateRange(context, isSmallScreen),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Material(
                  color: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: theme.primaryColor.withOpacity(0.1),
                    child: Text(
                      'ID: ${chantier.id}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book_sharp, color: Colors.blue),
              title: const Text(
                'Consulter transaction',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                // Use chantier.id instead of undefined chantierId
                Navigator.pushNamed(
                    context,
                    '/transaction',
                    arguments: {'chantierId': chantier.id}
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xffea6b24)),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }



  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment supprimer ce chantier ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
                onRefresh?.call();
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isSmallScreen,
  ) {
    return Container(
      constraints: BoxConstraints(
        minWidth: isSmallScreen ? 130 : 150,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 16 : 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
