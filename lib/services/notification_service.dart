import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationService {
  final _supabase = Supabase.instance.client;
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

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

  Stream<int> unreadCountStream() {
    _updateUnreadCountStream();

    return _unreadCountController.stream;
  }

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

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      await _updateUnreadCountStream();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      await _updateUnreadCountStream();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

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

      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        await _updateUnreadCountStream();
      }
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('is_read')
          .eq('id', notificationId)
          .single();

      final isUnread = response['is_read'] == false;

      await _supabase.from('notifications').delete().eq('id', notificationId);

      if (isUnread) {
        await _updateUnreadCountStream();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

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
    } catch (e) {
      print('Error creating reaction notification: $e');
    }
  }

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
    } catch (e) {
      print('Error creating comment notification: $e');
    }
  }

  Future<void> refreshUnreadCount() async {
    await _updateUnreadCountStream();
  }

  void dispose() {
    if (!_unreadCountController.isClosed) {
      _unreadCountController.close();
    }
  }
}
