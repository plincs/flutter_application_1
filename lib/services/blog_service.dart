import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_post.dart';
import '../models/comment.dart';

// Timeout extension for PostgrestQueryBuilder
extension PostgrestQueryTimeout on PostgrestQueryBuilder {
  Future<dynamic> timeout(Duration duration) {
    return then((value) => value).timeout(duration);
  }
}

class BlogService {
  final _supabase = Supabase.instance.client;

  // ============ SEARCH METHODS ============

  // Advanced search with filters
  Future<List<BlogPost>> searchBlogs({
    required String query,
    String? authorId,
    DateTime? fromDate,
    DateTime? toDate,
    int? minReactions,
    int? maxReactions,
    bool sortByReactions = false,
    bool sortByDate = true,
  }) async {
    try {
      // Get all blog posts
      final allBlogs = await getBlogPosts();

      // Apply search query filter
      List<BlogPost> filteredBlogs = allBlogs.where((blog) {
        final matchesQuery =
            query.isEmpty ||
            blog.title.toLowerCase().contains(query.toLowerCase()) ||
            blog.content.toLowerCase().contains(query.toLowerCase()) ||
            blog.authorName.toLowerCase().contains(query.toLowerCase());

        final matchesAuthor = authorId == null || blog.userId == authorId;

        final matchesDateRange =
            (fromDate == null || blog.createdAt.isAfter(fromDate)) &&
            (toDate == null || blog.createdAt.isBefore(toDate));

        final matchesReactions =
            (minReactions == null || blog.totalReactions >= minReactions) &&
            (maxReactions == null || blog.totalReactions <= maxReactions);

        return matchesQuery &&
            matchesAuthor &&
            matchesDateRange &&
            matchesReactions;
      }).toList();

      // Apply sorting
      if (sortByReactions) {
        filteredBlogs.sort(
          (a, b) => b.totalReactions.compareTo(a.totalReactions),
        );
      } else if (sortByDate) {
        filteredBlogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return filteredBlogs;
    } catch (e) {
      print('Error in advanced search: $e');
      return [];
    }
  }

  // Search by tags (if you add tags to your blog posts)
  Future<List<BlogPost>> searchByTags(List<String> tags) async {
    try {
      final allBlogs = await getBlogPosts();

      return allBlogs.where((blog) {
        // If you add tags to your BlogPost model, implement this
        // For now, search in title and content
        return tags.any(
          (tag) =>
              blog.title.toLowerCase().contains(tag.toLowerCase()) ||
              blog.content.toLowerCase().contains(tag.toLowerCase()),
        );
      }).toList();
    } catch (e) {
      print('Error searching by tags: $e');
      return [];
    }
  }

  // Simple search method (for quick searches)
  Future<List<BlogPost>> searchBlogsSimple(String query) async {
    if (query.isEmpty) {
      return await getBlogPosts();
    }

    try {
      final allBlogs = await getBlogPosts();

      return allBlogs.where((blog) {
        final titleMatch = blog.title.toLowerCase().contains(
          query.toLowerCase(),
        );
        final contentMatch = blog.content.toLowerCase().contains(
          query.toLowerCase(),
        );
        final authorMatch = blog.authorName.toLowerCase().contains(
          query.toLowerCase(),
        );

        return titleMatch || contentMatch || authorMatch;
      }).toList();
    } catch (e) {
      print('Error in simple search: $e');
      return [];
    }
  }

  // ============ EXISTING METHODS (keep all your existing code below) ============

  // Get ALL blog posts WITH comment count AND reaction counts
  // In BlogService.dart, update the getBlogPosts() method:
  Future<List<BlogPost>> getBlogPosts() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      // Try to use the RPC function first
      try {
        final response = await _supabase.rpc(
          'get_blog_posts_with_counts',
          params: {'user_id_param': currentUserId},
        );

        if (response != null && response is List) {
          final posts = response.cast<Map<String, dynamic>>();

          // DEBUG: Print the response to see the structure
          print('DEBUG - First blog post structure:');
          if (posts.isNotEmpty) {
            print(posts[0].keys.toList()); // Print all keys
            print('author_name: ${posts[0]['author_name']}');
            print('author_photo_url: ${posts[0]['author_photo_url']}');
          }

          // Sort by created_at descending
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
          throw Exception('Invalid response from RPC function');
        }
      } catch (e) {
        print('Error getting blog posts with RPC function: $e');
        // Fallback to original method
        return await _getBlogPostsFallback();
      }
    } catch (e) {
      print('Error getting blog posts: $e');
      return await _getBlogPostsFallback();
    }
  }

  // Get blog posts by specific user WITH comment count AND reaction counts
  Future<List<BlogPost>> getUserBlogPosts(String userId) async {
    try {
      // Use fallback method until RPC function is fully working
      return await _getUserBlogPostsFallback(userId);
    } catch (e) {
      print('Error getting user blog posts: $e');
      return await _getUserBlogPostsFallback(userId);
    }
  }

  // Get current user's blog posts WITH comment count AND reaction countsFuture<List<BlogPost>> getBlogPosts() async
  Future<List<BlogPost>> getCurrentUserBlogPosts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return await getUserBlogPosts(user.id);
    } catch (e) {
      print('Error getting current user blog posts: $e');
      rethrow;
    }
  }

  // Get blog post with comment count and reaction data
  Future<BlogPost> getBlogPost(String id) async {
    try {
      // Use fallback method for single post
      return await _getBlogPostFallback(id);
    } catch (e) {
      print('Error getting blog post: $e');
      rethrow;
    }
  }

  // Fallback method for getting single blog post
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

      // Handle the list response
      if (response.isNotEmpty) {
        final json = response[0];

        // Get comment count
        final commentCount = await _getCommentCountForPost(postId);
        json['comment_count'] = commentCount;

        // Get reaction data
        final reactionData = await getBlogPostReactions(postId);
        json['reactions'] = {'total': reactionData['total']};
        json['current_user_reaction'] = reactionData['current_user_reaction'];

        return BlogPost.fromJson(json);
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      print('Error in fallback blog post method: $e');
      rethrow;
    }
  }

  // Fallback method if function doesn't exist
  Future<List<BlogPost>> _getBlogPostsFallback() async {
    try {
      // Get all blog posts with user info
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

      // Get all posts
      final posts = (response as List).cast<Map<String, dynamic>>();

      if (posts.isEmpty) return [];

      // Get post IDs
      final postIds = posts.map((p) => p['id'] as String).toList();

      // Get comment counts for all posts
      final commentCounts = await _getCommentCountsForPosts(postIds);

      // Get reaction data for all posts (only total counts)
      final reactionDataMap = <String, Map<String, dynamic>>{};
      for (final postId in postIds) {
        final reactionData = await getBlogPostReactions(postId);
        reactionDataMap[postId] = {
          'total': reactionData['total'],
          'current_user_reaction': reactionData['current_user_reaction'],
        };
      }

      // Create BlogPost objects with comment counts and reaction data
      return posts.map((json) {
        final postId = json['id'] as String;

        // Add comment count
        json['comment_count'] = commentCounts[postId] ?? 0;

        // Add reaction data (only total and user reaction)
        final reactionData = reactionDataMap[postId] ?? {};
        json['reactions'] = {'total': reactionData['total'] ?? 0};
        json['current_user_reaction'] = reactionData['current_user_reaction'];

        return BlogPost.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error in fallback blog posts method: $e');
      rethrow;
    }
  }

  // Fallback for user blog posts
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

      // Get post IDs
      final postIds = posts.map((p) => p['id'] as String).toList();

      // Get comment counts for all posts
      final commentCounts = await _getCommentCountsForPosts(postIds);

      // Get reaction data for all posts (only total counts)
      final reactionDataMap = <String, Map<String, dynamic>>{};
      for (final postId in postIds) {
        final reactionData = await getBlogPostReactions(postId);
        reactionDataMap[postId] = {
          'total': reactionData['total'],
          'current_user_reaction': reactionData['current_user_reaction'],
        };
      }

      // Create BlogPost objects
      return posts.map((json) {
        final postId = json['id'] as String;

        // Add comment count
        json['comment_count'] = commentCounts[postId] ?? 0;

        // Add reaction data
        final reactionData = reactionDataMap[postId] ?? {};
        json['reactions'] = {'total': reactionData['total'] ?? 0};
        json['current_user_reaction'] = reactionData['current_user_reaction'];

        return BlogPost.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error in fallback user blog posts method: $e');
      rethrow;
    }
  }

  // Helper method to get comment counts for multiple posts
  Future<Map<String, int>> _getCommentCountsForPosts(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};

    try {
      // Get all comments for these posts
      final response = await _supabase
          .from('comments')
          .select('post_id')
          .inFilter('post_id', postIds);

      final comments = (response as List).cast<Map<String, dynamic>>();

      // Count comments per post
      final counts = <String, int>{};
      for (final comment in comments) {
        final postId = comment['post_id'] as String;
        counts[postId] = (counts[postId] ?? 0) + 1;
      }

      // Ensure all postIds have an entry (even if 0)
      for (final postId in postIds) {
        counts.putIfAbsent(postId, () => 0);
      }

      return counts;
    } catch (e) {
      print('Error getting comment counts: $e');
      return {};
    }
  }

  // Helper method to get comment count for a single post
  Future<int> _getCommentCountForPost(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      print('Error getting comment count for post: $e');
      return 0;
    }
  }

  // Create blog post
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

      // Add comment count (will be 0 for new post)
      final json = response;
      json['comment_count'] = 0;
      json['reactions'] = {'total': 0};
      json['current_user_reaction'] = null;

      return BlogPost.fromJson(json);
    } catch (e) {
      print('Error creating blog post: $e');
      rethrow;
    }
  }

  // Update blog post
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

      // Get comment count
      final commentCount = await _getCommentCountForPost(id);
      json['comment_count'] = commentCount;

      // Get reaction data
      final reactionData = await getBlogPostReactions(id);
      json['reactions'] = {'total': reactionData['total']};
      json['current_user_reaction'] = reactionData['current_user_reaction'];

      return BlogPost.fromJson(json);
    } catch (e) {
      print('Error updating blog post: $e');
      rethrow;
    }
  }

  // Get blog post count for a user
  Future<int> getUserBlogPostCount(String userId) async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select()
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting user blog post count: $e');
      return 0;
    }
  }

  // Delete a blog post
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
      print('Error deleting blog post: $e');
      rethrow;
    }
  }

  // Get comments
  // In blog_service.dart
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
      print('Error getting comments: $e');
      return []; // Return empty array on error
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  // Create comment
  Future<Comment> createComment({
    required String postId,
    String? content,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check that at least content or imageUrl is provided
      if ((content == null || content.isEmpty) && imageUrl == null) {
        throw Exception('Comment must have either text or image');
      }

      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': user.id,
            'content': content,
            'image_url': imageUrl,
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
      print('Error creating comment: $e');
      rethrow;
    }
  }

  // Update comment
  Future<Comment> updateComment({
    required String id,
    String? content,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check that at least content or imageUrl is provided
      if ((content == null || content.isEmpty) && imageUrl == null) {
        throw Exception('Comment must have either text or image');
      }

      final response = await _supabase
          .from('comments')
          .update({'content': content, 'image_url': imageUrl})
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
      print('Error updating comment: $e');
      rethrow;
    }
  }

  // Delete comment
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
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // Get reaction types
  Future<List<Map<String, dynamic>>> getReactionTypes() async {
    try {
      final response = await _supabase
          .from('reaction_types')
          .select()
          .order('id');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting reaction types: $e');
      return [];
    }
  }

  // React to a blog post
  Future<Map<String, dynamic>> reactToBlogPost({
    required String postId,
    required String reactionTypeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First, check if user already has a reaction
      final existingReaction = await _supabase
          .from('blog_post_reactions')
          .select('reaction_type_id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingReaction != null) {
        final existingTypeId = existingReaction['reaction_type_id'] as String;

        // If same reaction, remove it
        if (existingTypeId == reactionTypeId) {
          await removeBlogPostReaction(
            postId: postId,
            reactionTypeId: reactionTypeId,
          );
          return await getBlogPostReactions(postId);
        } else {
          // Update existing reaction to new type
          await _supabase
              .from('blog_post_reactions')
              .update({'reaction_type_id': reactionTypeId})
              .eq('post_id', postId)
              .eq('user_id', user.id);

          return await getBlogPostReactions(postId);
        }
      } else {
        // Create new reaction
        await _supabase.from('blog_post_reactions').insert({
          'post_id': postId,
          'user_id': user.id,
          'reaction_type_id': reactionTypeId,
        });

        return await getBlogPostReactions(postId);
      }
    } catch (e) {
      print('Error reacting to blog post: $e');
      rethrow;
    }
  }

  // Remove reaction from blog post
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
      print('Error removing blog post reaction: $e');
      rethrow;
    }
  }

  // Get blog post reactions
  Future<Map<String, dynamic>> getBlogPostReactions(String postId) async {
    try {
      final user = _supabase.auth.currentUser;

      // Get all reactions for this post
      final response = await _supabase
          .from('blog_post_reactions')
          .select('reaction_type_id, user_id')
          .eq('post_id', postId);

      // Handle the response as a list
      final reactions = response;
      final total = reactions.length;

      // Get user's reaction if logged in
      String? currentUserReaction;
      if (user != null && reactions.isNotEmpty) {
        // Use a for loop instead of firstWhere to avoid null return issue
        for (final reaction in reactions) {
          if (reaction['user_id'] == user.id) {
            currentUserReaction = reaction['reaction_type_id'] as String;
            break;
          }
        }
      }

      return {'total': total, 'current_user_reaction': currentUserReaction};
    } catch (e) {
      print('Error getting blog post reactions: $e');
      return {'total': 0, 'current_user_reaction': null};
    }
  }

  // React to a comment
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
      print('Error reacting to comment: $e');
      rethrow;
    }
  }

  // Remove reaction from comment
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
      print('Error removing comment reaction: $e');
      rethrow;
    }
  }

  // Get comment reactions with user's reaction
  Future<Map<String, dynamic>> getCommentReactions(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;

      // Get all reactions for this comment
      final response = await _supabase
          .from('comment_reactions')
          .select('reaction_type_id, user_id')
          .eq('comment_id', commentId);

      final reactions = response;
      final total = reactions.length;

      // Get user's reaction if logged in
      String? currentUserReaction;
      if (user != null && reactions.isNotEmpty) {
        // Use a for loop instead of firstWhere
        for (final reaction in reactions) {
          if (reaction['user_id'] == user.id) {
            currentUserReaction = reaction['reaction_type_id'] as String;
            break;
          }
        }
      }

      return {'total': total, 'current_user_reaction': currentUserReaction};
    } catch (e) {
      print('Error getting comment reactions: $e');
      return {'total': 0, 'current_user_reaction': null};
    }
  }
}
