import 'package:caisse/models/accounts.dart';
import 'package:caisse/pages/home_page.dart';
import 'package:flutter/material.dart';

class SearchableAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Account? selectedAccount;
  final Function() onAccountTap;
  final Function(String) onSearch;

  const SearchableAppBar({
    Key? key,
    this.selectedAccount,
    required this.onAccountTap,
    required this.onSearch,
  }) : super(key: key);

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

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _searchController.clear();
        widget.onSearch(''); // Clear search
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xffea6b24),
      title: isSearching ? _buildSearchField() : _buildTitle(),
      actions: [
        const AppbarActionList(
          icon: Icons.list_alt_outlined,
          color: Colors.white,
        ),
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: _toggleSearch,
        ),
        const MyPopupMenuButton(),
      ],
    );
  }
}