import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback? onFilter;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search blogs...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
          if (onFilter != null)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.grey),
              onPressed: onFilter,
            ),
        ],
      ),
    );
  }
}
