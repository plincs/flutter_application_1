import 'dart:async';
import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../models/blog_post.dart';
import '../widgets/blog_card.dart';
import 'home_screen.dart'; // This imports BlogDetailModal

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  List<BlogPost> _searchResults = [];
  bool _isLoading = false;
  bool _isInitial = true;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    print('🔍 Performing search for: "$query"');

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
        _isInitial = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isInitial = false;
    });

    try {
      final results = await _searchService.searchBlogs(query);
      print('✅ Search returned ${results.length} results');

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    // Start new timer (debounce)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: const InputDecoration(
              hintText: 'Search blog posts...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            autofocus: true,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
                _searchFocusNode.requestFocus();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitial) {
      return _buildInitialView();
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching for "${_searchController.text}"...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final blog = _searchResults[index];
        return BlogCard(
          blog: blog,
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (context) {
                return BlogDetailModal(
                  blog: blog,
                  onClose: () {
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInitialView() {
    return FutureBuilder<List<String>>(
      future: _searchService.getTrendingSearches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trendingSearches = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Trending Searches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (trendingSearches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No trending searches',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trendingSearches.map((search) {
                  return ActionChip(
                    label: Text(search),
                    onPressed: () {
                      _searchController.text = search;
                      _performSearch(search);
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            const Text(
              'Search Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSearchTips(),
          ],
        );
      },
    );
  }

  Widget _buildSearchTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Search effectively:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildTipItem('Use specific keywords'),
          _buildTipItem('Try different word combinations'),
          _buildTipItem('Check spelling if no results'),
          _buildTipItem('Use quotes for exact phrases'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
