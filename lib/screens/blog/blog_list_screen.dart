import 'package:flutter/material.dart';
import '../../services/blog_service.dart'; // Add this import
import '../../models/blog_post.dart';
import '../../widgets/blog_card.dart';
import 'blog_detail_screen.dart'; // Keep import for modal

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<BlogPost> _blogs = [];
  bool _isLoading = true;
  final BlogService _blogService = BlogService(); // Add this

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    try {
      // Remove all the hardcoded data and fetch from database
      final posts = await _blogService.getBlogPosts(); // Call your BlogService

      setState(() {
        _blogs = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading blogs: $e');
      setState(() {
        _blogs = []; // Set to empty array instead of hardcoded data
        _isLoading = false;
      });
    }
  }

  void _viewBlogDetail(BlogPost blog) {
    // Show modal instead of navigating
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
  }

  void _editBlog(BlogPost blog) {
    // We'll implement this later
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit: ${blog.title}')));
  }

  void _deleteBlog(String blogId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blog'),
        content: const Text('Are you sure you want to delete this blog post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete from database
                await _blogService.deleteBlogPost(blogId);

                // Also remove from local state
                setState(() {
                  _blogs.removeWhere((blog) => blog.id == blogId);
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Blog deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting blog: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBlogs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _blogs.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No blogs yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to create a blog!',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            // This should also be updated to use modal
                            // but we'll keep it as is for now since CreateBlogScreen
                            // is already converted to modal in home_screen.dart
                            // If CreateBlogScreen is used elsewhere, it should also be converted
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Create blog modal is available from the home screen',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Blog'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _blogs.length,
                itemBuilder: (context, index) {
                  final blog = _blogs[index];
                  return BlogCard(
                    blog: blog,
                    onTap: () => _viewBlogDetail(blog),
                    onEdit: () => _editBlog(blog),
                    onDelete: () => _deleteBlog(blog.id),
                  );
                },
              ),
      ),
    );
  }
}
