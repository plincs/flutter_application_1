import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/blog_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../models/blog_post.dart';
import '../../models/comment.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BlogService _blogService = BlogService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  int _postCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;

  late bool _notificationsEnabled;
  late bool _darkMode;
  late bool _autoPlayVideos;
  late bool _dataSaver;
  late String _language;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _autoPlayVideos = prefs.getBool('auto_play_videos') ?? true;
      _dataSaver = prefs.getBool('data_saver') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveAppSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('auto_play_videos', _autoPlayVideos);
    await prefs.setBool('data_saver', _dataSaver);
    await prefs.setString('language', _language);
  }

  Future<void> _loadUserStats() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final postCount = await _blogService.getUserBlogPostCount(
          currentUser.id,
        );

        final followerCount = await _userService.getFollowerCount(
          currentUser.id,
        );
        final followingCount = await _userService.getFollowingCount(
          currentUser.id,
        );

        setState(() {
          _postCount = postCount;
          _followerCount = followerCount;
          _followingCount = followingCount;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStats() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserStats();
  }

  void _showAccountSettings(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to access account settings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController emailController = TextEditingController(
      text: currentUser.email ?? '',
    );
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    bool isChangingEmail = false;
    bool isChangingPassword = false;
    bool isDeletingAccount = false;

    void changeEmail() async {
      final newEmail = emailController.text.trim();
      if (newEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a new email address'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        isChangingEmail = true;
      });

      try {
        await Future.delayed(const Duration(seconds: 2));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent to your new address'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isChangingEmail = false;
        });
      }
    }

    void changePassword() async {
      final currentPassword = currentPasswordController.text.trim();
      final newPassword = newPasswordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all password fields'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (newPassword.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New password must be at least 6 characters'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New passwords do not match'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        isChangingPassword = true;
      });

      try {
        await Future.delayed(const Duration(seconds: 2));

        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isChangingPassword = false;
        });
      }
    }

    void deleteAccount() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete your account?'),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone. All your data, blogs, comments, and reactions will be permanently deleted.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                setState(() {
                  isDeletingAccount = true;
                });

                try {
                  await Future.delayed(const Duration(seconds: 2));

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    isDeletingAccount = false;
                  });
                }
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Change Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isChangingEmail ? null : changeEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: isChangingEmail
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Change Email'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: currentPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: Icon(Icons.lock_reset),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isChangingPassword ? null : changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: isChangingPassword
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Change Password'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Account Management',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Once you delete your account, there is no going back. Please be certain.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isDeletingAccount ? null : deleteAccount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: isDeletingAccount
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Text('Delete Account'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person, size: 20),
                        title: const Text('User ID'),
                        subtitle: Text(
                          currentUser.id,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range, size: 20),
                        title: const Text('Account Created'),
                        subtitle: Text(
                          currentUser.createdAt.isNotEmpty
                              ? _formatDateTime(currentUser.createdAt)
                              : 'Unknown',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLikedPosts(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to view liked posts'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading liked posts...'),
            ],
          ),
        ),
      );

      final allPosts = await _blogService.getBlogPosts();

      print('Total posts loaded: ${allPosts.length}');
      for (var post in allPosts) {
        print('Post: ${post.title}, Reaction: ${post.currentUserReaction}');
      }

      final likedPosts = allPosts.where((post) {
        final hasReaction =
            post.currentUserReaction != null &&
            post.currentUserReaction!.isNotEmpty;
        if (hasReaction) {
          print(
            'Found liked post: ${post.title}, Reaction: ${post.currentUserReaction}',
          );
        }
        return hasReaction;
      }).toList();

      print('Found ${likedPosts.length} liked posts');

      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Liked Posts (${likedPosts.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: likedPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No liked posts yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start reacting to posts you enjoy!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: likedPosts.length,
                          itemBuilder: (context, index) {
                            final post = likedPosts[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                leading: post.imageUrls.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          post.imageUrls[0],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image,
                                                  ),
                                                );
                                              },
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.article),
                                      ),
                                title: Text(
                                  post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'By ${post.authorName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(post.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (post.currentUserReaction != null)
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: _getReactionEmoji(
                                          post.currentUserReaction!,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return Text(
                                              snapshot.data!['emoji'] ?? '👍',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            );
                                          }
                                          return const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 20,
                                          );
                                        },
                                      )
                                    else
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showBlogDetails(post);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error loading liked posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading liked posts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _getReactionEmoji(String reactionTypeId) async {
    try {
      final reactionTypes = await _blogService.getReactionTypes();
      return reactionTypes.firstWhere(
        (type) => type['id'] == reactionTypeId,
        orElse: () => {'emoji': '👍'},
      );
    } catch (e) {
      print('Error getting reaction emoji: $e');
      return {'emoji': '👍'};
    }
  }

  Future<void> _showMyComments(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to view your comments'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your comments...'),
            ],
          ),
        ),
      );

      final allPosts = await _blogService.getBlogPosts();
      final userComments = <Map<String, dynamic>>[];

      for (final post in allPosts) {
        try {
          final comments = await _blogService.getComments(post.id);
          final userPostComments = comments
              .where((comment) {
                return comment.userId == currentUser.id;
              })
              .map((comment) {
                return {'comment': comment, 'post': post};
              })
              .toList();

          userComments.addAll(userPostComments);
        } catch (e) {
          print('Error loading comments for post ${post.id}: $e');
        }
      }

      userComments.sort((a, b) {
        return b['comment'].createdAt.compareTo(a['comment'].createdAt);
      });

      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Comments (${userComments.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: userComments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start commenting on posts!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: userComments.length,
                          itemBuilder: (context, index) {
                            final data = userComments[index];
                            final comment = data['comment'] as Comment;
                            final post = data['post'] as BlogPost;

                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.comment,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  'On: ${post.title}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.content ?? '[Image Comment]',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(comment.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showBlogDetails(post);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppSettingsDialog(BuildContext context) {
    final List<String> languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Japanese',
      'Korean',
      'Chinese',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'App Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        subtitle: const Text(
                          'Receive notifications for new interactions',
                        ),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Display',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Enable dark theme'),
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(_language),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select Language'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: languages.length,
                                  itemBuilder: (context, index) {
                                    final lang = languages[index];
                                    return RadioListTile<String>(
                                      title: Text(lang),
                                      value: lang,
                                      groupValue: _language,
                                      onChanged: (value) {
                                        setState(() {
                                          _language = value!;
                                        });
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Media',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Auto-play Videos'),
                        subtitle: const Text(
                          'Automatically play videos in feed',
                        ),
                        value: _autoPlayVideos,
                        onChanged: (value) {
                          setState(() {
                            _autoPlayVideos = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Data Usage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Data Saver'),
                        subtitle: const Text(
                          'Reduce data usage by loading lower quality images',
                        ),
                        value: _dataSaver,
                        onChanged: (value) {
                          setState(() {
                            _dataSaver = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.orange,
                        ),
                        title: const Text('Clear Cache'),
                        subtitle: const Text('Clear temporary app data'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Cache'),
                              content: const Text(
                                'Are you sure you want to clear app cache?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cache cleared successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _notificationsEnabled = true;
                                  _darkMode = false;
                                  _autoPlayVideos = true;
                                  _dataSaver = false;
                                  _language = 'English';
                                });
                              },
                              child: const Text('Reset to Defaults'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _saveAppSettings();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Settings saved successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save Settings'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    final TextEditingController supportController = TextEditingController();
    bool isSubmitting = false;

    void sendSupportRequest() async {
      if (supportController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your message'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        isSubmitting = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Support request sent successfully! We\'ll get back to you soon.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Help & Support',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildFAQItems(context),

                      const SizedBox(height: 20),

                      const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: supportController,
                        decoration: const InputDecoration(
                          labelText: 'Describe your issue',
                          hintText: 'Tell us what you need help with...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Other ways to contact us:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.email, color: Colors.blue),
                            onPressed: () {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'support@aniblog.com',
                                queryParameters: {
                                  'subject': 'AniBlog Support Request',
                                },
                              );
                              launchUrl(emailLaunchUri);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              launchUrl(Uri.parse('tel:+1234567890'));
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.language,
                              color: Colors.purple,
                            ),
                            onPressed: () {
                              launchUrl(Uri.parse('https://aniblog.com/help'));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Send Button
                      if (isSubmitting)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: sendSupportRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Send Support Request'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFAQItems(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': 'How do I create a blog post?',
        'answer':
            'Tap the + button in the bottom navigation bar or the "Write Your First Blog" button on the home screen.',
      },
      {
        'question': 'Can I edit my blog post after publishing?',
        'answer':
            'Yes, you can edit your blog posts by clicking the edit button on your own posts.',
      },
      {
        'question': 'How do I change my profile picture?',
        'answer':
            'Go to your profile, tap "Edit Profile", then tap on your profile picture to choose a new one.',
      },
      {
        'question': 'Are there any posting guidelines?',
        'answer':
            'Yes, please keep content respectful and appropriate. No spam, harassment, or illegal content.',
      },
      {
        'question': 'How do I report inappropriate content?',
        'answer':
            'Tap the three dots menu on any post or comment and select "Report".',
      },
    ];

    return faqs.map((faq) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          title: Text(
            faq['question']!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq['answer']!,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<Uint8List?> _pickProfileImage() async {
    try {
      final imageSource = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );

      if (imageSource != null) {
        final image = await _picker.pickImage(
          source: imageSource,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          return bytes;
        }
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        return bytes;
      }
      return null;
    }
  }

  void _navigateToMyBlogs() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final userBlogs = await _blogService.getUserBlogPosts(currentUser.id);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('My Blogs'),
            content: SizedBox(
              width: double.maxFinite,
              child: userBlogs.isEmpty
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No blogs yet'),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: userBlogs.length,
                      itemBuilder: (context, index) {
                        final blog = userBlogs[index];
                        return ListTile(
                          title: Text(blog.title),
                          subtitle: Text(
                            'Published: ${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showBlogDetails(blog);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error loading user blogs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading blogs'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBlogDetails(BlogPost blog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(blog.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(blog.content, style: const TextStyle(fontSize: 14)),
              if (blog.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Images:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...blog.imageUrls.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthService authService) {
    final TextEditingController displayNameController = TextEditingController(
      text: authService.displayName ?? '',
    );
    final TextEditingController bioController = TextEditingController(
      text: authService.bio ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    Uint8List? selectedImageBytes;
    XFile? selectedImageFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: isUpdating
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: isUpdating
                              ? null
                              : () async {
                                  final imageSource =
                                      await showModalBottomSheet<ImageSource>(
                                        context: context,
                                        builder: (context) => SafeArea(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.photo_library,
                                                ),
                                                title: const Text(
                                                  'Choose from Gallery',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(
                                                    context,
                                                    ImageSource.gallery,
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.camera_alt,
                                                ),
                                                title: const Text(
                                                  'Take a Photo',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(
                                                    context,
                                                    ImageSource.camera,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );

                                  if (imageSource != null) {
                                    final image = await _picker.pickImage(
                                      source: imageSource,
                                      maxWidth: 800,
                                      maxHeight: 800,
                                      imageQuality: 85,
                                    );

                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      setState(() {
                                        selectedImageBytes = bytes;
                                        selectedImageFile = image;
                                      });
                                    }
                                  }
                                },
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: selectedImageBytes != null
                                      ? Image.memory(
                                          selectedImageBytes!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : authService.profilePhotoUrl != null &&
                                            authService
                                                .profilePhotoUrl!
                                                .isNotEmpty
                                      ? Image.network(
                                          authService.profilePhotoUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.blue[100],
                                                  child: Center(
                                                    child: Text(
                                                      (authService.displayName ??
                                                              '?')
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          color: Colors.blue[100],
                                          child: Center(
                                            child: Text(
                                              (authService.displayName ?? '?')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (!isUpdating)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (selectedImageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New image selected',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: isUpdating
                                    ? null
                                    : () {
                                        setState(() {
                                          selectedImageBytes = null;
                                          selectedImageFile = null;
                                        });
                                      },
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: displayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a display name';
                                }
                                if (value.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                              enabled: !isUpdating,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: bioController,
                              decoration: const InputDecoration(
                                labelText: 'Bio (Optional)',
                                prefixIcon: Icon(Icons.info),
                                border: OutlineInputBorder(),
                                hintText: 'Tell us about yourself...',
                              ),
                              maxLines: 3,
                              enabled: !isUpdating,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isUpdating)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() {
                                    isUpdating = true;
                                  });

                                  try {
                                    String? profilePhotoUrl;

                                    if (selectedImageFile != null) {
                                      profilePhotoUrl = await _storageService
                                          .uploadImage(
                                            bucket: 'profile-images',
                                            imageFile: selectedImageFile!,
                                          );
                                    }

                                    final currentUserId =
                                        authService.currentUser?.id;

                                    if (currentUserId != null) {
                                      await _userService.updateUserProfile(
                                        displayName: displayNameController.text,
                                        bio: bioController.text.isNotEmpty
                                            ? bioController.text
                                            : null,

                                        profilePhotoUrl:
                                            profilePhotoUrl ??
                                            authService.profilePhotoUrl,
                                      );
                                    }

                                    await authService.loadCurrentUser();

                                    await _loadUserStats();

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error updating profile: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isUpdating = false;
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays < 7) {
        return '${DateFormat('EEEE').format(date)} at ${DateFormat('h:mm a').format(date)}';
      } else {
        return DateFormat('MMM d, yyyy - h:mm a').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated;

    return RefreshIndicator(
      onRefresh: _refreshStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    backgroundImage: authService.profilePhotoUrl != null
                        ? NetworkImage(authService.profilePhotoUrl!)
                        : null,
                    child: authService.profilePhotoUrl == null
                        ? Text(
                            (authService.displayName ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    authService.displayName ?? 'Guest',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),

                  if (authService.email != null)
                    Text(
                      authService.email!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),

                  if (authService.bio != null && authService.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        authService.bio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      _showEditProfileDialog(context, authService);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: _postCount > 0 ? _navigateToMyBlogs : null,
                          child: _buildStatItem('Posts', _postCount.toString()),
                        ),
                        _buildStatItem('Followers', _followerCount.toString()),
                        _buildStatItem('Following', _followingCount.toString()),
                      ],
                    ),
            ),

            const SizedBox(height: 8),
            if (!_isLoading && _postCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Start writing your first blog!',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Account Settings',
                    onTap: () => _showAccountSettings(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.article_outlined,
                    title: 'My Blogs',
                    onTap: _navigateToMyBlogs,
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite_border,
                    title: 'Liked Posts',
                    onTap: () => _showLikedPosts(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.comment_outlined,
                    title: 'My Comments',
                    onTap: () => _showMyComments(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'App Settings',
                    onTap: () => _showAppSettingsDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => _showHelpAndSupport(context),
                  ),
                  if (isLoggedIn)
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      color: Theme.of(context).colorScheme.error,
                      onTap: () {
                        _showLogoutDialog(context, authService);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
