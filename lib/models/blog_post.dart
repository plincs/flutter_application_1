import 'dart:convert';

class BlogPost {
  final String id;
  final String userId;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorName;
  final String? authorPhoto;
  final Map<String, dynamic>? reactions;
  final Map<String, dynamic>? userReaction;
  final int commentCount;

  final Map<String, dynamic>? reactionCounts;
  final String? currentUserReaction;

  int get totalReactions {
    if (reactionCounts != null && reactionCounts!.isNotEmpty) {
      int total = 0;
      reactionCounts!.forEach((key, value) {
        total += (value is int ? value : int.tryParse(value.toString()) ?? 0);
      });
      return total;
    }
    return 0;
  }

  int get likeCount {
    if (reactions != null && reactions!.isNotEmpty) {
      return reactions!['like'] as int? ?? 0;
    }
    if (reactionCounts != null && reactionCounts!.isNotEmpty) {
      return reactionCounts!['like'] as int? ?? 0;
    }
    return 0;
  }

  List<Map<String, dynamic>> get topReactions {
    final Map<String, dynamic> counts = reactionCounts ?? reactions ?? {};
    final List<Map<String, dynamic>> reactionsList = [];

    final Map<String, String> reactionEmojis = {
      'like': '👍',
      'love': '❤️',
      'laugh': '😂',
      'wow': '😲',
      'sad': '😢',
      'angry': '😠',
    };

    counts.forEach((reactionId, count) {
      if (count is int && count > 0) {
        reactionsList.add({
          'id': reactionId,
          'emoji': reactionEmojis[reactionId] ?? '👍',
          'count': count,
        });
      }
    });

    reactionsList.sort(
      (a, b) => (b['count'] as int).compareTo(a['count'] as int),
    );

    return reactionsList;
  }

  BlogPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    this.authorPhoto,
    this.reactions,
    this.userReaction,
    required this.commentCount,
    this.reactionCounts,
    this.currentUserReaction,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    // FIXED: Check for both possible formats
    // 1. From SQL function: direct author_name and author_photo_url fields
    // 2. From regular query: nested users object

    String? authorName;
    String? authorPhoto;

    // First check if author_name is directly in the JSON (from SQL function)
    if (json['author_name'] != null) {
      authorName = json['author_name'] as String;
      authorPhoto = json['author_photo_url'] as String?;
    }
    // Otherwise check for nested users object (from regular query)
    else if (json['users'] != null) {
      final users = json['users'] as Map<String, dynamic>?;
      authorName = users?['display_name'] as String?;
      authorPhoto = users?['profile_photo_url'] as String?;
    }
    // If neither, use user_id to look up later or default
    else {
      authorName = 'Unknown';
      authorPhoto = null;
    }

    Map<String, dynamic>? parsedReactionCounts;
    if (json['reactions'] != null) {
      if (json['reactions'] is Map<String, dynamic>) {
        parsedReactionCounts = json['reactions'] as Map<String, dynamic>;
      } else if (json['reactions'] is String) {
        try {
          parsedReactionCounts = Map<String, dynamic>.from(
            jsonDecode(json['reactions']),
          );
        } catch (e) {
          parsedReactionCounts = {};
        }
      }
    }

    String? currentUserReaction;
    // Check current_user_reaction field directly (from SQL function)
    if (json['current_user_reaction'] != null) {
      if (json['current_user_reaction'] is String) {
        currentUserReaction = json['current_user_reaction'] as String;
      } else if (json['current_user_reaction'] is Map<String, dynamic>) {
        currentUserReaction =
            json['current_user_reaction']['reaction_type'] as String?;
      }
    }
    // Also check user_reaction for backward compatibility
    else if (json['user_reaction'] != null) {
      if (json['user_reaction'] is Map<String, dynamic>) {
        currentUserReaction = json['user_reaction']['reaction_type'] as String?;
      }
    }

    return BlogPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: authorName ?? 'Unknown',
      authorPhoto: authorPhoto,
      reactions: parsedReactionCounts,
      userReaction: json['user_reaction'] as Map<String, dynamic>?,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      reactionCounts: parsedReactionCounts,
      currentUserReaction: currentUserReaction,
    );
  }

  BlogPost copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorPhoto,
    Map<String, dynamic>? reactions,
    Map<String, dynamic>? userReaction,
    int? commentCount,
    Map<String, dynamic>? reactionCounts,
    String? currentUserReaction,
  }) {
    return BlogPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      reactions: reactions ?? this.reactions,
      userReaction: userReaction ?? this.userReaction,
      commentCount: commentCount ?? this.commentCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
    );
  }

  BlogPost updateReactionCounts(Map<String, dynamic> newCounts) {
    return copyWith(reactionCounts: newCounts);
  }

  BlogPost updateUserReaction(String? reactionType) {
    return copyWith(currentUserReaction: reactionType);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author_name': authorName,
      'author_photo': authorPhoto,
      'reactions': reactions,
      'user_reaction': userReaction,
      'comment_count': commentCount,
      'reaction_counts': reactionCounts,
      'current_user_reaction': currentUserReaction,
    };
  }
}
