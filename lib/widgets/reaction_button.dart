import 'package:flutter/material.dart';

class ReactionButton extends StatefulWidget {
  final String? currentReaction;
  final Map<String, dynamic>? reactionCounts;
  final Function(String) onReactionSelected;
  final Function()? onReactionRemoved;
  final bool isSmall;

  const ReactionButton({
    super.key,
    this.currentReaction,
    this.reactionCounts,
    required this.onReactionSelected,
    this.onReactionRemoved,
    this.isSmall = false,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  final List<Map<String, dynamic>> _reactionTypes = [
    {'id': 'like', 'emoji': '👍', 'name': 'Like', 'color': Colors.blue},
    {'id': 'love', 'emoji': '❤️', 'name': 'Love', 'color': Colors.pink},
    {'id': 'laugh', 'emoji': '😂', 'name': 'Laugh', 'color': Colors.amber},
    {'id': 'wow', 'emoji': '😲', 'name': 'Wow', 'color': Colors.orange},
    {'id': 'sad', 'emoji': '😢', 'name': 'Sad', 'color': Colors.blueGrey},
    {'id': 'angry', 'emoji': '😠', 'name': 'Angry', 'color': Colors.red},
  ];

  bool _isHovering = false;
  OverlayEntry? _reactionOverlay;
  final GlobalKey _buttonKey = GlobalKey();

  void _showReactionMenu() {
    if (_reactionOverlay != null) {
      _removeReactionOverlay();
      return;
    }

    final RenderBox renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _reactionOverlay = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _removeReactionOverlay,
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: position.dx - 100,
                  top: position.dy - 70,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: _reactionTypes.map((reaction) {
                          return GestureDetector(
                            onTap: () {
                              widget.onReactionSelected(reaction['id']);
                              _removeReactionOverlay();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: widget.currentReaction == reaction['id']
                                    ? reaction['color'].withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                reaction['emoji'],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(_buttonKey.currentContext!).insert(_reactionOverlay!);
  }

  void _removeReactionOverlay() {
    if (_reactionOverlay != null) {
      _reactionOverlay!.remove();
      _reactionOverlay = null;
    }
  }

  void _handleButtonClick() {
    if (widget.currentReaction == null) {
      // Show reaction menu on first click
      _showReactionMenu();
    } else {
      // Remove reaction on click if already has one
      widget.onReactionRemoved?.call();
    }
  }

  // FIXED: Show thumbs up icon when no reaction, emoji when reacted
  Widget _getReactionIcon() {
    if (widget.currentReaction == null) {
      // No reaction - show neutral thumbs up icon
      return Icon(
        Icons.thumb_up_alt_outlined,
        size: widget.isSmall ? 16 : 20,
        color: Colors.grey[600],
      );
    } else {
      // Has reaction - show the emoji
      final reaction = _reactionTypes.firstWhere(
        (r) => r['id'] == widget.currentReaction,
        orElse: () => _reactionTypes[0],
      );
      return Text(
        reaction['emoji'],
        style: TextStyle(fontSize: widget.isSmall ? 16 : 20),
      );
    }
  }

  Color _getCurrentReactionColor() {
    if (widget.currentReaction == null) return Colors.grey;
    final reaction = _reactionTypes.firstWhere(
      (r) => r['id'] == widget.currentReaction,
      orElse: () => _reactionTypes[0],
    );
    return reaction['color'];
  }

  // Get TOTAL reaction count (sum of all reactions)
  int _getTotalReactions() {
    if (widget.reactionCounts == null) return 0;

    // If it's already a total count (from simplified service)
    if (widget.reactionCounts!['total'] != null) {
      return widget.reactionCounts!['total'] as int;
    }

    // Otherwise calculate from individual counts
    int total = 0;
    widget.reactionCounts!.forEach((key, value) {
      total += (value is int ? value : int.tryParse(value.toString()) ?? 0);
    });
    return total;
  }

  @override
  void dispose() {
    _removeReactionOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalReactions = _getTotalReactions();
    final hasReaction = widget.currentReaction != null;
    final currentReactionColor = _getCurrentReactionColor();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _handleButtonClick,
        onLongPress: _showReactionMenu,
        child: Container(
          key: _buttonKey,
          padding: widget.isSmall
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasReaction
                ? currentReactionColor.withOpacity(0.1)
                : _isHovering
                ? Colors.blue.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasReaction
                  ? currentReactionColor
                  : _isHovering
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.transparent,
              width: hasReaction ? 1.5 : (_isHovering ? 1 : 0),
            ),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use icon for no reaction, emoji for reacted
              _getReactionIcon(),

              // Show total count if there are any reactions
              if (totalReactions > 0) ...[
                const SizedBox(width: 6),
                Text(
                  totalReactions.toString(),
                  style: TextStyle(
                    fontSize: widget.isSmall ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: hasReaction
                        ? currentReactionColor
                        : Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
