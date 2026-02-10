import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_post.dart';
import '../models/comment.dart';

class BlogService {
  final _supabase = Supabase.instance.client;

  Future<List<BlogPost>> getBlogPosts() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      try {
        final response = await _supabase.rpc(
          'get_blog_posts_with_counts',
          params: {'user_id_param': currentUserId},
        );

        if (response != null && response is List) {
          final posts = response.cast<Map<String, dynamic>>();

          posts.sort((a, b) {
            try {
              final aDate = DateTime.parse(a['created_at'] as String);
              final bDate = DateTime.parse(b['created_at'] as String);
              return bDate.compareTo(aDate);
            } catch (e) {
              return 0;
            }
          });

          return posts.map((json) => BlogPost.fromJson(json)).toList();
        } else {
          return await _getBlogPostsFallback();
        }
      } catch (e) {
        return await _getBlogPostsFallback();
      }
    } catch (e) {
      return await _getBlogPostsFallback();
    }
  }

  Future<List<BlogPost>> getUserBlogPosts(String userId) async {
    try {
      return await _getUserBlogPostsFallback(userId);
    } catch (e) {
      return await _getUserBlogPostsFallback(userId);
    }
  }

  Future<List<BlogPost>> getCurrentUserBlogPosts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      return await getUserBlogPosts(user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<BlogPost> getBlogPost(String id) async {
    try {
      return await _getBlogPostFallback(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<BlogPost> _getBlogPostFallback(String postId) async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .eq('id', postId);

      if (response.isNotEmpty) {
        final json = response[0];

        final commentCount = await _getCommentCountForPost(postId);
        json['comment_count'] = commentCount;

        final reactionData = await getBlogPostReactions(postId);
        json['reactions'] = {'total': reactionData['total']};
        json['current_user_reaction'] = reactionData['current_user_reaction'];

        return BlogPost.fromJson(json);
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BlogPost>> _getBlogPostsFallback() async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .order('created_at', ascending: false);

      final posts = (response as List).cast<Map<String, dynamic>>();

      if (posts.isEmpty) return [];

      final postIds = posts.map((p) => p['id'] as String).toList();

      final commentCounts = await _getCommentCountsForPosts(postIds);

      final reactionDataMap = <String, Map<String, dynamic>>{};
      for (final postId in postIds) {
        final reactionData = await getBlogPostReactions(postId);
        reactionDataMap[postId] = {
          'total': reactionData['total'],
          'current_user_reaction': reactionData['current_user_reaction'],
        };
      }

      return posts.map((json) {
        final postId = json['id'] as String;

        json['comment_count'] = commentCounts[postId] ?? 0;

        final reactionData = reactionDataMap[postId] ?? {};
        json['reactions'] = {'total': reactionData['total'] ?? 0};
        json['current_user_reaction'] = reactionData['current_user_reaction'];

        return BlogPost.fromJson(json);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BlogPost>> _getUserBlogPostsFallback(String userId) async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final posts = (response as List).cast<Map<String, dynamic>>();

      if (posts.isEmpty) return [];

      final postIds = posts.map((p) => p['id'] as String).toList();

      final commentCounts = await _getCommentCountsForPosts(postIds);

      final reactionDataMap = <String, Map<String, dynamic>>{};
      for (final postId in postIds) {
        final reactionData = await getBlogPostReactions(postId);
        reactionDataMap[postId] = {
          'total': reactionData['total'],
          'current_user_reaction': reactionData['current_user_reaction'],
        };
      }

      return posts.map((json) {
        final postId = json['id'] as String;

        json['comment_count'] = commentCounts[postId] ?? 0;

        final reactionData = reactionDataMap[postId] ?? {};
        json['reactions'] = {'total': reactionData['total'] ?? 0};
        json['current_user_reaction'] = reactionData['current_user_reaction'];

        return BlogPost.fromJson(json);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, int>> _getCommentCountsForPosts(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};

    try {
      final response = await _supabase
          .from('comments')
          .select('post_id')
          .inFilter('post_id', postIds);

      final comments = (response as List).cast<Map<String, dynamic>>();

      final counts = <String, int>{};
      for (final comment in comments) {
        final postId = comment['post_id'] as String;
        counts[postId] = (counts[postId] ?? 0) + 1;
      }

      for (final postId in postIds) {
        counts.putIfAbsent(postId, () => 0);
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  Future<int> _getCommentCountForPost(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<BlogPost> createBlogPost({
    required String title,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('blog_posts')
          .insert({
            'user_id': user.id,
            'title': title,
            'content': content,
            'image_urls': imageUrls ?? [],
          })
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .single();

      final json = response;
      json['comment_count'] = 0;
      json['reactions'] = {'total': 0};
      json['current_user_reaction'] = null;

      return BlogPost.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<BlogPost> updateBlogPost({
    required String id,
    required String title,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('blog_posts')
          .update({
            'title': title,
            'content': content,
            'image_urls': imageUrls ?? [],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', user.id)
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .single();

      final json = response;

      final commentCount = await _getCommentCountForPost(id);
      json['comment_count'] = commentCount;

      final reactionData = await getBlogPostReactions(id);
      json['reactions'] = {'total': reactionData['total']};
      json['current_user_reaction'] = reactionData['current_user_reaction'];

      return BlogPost.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUserBlogPostCount(String userId) async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select()
          .eq('user_id', userId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteBlogPost(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('blog_posts')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
          *,
          users:user_id(
            id,
            email,
            display_name,
            profile_photo_url
          )
        ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Comment> createComment({
    required String postId,
    String? content,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if ((content == null || content.isEmpty) &&
          (imageUrls == null || imageUrls.isEmpty)) {
        throw Exception('Comment must have either text or image');
      }

      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': user.id,
            'content': content,
            'image_urls': imageUrls ?? [],
          })
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .single();

      return Comment.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Comment> updateComment({
    required String id,
    String? content,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if ((content == null || content.isEmpty) &&
          (imageUrls == null || imageUrls.isEmpty)) {
        throw Exception('Comment must have either text or image');
      }

      final response = await _supabase
          .from('comments')
          .update({'content': content, 'image_urls': imageUrls})
          .eq('id', id)
          .eq('user_id', user.id)
          .select('''
            *,
            users:user_id(
              id,
              email,
              display_name,
              profile_photo_url
            )
          ''')
          .single();

      return Comment.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReactionTypes() async {
    try {
      final response = await _supabase
          .from('reaction_types')
          .select()
          .order('id');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> reactToBlogPost({
    required String postId,
    required String reactionTypeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final existingReaction = await _supabase
          .from('blog_post_reactions')
          .select('reaction_type_id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingReaction != null) {
        final existingTypeId = existingReaction['reaction_type_id'] as String;

        if (existingTypeId == reactionTypeId) {
          await removeBlogPostReaction(
            postId: postId,
            reactionTypeId: reactionTypeId,
          );
          return await getBlogPostReactions(postId);
        } else {
          await _supabase
              .from('blog_post_reactions')
              .update({'reaction_type_id': reactionTypeId})
              .eq('post_id', postId)
              .eq('user_id', user.id);

          return await getBlogPostReactions(postId);
        }
      } else {
        await _supabase.from('blog_post_reactions').insert({
          'post_id': postId,
          'user_id': user.id,
          'reaction_type_id': reactionTypeId,
        });

        return await getBlogPostReactions(postId);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeBlogPostReaction({
    required String postId,
    required String reactionTypeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('blog_post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .eq('reaction_type_id', reactionTypeId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBlogPostReactions(String postId) async {
    try {
      final user = _supabase.auth.currentUser;

      final response = await _supabase
          .from('blog_post_reactions')
          .select('reaction_type_id, user_id')
          .eq('post_id', postId);

      final reactions = response;
      final total = reactions.length;

      String? currentUserReaction;
      if (user != null && reactions.isNotEmpty) {
        for (final reaction in reactions) {
          if (reaction['user_id'] == user.id) {
            currentUserReaction = reaction['reaction_type_id'] as String;
            break;
          }
        }
      }

      return {'total': total, 'current_user_reaction': currentUserReaction};
    } catch (e) {
      return {'total': 0, 'current_user_reaction': null};
    }
  }

  Future<Map<String, dynamic>> reactToComment({
    required String commentId,
    required String reactionTypeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('comment_reactions')
          .upsert({
            'comment_id': commentId,
            'user_id': user.id,
            'reaction_type_id': reactionTypeId,
          }, onConflict: 'comment_id,user_id,reaction_type_id')
          .select()
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCommentReaction({
    required String commentId,
    required String reactionTypeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('comment_reactions')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', user.id)
          .eq('reaction_type_id', reactionTypeId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommentReactions(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;

      final response = await _supabase
          .from('comment_reactions')
          .select('reaction_type_id, user_id')
          .eq('comment_id', commentId);

      final reactions = response;
      final total = reactions.length;

      String? currentUserReaction;
      if (user != null && reactions.isNotEmpty) {
        for (final reaction in reactions) {
          if (reaction['user_id'] == user.id) {
            currentUserReaction = reaction['reaction_type_id'] as String;
            break;
          }
        }
      }

      return {'total': total, 'current_user_reaction': currentUserReaction};
    } catch (e) {
      return {'total': 0, 'current_user_reaction': null};
    }
  }

  Future<void> refreshUserProfilePhoto(
    String userId,
    String newPhotoUrl,
  ) async {
    try {
      return;
    } catch (e) {
      print('Error refreshing profile photo in posts: $e');
    }
  }

  Future<List<BlogPost>> refreshBlogPostsWithUpdatedProfile(
    String userId,
    String newPhotoUrl,
  ) async {
    try {
      return await getBlogPosts();
    } catch (e) {
      print('Error refreshing posts with updated profile: $e');
      return await getBlogPosts();
    }
  }

  // Added from your version - this updates cached author info in posts
  Future<void> updateAuthorInfoInPosts({
    required String userId,
    String? newDisplayName,
    String? newProfilePhotoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (newDisplayName != null) {
        updates['author_name'] = newDisplayName;
      }
      if (newProfilePhotoUrl != null) {
        updates['author_photo_url'] = newProfilePhotoUrl;
      }

      if (updates.isEmpty) return;

      await _supabase.from('blog_posts').update(updates).eq('user_id', userId);
    } catch (e) {
      print('Error updating author info in posts: $e');
    }
  }
}
