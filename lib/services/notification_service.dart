import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationService {
  final _supabase = Supabase.instance.client;
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  // Get notifications for dropdown (limited to 10)
  Future<List<Map<String, dynamic>>> getNotificationsForDropdown() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            sender:sender_id (
              id,
              display_name,
              profile_photo_url
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Get unread count for badge
  Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Stream for real-time unread count updates
  Stream<int> unreadCountStream() {
    // Load initial value
    _updateUnreadCountStream();

    // Return the stream
    return _unreadCountController.stream;
  }

  // Helper to update the stream with current count
  Future<void> _updateUnreadCountStream() async {
    try {
      final count = await getUnreadCount();
      if (_unreadCountController.hasListener &&
          !_unreadCountController.isClosed) {
        _unreadCountController.add(count);
      }
    } catch (e) {
      print('Error updating unread count stream: $e');
      if (_unreadCountController.hasListener &&
          !_unreadCountController.isClosed) {
        _unreadCountController.add(0);
      }
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Update stream after marking as read
      await _updateUnreadCountStream();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      // Update stream after marking all as read
      await _updateUnreadCountStream();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? referenceId,
    String? senderId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'reference_id': referenceId,
        'sender_id': senderId,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update stream if notification is for current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        await _updateUnreadCountStream();
      }
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // First check if it's unread
      final response = await _supabase
          .from('notifications')
          .select('is_read')
          .eq('id', notificationId)
          .single();

      final isUnread = response['is_read'] == false;

      await _supabase.from('notifications').delete().eq('id', notificationId);

      // Only update stream if we deleted an unread notification
      if (isUnread) {
        await _updateUnreadCountStream();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get notification icon and color based on type
  static Map<String, dynamic> getNotificationIcon(String type) {
    switch (type) {
      case 'reaction':
        return {'icon': Icons.thumb_up, 'color': Colors.blue};
      case 'comment':
        return {'icon': Icons.comment, 'color': Colors.green};
      case 'comment_reaction':
        return {'icon': Icons.thumb_up_alt, 'color': Colors.purple};
      case 'follow':
        return {'icon': Icons.person_add, 'color': Colors.orange};
      default:
        return {'icon': Icons.notifications, 'color': Colors.grey};
    }
  }

  // Format time for display
  static String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  // Convenience method for creating reaction notification - UPDATED
  Future<void> createReactionNotification({
    required String postId,
    required String postTitle,
    required String targetUserId,
    required String senderName,
    required String reactionType,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser?.id == targetUserId) return;

      await createNotification(
        userId: targetUserId,
        type: 'reaction',
        title: 'New Reaction',
        message:
            '$senderName reacted with $reactionType to your post "$postTitle"',
        referenceId: postId,
        senderId: currentUser?.id,
      );

      // The createNotification method already updates the stream
      // for the target user, so no need to call _updateUnreadCountStream here
    } catch (e) {
      print('Error creating reaction notification: $e');
    }
  }

  // Convenience method for creating comment notification - UPDATED
  Future<void> createCommentNotification({
    required String postId,
    required String postTitle,
    required String targetUserId,
    required String senderName,
    String? commentPreview,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser?.id == targetUserId) return;

      final message = commentPreview != null
          ? '$senderName commented on your post "$postTitle": "$commentPreview"'
          : '$senderName commented on your post "$postTitle"';

      await createNotification(
        userId: targetUserId,
        type: 'comment',
        title: 'New Comment',
        message: message,
        referenceId: postId,
        senderId: currentUser?.id,
      );

      // The createNotification method already updates the stream
      // for the target user
    } catch (e) {
      print('Error creating comment notification: $e');
    }
  }

  // Add method to manually refresh the stream (useful for testing)
  Future<void> refreshUnreadCount() async {
    await _updateUnreadCountStream();
  }

  // Clean up stream controller
  void dispose() {
    if (!_unreadCountController.isClosed) {
      _unreadCountController.close();
    }
  }
}
