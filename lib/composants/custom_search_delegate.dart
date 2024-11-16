import 'package:caisse/composants/texts.dart';
import 'package:caisse/home_composantes/app_bar_action_list.dart';
import 'package:caisse/models/accounts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchableAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Account? selectedAccount;
  final Function() onAccountTap;
  final Function(String) onSearch;
  final void Function()? onTap;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function() onDateReset;
  final void Function()? onTapPdf;

  const SearchableAppBar({
    super.key,
    this.selectedAccount,
    required this.onAccountTap,
    required this.onSearch,
    required this.onTap,
    required this.onDateReset,
    this.startDate,
    this.endDate,
    this.onTapPdf,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchableAppBar> createState() => _SearchableAppBarState();
}

class _SearchableAppBarState extends State<SearchableAppBar> {
  bool isSearching = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _searchController.clear();
        widget.onSearch('');
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: const Color(0xffea6b24),
      title: isSearching ? _buildSearchField() : _buildTitle(),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.print),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pdf',
              onTap: widget.onTapPdf,
              child: const MyText(texte: 'Pdf'),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: _toggleSearch,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.date_range_outlined),
          iconColor: Colors.white,
          itemBuilder: (BuildContext context) {
            List<PopupMenuEntry<String>> menuItems = [
              PopupMenuItem<String>(
                value: 'date',
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xffea6b24),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MyText(
                        texte: widget.startDate != null &&
                                widget.endDate != null
                            ? '${DateFormat('dd/MM/yyyy').format(widget.startDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate!)}'
                            : 'Choisir une plage de dates',
                      ),
                    ),
                    if (widget.startDate != null && widget.endDate != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xffea6b24),
                          size: 18,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDateReset();
                        },
                      ),
                  ],
                ),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (widget.onTap != null) {
                      widget.onTap!();
                    }
                  });
                },
              ),
            ];
            return menuItems;
          },
        )
      ],
    );
  }

  Widget _buildTitle() {
    return TextButton(
      onPressed: widget.onAccountTap,
      child: Row(
        children: [
          Text(
            widget.selectedAccount?.name ?? 'Livre de Caisse',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          const Icon(Icons.arrow_drop_down_outlined, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16.0,
      ),
      onChanged: widget.onSearch,
      decoration: const InputDecoration(
        hintText: "Search...",
        hintStyle: TextStyle(color: Colors.white60),
        border: InputBorder.none,
      ),
    );
  }
}
