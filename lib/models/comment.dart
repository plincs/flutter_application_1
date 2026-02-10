class Comment {
  final String id;
  final String postId;
  final String userId;
  final String? content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final String authorName;
  final String? authorPhoto;
  final Map<String, dynamic>? reactions;
  final Map<String, dynamic>? userReaction;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.content,
    this.imageUrls,
    required this.createdAt,
    required this.authorName,
    this.authorPhoto,
    this.reactions,
    this.userReaction,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;

    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List<dynamic>)
          : (json['image_url'] != null ? [json['image_url'] as String] : null),
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: users?['display_name'] as String? ?? 'Unknown',
      authorPhoto: users?['profile_photo_url'] as String?,
      reactions: json['reactions'] as Map<String, dynamic>?,
      userReaction: json['user_reaction'] as Map<String, dynamic>?,
    );
  }
}
