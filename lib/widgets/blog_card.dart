import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/blog_post.dart';
import '../widgets/reaction_button.dart';
import '../services/blog_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class BlogCard extends StatefulWidget {
  final BlogPost blog;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showReactions;
  final Function()? onRefresh; // Callback to refresh parent state

  const BlogCard({
    super.key,
    required this.blog,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showReactions = true,
    this.onRefresh,
  });

  @override
  State<BlogCard> createState() => _BlogCardState();
}

class _BlogCardState extends State<BlogCard> {
  late Map<String, dynamic> _reactionCounts;
  late String? _currentUserReaction;
  final BlogService _blogService = BlogService();
  final NotificationService _notificationService = NotificationService();
  bool _isReacting = false;

  @override
  void initState() {
    super.initState();
    // Initialize reaction data
    _reactionCounts = _parseReactionCounts(widget.blog);
    _currentUserReaction = widget.blog.currentUserReaction;
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

  Future<void> _handleReactionSelected(String reactionType) async {
    if (_isReacting) return;

    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to react to posts'),
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
    final authorInitial = widget.blog.authorName.isNotEmpty
        ? widget.blog.authorName.substring(0, 1).toUpperCase()
        : 'A';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.blog.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Content preview
              Text(
                widget.blog.content.length > 150
                    ? '${widget.blog.content.substring(0, 150)}...'
                    : widget.blog.content,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Images
              if (widget.blog.imageUrls.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.blog.imageUrls.length > 3
                        ? 3
                        : widget.blog.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            widget.blog.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (widget.blog.imageUrls.isNotEmpty) const SizedBox(height: 12),

              // Author and date
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue[100],
                    child:
                        widget.blog.authorPhoto != null &&
                            widget.blog.authorPhoto!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.blog.authorPhoto!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAuthorFallback(authorInitial);
                              },
                            ),
                          )
                        : _buildAuthorFallback(authorInitial),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.blog.authorName.isNotEmpty
                        ? widget.blog.authorName
                        : 'Anonymous',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.blog.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Reactions and comments section
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Reaction button
                  if (widget.showReactions)
                    ReactionButton(
                      currentReaction: _currentUserReaction,
                      reactionCounts: _reactionCounts,
                      onReactionSelected: _handleReactionSelected,
                      onReactionRemoved: _handleReactionRemoved,
                      isSmall: false,
                    ),

                  if (widget.showReactions) const SizedBox(width: 16),

                  // Comments
                  InkWell(
                    onTap: widget.onTap,
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 20,
                          color: widget.blog.commentCount > 0
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.blog.commentCount > 0
                              ? widget.blog.commentCount.toString()
                              : 'Comment',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.blog.commentCount > 0
                                ? Colors.blue
                                : Colors.grey[700],
                            fontWeight: widget.blog.commentCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Share button (optional)
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    onPressed: () {
                      // Implement share functionality
                    },
                    color: Colors.grey[600],
                  ),
                ],
              ),

              // Action buttons (if provided)
              if (widget.onEdit != null || widget.onDelete != null) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onEdit != null)
                      TextButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    if (widget.onDelete != null)
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorFallback(String initial) {
    return Container(
      color: Colors.blue[100],
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
}
