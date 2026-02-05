import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/blog_post.dart';
import '../../models/comment.dart';
import '../../widgets/comment_card.dart';
import '../../widgets/reaction_button.dart';
import '../../services/blog_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class BlogDetailModal extends StatefulWidget {
  final BlogPost blog;
  final VoidCallback? onClose;
  final Function()? onRefresh; // Callback to refresh parent state

  const BlogDetailModal({
    super.key,
    required this.blog,
    this.onClose,
    this.onRefresh,
  });

  @override
  State<BlogDetailModal> createState() => _BlogDetailModalState();
}

class _BlogDetailModalState extends State<BlogDetailModal> {
  final BlogService _blogService = BlogService();
  final NotificationService _notificationService = NotificationService();
  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  bool _isReacting = false;

  late Map<String, dynamic> _reactionCounts;
  late String? _currentUserReaction;

  @override
  void initState() {
    super.initState();
    // Initialize reaction data
    _reactionCounts = _parseReactionCounts(widget.blog);
    _currentUserReaction = widget.blog.currentUserReaction;
    _loadComments();
  }

  // Parse reaction counts from blog post
  Map<String, dynamic> _parseReactionCounts(BlogPost blog) {
    if (blog.reactions != null) {
      // If reactions is already a map with 'total'
      return blog.reactions!;
    }
    // If reactionCounts exists
    if (blog.reactionCounts != null) {
      return blog.reactionCounts!;
    }
    // Default empty
    return {'total': 0};
  }

  // Get total reactions count
  int _getTotalReactions() {
    if (_reactionCounts['total'] != null) {
      return _reactionCounts['total'] as int;
    }

    // Fallback: calculate from individual counts
    int total = 0;
    _reactionCounts.forEach((key, value) {
      if (key != 'total') {
        total += (value is int ? value : int.tryParse(value.toString()) ?? 0);
      }
    });
    return total;
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _blogService.getComments(widget.blog.id);

      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _comments = [];
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _handleReactionSelected(String reactionType) async {
    if (_isReacting) return;

    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to react to posts'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isReacting = true;
    });

    try {
      // Call the blog service to add/update reaction
      final result = await _blogService.reactToBlogPost(
        postId: widget.blog.id,
        reactionTypeId: reactionType,
      );

      // Update local state with new data
      setState(() {
        _reactionCounts = {'total': result['total']};
        _currentUserReaction = result['current_user_reaction'];
      });

      // Send notification if user reacted to someone else's post
      final currentUser = authService.currentUser;
      if (currentUser != null &&
          currentUser.id != widget.blog.userId &&
          result['current_user_reaction'] != null) {
        await _notificationService.createReactionNotification(
          postId: widget.blog.id,
          postTitle: widget.blog.title,
          targetUserId: widget.blog.userId,
          senderName: authService.displayName ?? 'Someone',
          reactionType: reactionType,
        );
      }

      // Notify parent to refresh if needed
      widget.onRefresh?.call();
    } catch (e) {
      print('Error handling reaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isReacting = false;
      });
    }
  }

  Future<void> _handleReactionRemoved() async {
    if (_currentUserReaction == null || _isReacting) return;

    setState(() {
      _isReacting = true;
    });

    try {
      // Remove the reaction
      await _blogService.removeBlogPostReaction(
        postId: widget.blog.id,
        reactionTypeId: _currentUserReaction!,
      );

      // Get updated reaction data
      final result = await _blogService.getBlogPostReactions(widget.blog.id);

      // Update local state
      setState(() {
        _reactionCounts = {'total': result['total']};
        _currentUserReaction = result['current_user_reaction'];
      });

      // Notify parent to refresh if needed
      widget.onRefresh?.call();
    } catch (e) {
      print('Error removing reaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isReacting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Theme(
        data: Theme.of(context), // Ensure dialog uses current theme
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Blog Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.blog.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Author and Date
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: widget.blog.authorPhoto != null
                                  ? NetworkImage(widget.blog.authorPhoto!)
                                  : null,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              child: widget.blog.authorPhoto == null
                                  ? Text(
                                      widget.blog.authorName.isNotEmpty
                                          ? widget.blog.authorName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.blog.authorName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _formatDate(widget.blog.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Images Gallery
                        if (widget.blog.imageUrls.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.blog.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(
                                    right:
                                        index < widget.blog.imageUrls.length - 1
                                        ? 8
                                        : 0,
                                  ),
                                  width: 300,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        widget.blog.imageUrls[index],
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        if (widget.blog.imageUrls.isNotEmpty)
                          const SizedBox(height: 20),

                        // Content
                        Text(
                          widget.blog.content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_comments.length} comments',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_calculateReadTime(widget.blog.content)} min read',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons (Reaction, Comment, Share)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Reaction Button
                              ReactionButton(
                                currentReaction: _currentUserReaction,
                                reactionCounts: _reactionCounts,
                                onReactionSelected: _handleReactionSelected,
                                onReactionRemoved: _handleReactionRemoved,
                                isSmall: false,
                              ),

                              // Comment Button
                              InkWell(
                                onTap: () {
                                  // Scroll to comments or show comment input
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Add comment feature coming soon!',
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.comment_outlined,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.blog.commentCount}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Share Button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.share_outlined,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Comments Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Add Comment Button
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Add comment feature coming soon!',
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.add_comment,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              label: Text(
                                'Add Comment',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Comments List
                            _isLoadingComments
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  )
                                : _comments.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 48,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No comments yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Be the first to comment!',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListView.separated(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: _comments.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            height: 1,
                                            color: Theme.of(
                                              context,
                                            ).dividerColor,
                                            indent: 16,
                                            endIndent: 16,
                                          ),
                                      itemBuilder: (context, index) {
                                        final comment = _comments[index];
                                        return Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: CommentCard(comment: comment),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  int _calculateReadTime(String content) {
    final words = content.split(' ');
    final readTime = (words.length / 200).ceil();
    return readTime < 1 ? 1 : readTime;
  }
}

// Helper function to show the modal
void showBlogDetailModal(
  BuildContext context,
  BlogPost blog, {
  Function()? onRefresh,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      return Theme(
        data: Theme.of(context), // Wrap with Theme to ensure dark mode
        child: BlogDetailModal(blog: blog, onRefresh: onRefresh),
      );
    },
  );
}
