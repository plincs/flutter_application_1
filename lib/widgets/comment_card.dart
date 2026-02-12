import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../widgets/reaction_button.dart';
import '../services/blog_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class CommentCard extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showActions;
  final bool showReactions;

  const CommentCard({
    super.key,
    required this.comment,
    this.onDelete,
    this.onEdit,
    this.showActions = false,
    this.showReactions = true,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late Map<String, dynamic> _reactionCounts;
  late String? _currentUserReaction;
  final BlogService _blogService = BlogService();
  bool _isReacting = false;

  @override
  void initState() {
    super.initState();
    _initReactions();
  }

  // ADD THIS METHOD - Update when widget changes
  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the comment has changed
    if (oldWidget.comment.id != widget.comment.id ||
        oldWidget.comment.reactions != widget.comment.reactions ||
        oldWidget.comment.userReaction != widget.comment.userReaction) {
      _initReactions();
    }
  }

  // ADD THIS METHOD - Initialize reactions
  void _initReactions() {
    _reactionCounts = widget.comment.reactions ?? {};
    _currentUserReaction = _getUserReactionType(widget.comment.userReaction);
  }

  String? _getUserReactionType(Map<String, dynamic>? userReaction) {
    if (userReaction == null || userReaction.isEmpty) return null;
    return userReaction['type'] as String?;
  }

  Future<void> _handleReactionSelected(String reactionType) async {
    if (_isReacting) return;

    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to react to comments'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isReacting = true;
    });

    try {
      if (_currentUserReaction == reactionType) {
        await _blogService.removeCommentReaction(
          commentId: widget.comment.id,
          reactionTypeId: reactionType,
        );

        setState(() {
          _currentUserReaction = null;
          _reactionCounts[reactionType] =
              (_reactionCounts[reactionType] ?? 1) - 1;
          if (_reactionCounts[reactionType] <= 0) {
            _reactionCounts.remove(reactionType);
          }
        });
      } else {
        if (_currentUserReaction != null) {
          await _blogService.removeCommentReaction(
            commentId: widget.comment.id,
            reactionTypeId: _currentUserReaction!,
          );
        }

        await _blogService.reactToComment(
          commentId: widget.comment.id,
          reactionTypeId: reactionType,
        );

        setState(() {
          if (_currentUserReaction != null) {
            _reactionCounts[_currentUserReaction!] =
                (_reactionCounts[_currentUserReaction!] ?? 1) - 1;
            if (_reactionCounts[_currentUserReaction!] <= 0) {
              _reactionCounts.remove(_currentUserReaction!);
            }
          }
          _currentUserReaction = reactionType;
          _reactionCounts[reactionType] =
              (_reactionCounts[reactionType] ?? 0) + 1;
        });
      }
    } catch (e) {
      print('Error handling comment reaction: $e');
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
      await _blogService.removeCommentReaction(
        commentId: widget.comment.id,
        reactionTypeId: _currentUserReaction!,
      );

      setState(() {
        _reactionCounts[_currentUserReaction!] =
            (_reactionCounts[_currentUserReaction!] ?? 1) - 1;
        if (_reactionCounts[_currentUserReaction!] <= 0) {
          _reactionCounts.remove(_currentUserReaction!);
        }
        _currentUserReaction = null;
      });
    } catch (e) {
      print('Error removing comment reaction: $e');
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

  Widget _buildImagesGrid(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrls[0],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.comment.imageUrls ?? [];

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green[100],
                  child: widget.comment.authorPhoto != null
                      ? ClipOval(
                          child: Image.network(
                            widget.comment.authorPhoto!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.green[100],
                                child: Center(
                                  child: Text(
                                    widget.comment.authorName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          widget.comment.authorName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(widget.comment.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      // ADD THIS - Show "Edited" if comment was updated
                      if (widget.comment.updatedAt != null &&
                          widget.comment.updatedAt!.isAfter(
                            widget.comment.createdAt,
                          ))
                        Text(
                          ' (edited)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.showActions &&
                    (widget.onEdit != null || widget.onDelete != null))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: widget.onEdit,
                          color: Colors.grey[600],
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: widget.onDelete,
                          color: Colors.grey[600],
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (widget.comment.content != null &&
                widget.comment.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.comment.content!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            if (imageUrls.isNotEmpty) _buildImagesGrid(imageUrls),

            if (widget.showReactions) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ReactionButton(
                  currentReaction: _currentUserReaction,
                  reactionCounts: _reactionCounts,
                  onReactionSelected: _handleReactionSelected,
                  onReactionRemoved: _handleReactionRemoved,
                  isSmall: true,
                ),
              ),
            ],
          ],
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
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
