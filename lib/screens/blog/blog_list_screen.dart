import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/blog_service.dart';
import '../../services/storage_service.dart';
import '../../models/blog_post.dart';
import '../../widgets/blog_card.dart';
import '../../widgets/comment_card.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/comment.dart';

class BlogListScreen extends StatefulWidget {
  final VoidCallback? onBlogCreated;

  const BlogListScreen({super.key, this.onBlogCreated});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<BlogPost> _blogs = [];
  bool _isLoading = true;
  final BlogService _blogService = BlogService();

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    try {
      final posts = await _blogService.getBlogPosts();
      setState(() {
        _blogs = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _blogs = [];
        _isLoading = false;
      });
    }
  }

  void _viewBlogDetail(BlogPost blog) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Blog Post',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blog.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue[100],
                              child:
                                  blog.authorPhoto != null &&
                                      blog.authorPhoto!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        blog.authorPhoto!,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Text(
                                                blog.authorName.isNotEmpty
                                                    ? blog.authorName
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                    : 'A',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                      ),
                                    )
                                  : Text(
                                      blog.authorName.isNotEmpty
                                          ? blog.authorName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              blog.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          blog.content,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                        const SizedBox(height: 24),

                        if (blog.imageUrls.isNotEmpty) ...[
                          const Text(
                            'Images:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (blog.imageUrls.length == 1) ...[
                            Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                  maxHeight: 300,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    blog.imageUrls[0],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 300,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: blog.imageUrls.length,
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    blog.imageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],

                        // Add Comment Section Here
                        _buildCommentSection(blog),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentSection(BlogPost blog) {
    return FutureBuilder<List<Comment>>(
      future: _blogService.getComments(blog.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Error loading comments');
        }

        final comments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments (${comments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Add Comment Button
            ElevatedButton.icon(
              onPressed: () {
                _showAddCommentDialog(blog);
              },
              icon: const Icon(Icons.add_comment),
              label: const Text('Add Comment'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),

            // Comments List
            if (comments.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No comments yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be the first to comment!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentCard(comment: comment);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCommentDialog(BlogPost blog) async {
    final TextEditingController _commentController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Write your comment here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_commentController.text.trim().isNotEmpty) {
                  try {
                    await _blogService.createComment(
                      postId: blog.id,
                      content: _commentController.text.trim(),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comment added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh the dialog to show new comment
                    _viewBlogDetail(blog);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  void _editBlog(BlogPost blog) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.id != blog.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own blog posts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
  }

  void _deleteBlog(String blogId) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    final blog = _blogs.firstWhere((b) => b.id == blogId);

    if (currentUser == null || currentUser.id != blog.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own blog posts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
                await _blogService.deleteBlogPost(blogId);
                await _loadBlogs();
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
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (context) {
              return Theme(
                data: Theme.of(context),
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: CreateBlogModal(
                      onBlogCreated: () {
                        _loadBlogs();
                        if (widget.onBlogCreated != null) {
                          widget.onBlogCreated!();
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Blog published successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      onClose: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
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
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (context) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                            0.8,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.9,
                                      ),
                                      child: CreateBlogModal(
                                        onBlogCreated: () {
                                          _loadBlogs();
                                          if (widget.onBlogCreated != null) {
                                            widget.onBlogCreated!();
                                          }
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Blog published successfully!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                        onClose: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                  final isAuthor = authService.currentUser?.id == blog.userId;

                  return BlogCard(
                    blog: blog,
                    onTap: () => _viewBlogDetail(blog),
                    onEdit: isAuthor ? () => _editBlog(blog) : null,
                    onDelete: isAuthor ? () => _deleteBlog(blog.id) : null,
                    onRefresh: _loadBlogs,
                  );
                },
              ),
      ),
    );
  }
}

class CreateBlogModal extends StatefulWidget {
  final VoidCallback? onBlogCreated;
  final VoidCallback? onClose;

  const CreateBlogModal({super.key, this.onBlogCreated, this.onClose});

  @override
  State<CreateBlogModal> createState() => _CreateBlogModalState();
}

class _CreateBlogModalState extends State<CreateBlogModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _storageService = StorageService();
  final BlogService _blogService = BlogService();
  bool _isSubmitting = false;
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      final image = await _storageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    }
  }

  Future<void> _uploadImages() async {
    _uploadedImageUrls.clear();

    for (final image in _selectedImages) {
      try {
        final imageUrl = await _storageService.uploadImage(
          bucket: 'blog-images',
          imageFile: image,
        );
        _uploadedImageUrls.add(imageUrl);
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> _submitBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_selectedImages.isNotEmpty) {
        await _uploadImages();
      }

      await _blogService.createBlogPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: _uploadedImageUrls,
      );

      if (widget.onBlogCreated != null) {
        widget.onBlogCreated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }

    _titleController.clear();
    _contentController.clear();
    _selectedImages.clear();
    _uploadedImageUrls.clear();
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create New Blog',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blog Title',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    hintText: 'Enter a title...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length < 10) {
                      return 'Title should be at least 10 characters';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blog Content',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    hintText: 'Write your blog content here...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter blog content';
                    }
                    if (value.length < 50) {
                      return 'Content should be at least 50 characters';
                    }
                    return null;
                  },
                  maxLines: 6,
                  maxLength: 5000,
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Add Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Add Image',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedImages.length} image(s) selected',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4),
                                      ),
                                      Text(
                                        'Image ${index + 1}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBlog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Publish Blog',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
