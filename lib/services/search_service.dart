import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_post.dart';

class SearchService {
  final _supabase = Supabase.instance.client;

  Future<List<BlogPost>> searchBlogs(String query) async {
    print('🔍 Searching for: "$query"');

    try {
      if (query.isEmpty) {
        return [];
      }

      final searchLower = query.toLowerCase();

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

      if (response == null) {
        return [];
      }

      final allPosts = (response as List).cast<Map<String, dynamic>>();

      if (allPosts.isEmpty) {
        return [];
      }

      // Filter by search query
      final filteredPosts = allPosts.where((post) {
        final title = (post['title'] as String?)?.toLowerCase() ?? '';
        final content = (post['content'] as String?)?.toLowerCase() ?? '';
        return title.contains(searchLower) || content.contains(searchLower);
      }).toList();

      print('Found ${filteredPosts.length} matching posts for "$query"');

      // Convert to BlogPost objects
      return filteredPosts.map((post) {
        final usersData = post['users'] as Map<String, dynamic>?;

        // Create JSON that matches your BlogPost structure
        final json = <String, dynamic>{
          'id': post['id'] as String? ?? '',
          'user_id': post['user_id'] as String? ?? '',
          'title': post['title'] as String? ?? '',
          'content': post['content'] as String? ?? '',
          'image_urls': post['image_urls'] as List<dynamic>? ?? [],
          'created_at':
              post['created_at'] as String? ?? DateTime.now().toIso8601String(),
          'updated_at':
              post['updated_at'] as String? ?? DateTime.now().toIso8601String(),
          'comment_count': 0,
          'reactions': <String, dynamic>{},
          'user_reaction': null,
          'reaction_counts': null,
          'current_user_reaction': null,
        };

        // Add author info - use the field names from your debug output
        if (usersData != null) {
          json['author_name'] =
              usersData['display_name'] as String? ?? 'Unknown';
          json['author_photo_url'] = usersData['profile_photo_url'] as String?;
        } else {
          json['author_name'] = 'Unknown';
          json['author_photo_url'] = null;
        }

        try {
          return BlogPost.fromJson(json);
        } catch (e) {
          print('Error creating BlogPost: $e');
          print('JSON: $json');

          // Fallback: create BlogPost manually
          return BlogPost(
            id: json['id'] as String,
            userId: json['user_id'] as String,
            title: json['title'] as String,
            content: json['content'] as String,
            imageUrls: List<String>.from(
              json['image_urls'] as List<dynamic>? ?? [],
            ),
            createdAt: DateTime.parse(json['created_at'] as String),
            updatedAt: DateTime.parse(json['updated_at'] as String),
            authorName: json['author_name'] as String,
            authorPhoto: json['author_photo_url'] as String?,
            commentCount: 0,
          );
        }
      }).toList();
    } catch (e) {
      print('Error searching blogs: $e');
      return [];
    }
  }

  Future<List<String>> getTrendingSearches() async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('title')
          .order('created_at', ascending: false)
          .limit(5);

      if (response == null) {
        return [];
      }

      final titles = (response as List).cast<Map<String, dynamic>>();
      return titles.map((item) => item['title'] as String).toList();
    } catch (e) {
      print('Error getting trending searches: $e');
      return [];
    }
  }
}
