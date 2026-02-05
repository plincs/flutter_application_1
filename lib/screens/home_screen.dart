import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/blog_card.dart';
import '../widgets/profile_menu_dropdown.dart';
import '../widgets/comment_card.dart';
import '../services/blog_service.dart';
import '../services/storage_service.dart';
import '../models/blog_post.dart';
import '../models/comment.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'blog/blog_list_screen.dart';
import 'auth/login_screen.dart';
import 'auth/profile_screen.dart';
import '../widgets/anime_slider.dart';
import '../services/theme_provider.dart';
import '../services/search_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<BlogPost> _recentBlogs = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  OverlayEntry? _profileOverlayEntry;
  bool _showCreateBlogModal = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  @override
  void dispose() {
    _removeProfileDropdown();
    _hideCreateBlogModal();
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    try {
      final blogService = BlogService();
      final posts = await blogService.getBlogPosts();

      // Load recent posts
      if (mounted) {
        setState(() {
          _recentBlogs = posts.take(3).toList(); // Take first 3 as recent
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading blogs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      _showCreateBlogModalDialog();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final isLoggedIn = authService.isAuthenticated;
              final userName = authService.displayName ?? 'Guest';

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer, // ← FIXED
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.background, // ← FIXED
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoggedIn) ...[
                            Text(
                              'Welcome back, $userName 👋',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer, // ← FIXED
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Stay updated with the latest insights, and trends in Anime.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8), // ← FIXED
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _showCreateBlogModalDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary, // ← FIXED
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary, // ← FIXED
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Write Your First Blog'),
                            ),
                          ] else ...[
                            // For logged-out users
                            Text(
                              'First time in Aniblog?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer, // ← FIXED
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join our community of anime and share your knowledge with the world...',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8), // ← FIXED
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary, // ← FIXED
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary, // ← FIXED
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Create Account'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary, // ← FIXED
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ), // ← FIXED
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Sign In'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Blog stats or icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface, // ← FIXED
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withOpacity(0.1), // ← FIXED
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Featured Anime Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimeSlider(),
          ),

          const SizedBox(height: 20),

          // Recent Articles Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, // ← FIXED
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Articles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface, // ← FIXED
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      child: Text(
                        'Browse All',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary, // Optional: make consistent
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _recentBlogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _recentBlogs.length,
                        itemBuilder: (context, index) {
                          final blog = _recentBlogs[index];
                          return BlogCard(
                            blog: blog,
                            onTap: () => _viewBlogDetail(blog),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No articles yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to write an article!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showCreateBlogModalDialog();
            },
            child: const Text('Write First Article'),
          ),
        ],
      ),
    );
  }

  void _viewBlogDetail(BlogPost blog) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return BlogDetailModal(
          blog: blog,
          onClose: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Show create blog modal in the center
  void _showCreateBlogModalDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Theme(
          // Wrap with Theme
          data: Theme.of(context),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // ← FIX THIS
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: CreateBlogModal(
                onBlogCreated: () {
                  _loadBlogs();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blog published successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onClose: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Hide create blog modal
  void _hideCreateBlogModal() {
    if (_showCreateBlogModal) {
      setState(() {
        _showCreateBlogModal = false;
      });
    }
  }

  // ADD THIS METHOD: Settings Dialog
  void _showAppSettingsDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('App Settings'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dark Mode Toggle
                    ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                      title: Text(
                        themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // Notifications Settings
                    ListTile(
                      leading: const Icon(Icons.notifications_rounded),
                      title: const Text('Notifications'),
                      trailing: Switch(
                        value: authService.notificationsEnabled,
                        onChanged: (value) async {
                          await authService.updateNotificationSettings(
                            notificationsEnabled: value,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // Email Notifications
                    ListTile(
                      leading: const Icon(Icons.email_rounded),
                      title: const Text('Email Notifications'),
                      trailing: Switch(
                        value: authService.emailNotifications,
                        onChanged: (value) async {
                          await authService.updateNotificationSettings(
                            emailNotifications: value,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build notification popup menu
  Widget _buildNotificationPopup(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: SizedBox(
              width: 350,
              child: _NotificationDropdownContent(
                notificationService: _notificationService,
              ),
            ),
          ),
        ];
      },
      child: _buildNotificationBell(),
    );
  }

  Widget _buildNotificationBell() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isAuthenticated) return const SizedBox.shrink();

        return Consumer<NotificationService>(
          // Add Consumer for NotificationService
          builder: (context, notificationService, child) {
            return StreamBuilder<int>(
              // Change FutureBuilder to StreamBuilder
              stream: notificationService
                  .unreadCountStream(), // Add this method to NotificationService
              initialData: 0,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.displayName ?? 'Guest';
    final userEmail = authService.currentUser?.email;
    final profilePhotoUrl = authService.profilePhotoUrl;

    // FIXED: Use actual ProfileScreen instead of placeholder
    final screens = [
      _buildHomeContent(),
      const BlogListScreen(),
      _buildHomeContent(), // Create blog is now a modal
      const ProfileScreen(), // This is the FIX - using actual ProfileScreen
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_profileOverlayEntry != null) {
          _removeProfileDropdown();
          return false;
        }
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _currentIndex == 0
            ? AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AniBlog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome, $userName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.pushNamed(context, '/search');
                    },
                  ),
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      if (authService.isAuthenticated) {
                        return _buildNotificationPopup(context);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  _buildProfileAvatar(
                    context,
                    authService,
                    userName,
                    userEmail,
                    profilePhotoUrl,
                  ),
                ],
                bottom: _currentIndex == 0
                    ? PreferredSize(
                        preferredSize: const Size.fromHeight(48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              _TopNavButton(
                                label: 'For You',
                                isActive: true,
                                onTap: () {},
                              ),
                              const SizedBox(width: 12),
                              _TopNavButton(
                                label: 'Following',
                                isActive: false,
                                onTap: () {},
                              ),
                              const SizedBox(width: 12),
                              _TopNavButton(
                                label: 'Trending',
                                isActive: false,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              )
            : AppBar(
                title: Text(_getAppBarTitle()),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                ),
                actions: _currentIndex == 1
                    ? [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {},
                        ),
                      ]
                    : null,
              ),
        body: Stack(children: [screens[_currentIndex]]),
        bottomNavigationBar: CustomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
        ),
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton(
                onPressed: () {
                  _showCreateBlogModalDialog();
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    AuthService authService,
    String userName,
    String? userEmail,
    String? profilePhotoUrl,
  ) {
    // Safe handling of empty userName
    final displayChar = userName.isNotEmpty
        ? userName.substring(0, 1).toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () {
        if (_profileOverlayEntry == null) {
          _showProfileDropdown(
            context,
            authService,
            userName,
            userEmail,
            profilePhotoUrl,
          );
        } else {
          _removeProfileDropdown();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: ClipOval(
            child: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                ? Image.network(
                    profilePhotoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.blue[100],
                        child: Center(
                          child: Text(
                            displayChar,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                        displayChar,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showProfileDropdown(
    BuildContext context,
    AuthService authService,
    String userName,
    String? userEmail,
    String? profilePhotoUrl,
  ) {
    if (_profileOverlayEntry != null) {
      return;
    }

    final isLoggedIn = authService.isAuthenticated;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _profileOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: kToolbarHeight + 8,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _removeProfileDropdown,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: MouseRegion(
                      onEnter: (_) {},
                      onExit: (_) {},
                      child: ProfileMenuDropdown(
                        userName: userName,
                        userEmail: userEmail,
                        profilePhotoUrl: profilePhotoUrl,
                        onProfileTap: () {
                          _removeProfileDropdown();
                          setState(() {
                            _currentIndex = 3;
                          });
                        },
                        onSettingsTap: () {
                          _removeProfileDropdown();
                          // Open app settings dialog instead of showing coming soon
                          _showAppSettingsDialog(context);
                        },
                        onLogoutTap: () {
                          _removeProfileDropdown();
                          _showLogoutDialog(context, authService);
                        },
                        onSignInTap: () {
                          _removeProfileDropdown();

                          // Use rootNavigator: true to navigate from overlay
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed('/login');
                        },
                        onThemeToggle: () {
                          themeProvider.toggleTheme();
                          _removeProfileDropdown();
                        },
                        isDarkMode: themeProvider.isDarkMode,
                        isLoggedIn: isLoggedIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_profileOverlayEntry!);
  }

  void _removeProfileDropdown() {
    if (_profileOverlayEntry != null) {
      _profileOverlayEntry!.remove();
      _profileOverlayEntry = null;
    }
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'All Articles';
      case 2:
        return 'Home';
      case 3:
        return 'My Profile';
      default:
        return 'AniBlog';
    }
  }
}

// Notification dropdown content widget
class _NotificationDropdownContent extends StatefulWidget {
  final NotificationService notificationService;

  const _NotificationDropdownContent({required this.notificationService});

  @override
  State<_NotificationDropdownContent> createState() =>
      _NotificationDropdownContentState();
}

class _NotificationDropdownContentState
    extends State<_NotificationDropdownContent> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await widget.notificationService
          .getNotificationsForDropdown();
      final unreadCount = await widget.notificationService.getUnreadCount();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await widget.notificationService.markAsRead(notificationId);

    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
    });
  }

  Future<void> _markAllAsRead() async {
    await widget.notificationService.markAllAsRead();

    setState(() {
      for (var notification in _notifications) {
        notification['is_read'] = true;
      }
      _unreadCount = 0;
    });
  }

  Future<void> _deleteNotification(String notificationId) async {
    await widget.notificationService.deleteNotification(notificationId);

    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final notificationId = notification['id'] as String;
    final type = notification['type'] as String?;
    final referenceId = notification['reference_id'] as String?;

    // Mark as read
    _markAsRead(notificationId);

    // Handle navigation based on type
    if (type == 'reaction' || type == 'comment' || type == 'comment_reaction') {
      if (referenceId != null) {
        // Close dropdown
        Navigator.pop(context);

        // Navigate to the blog post
        _navigateToBlogPost(referenceId);
      }
    }
  }

  Future<void> _navigateToBlogPost(String postId) async {
    try {
      final blogService = BlogService();
      final blog = await blogService.getBlogPost(postId);

      // Show blog detail modal
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) {
          return BlogDetailModal(
            blog: blog,
            onClose: () => Navigator.pop(context),
          );
        },
      );
    } catch (e) {
      print('Error navigating to blog post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getNotificationIcon(String type) {
    switch (type) {
      case 'reaction':
        return {
          'icon': Icons.thumb_up,
          'color': Theme.of(context).colorScheme.primary,
        };
      case 'comment':
        return {
          'icon': Icons.comment,
          'color': Theme.of(context).colorScheme.secondary,
        };
      case 'comment_reaction':
        return {
          'icon': Icons.thumb_up_alt,
          'color': Theme.of(context).colorScheme.tertiary ?? Colors.purple,
        };
      case 'follow':
        return {'icon': Icons.person_add, 'color': Colors.orange};
      default:
        return {
          'icon': Icons.notifications,
          'color': Theme.of(context).colorScheme.outline,
        };
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When you get notifications, they\'ll appear here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] as bool? ?? false;
                      final iconInfo = _getNotificationIcon(
                        notification['type'] as String? ?? '',
                      );
                      final createdAt = notification['created_at'] as String;

                      return _NotificationPopupItem(
                        notification: notification,
                        icon: iconInfo['icon'] as IconData,
                        iconColor: iconInfo['color'] as Color,
                        time: _formatTime(createdAt),
                        isRead: isRead,
                        onTap: () => _handleNotificationTap(notification),
                        onDelete: () =>
                            _deleteNotification(notification['id'] as String),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Notification popup item widget
class _NotificationPopupItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final IconData icon;
  final Color iconColor;
  final String time;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationPopupItem({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.isRead,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRead
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 18)),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] as String? ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification['message'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (notification['sender'] != null)
                          Expanded(
                            child: Text(
                              'From: ${(notification['sender'] as Map<String, dynamic>)['display_name'] ?? 'User'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button (small X)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create Blog Modal Widget
// Create Blog Modal Widget
class CreateBlogModal extends StatefulWidget {
  final VoidCallback? onBlogCreated;
  final VoidCallback? onClose;

  const CreateBlogModal({super.key, this.onBlogCreated, this.onClose});

  @override
  State<CreateBlogModal> createState() => _CreateBlogModalState();
}

class _CreateBlogModalState extends State<CreateBlogModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _storageService = StorageService();
  bool _isSubmitting = false;
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface, // ← ADD THIS
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.onSurface, // ← FIX
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, // ← FIX
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onSurface, // ← FIX
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, // ← FIX
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error showing image picker: $e');
      final image = await _storageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    }
  }

  Future<void> _uploadImages() async {
    _uploadedImageUrls.clear();

    for (final image in _selectedImages) {
      try {
        final imageUrl = await _storageService.uploadImage(
          bucket: 'blog-images',
          imageFile: image,
        );
        _uploadedImageUrls.add(imageUrl);
      } catch (e) {
        print('Error uploading image: $e');
        rethrow;
      }
    }
  }

  Future<void> _submitBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_selectedImages.isNotEmpty) {
        await _uploadImages();
      }

      final blogService = BlogService();
      await blogService.createBlogPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: _uploadedImageUrls,
      );

      if (widget.onBlogCreated != null) {
        widget.onBlogCreated!();
      }

      if (widget.onClose != null) {
        widget.onClose!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Blog published successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary, // ← FIX
        ),
      );
    } catch (e) {
      print('Error creating blog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error, // ← FIX
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }

    _titleController.clear();
    _contentController.clear();
    _selectedImages.clear();
    _uploadedImageUrls.clear();
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create New Blog',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface, // ← FIX
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface, // ← FIX
                ),
                onPressed: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, // ← FIX
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blog Title',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7), // ← FIX
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline, // ← FIX
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline, // ← FIX
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, // ← FIX
                      ),
                    ),
                    hintText: 'Enter a title...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5), // ← FIX
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length < 10) {
                      return 'Title should be at least 10 characters';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, // ← FIX
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blog Content',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7), // ← FIX
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline, // ← FIX
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline, // ← FIX
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, // ← FIX
                      ),
                    ),
                    hintText: 'Write your blog content here...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5), // ← FIX
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter blog content';
                    }
                    if (value.length < 50) {
                      return 'Content should be at least 50 characters';
                    }
                    return null;
                  },
                  maxLines: 6,
                  maxLength: 5000,
                ),

                // Image upload section
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Add Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface, // ← FIX
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: Theme.of(context).colorScheme.primary, // ← FIX
                      ),
                      label: Text(
                        'Add Image',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, // ← FIX
                        ),
                      ),
                    ),
                  ],
                ),

                // Selected images preview
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedImages.length} image(s) selected',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6), // ← FIX
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5), // ← FIX
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline, // ← FIX
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4), // ← FIX
                                      ),
                                      Text(
                                        'Image ${index + 1}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6), // ← FIX
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withOpacity(0.8), // ← FIX
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface, // ← FIX
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBlog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary, // ← FIX
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimary, // ← FIX
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Publish Blog',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface, // ← FIX
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline, // ← FIX
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

// Edit Blog Modal Widget
// Edit Blog Modal Widget
class EditBlogModal extends StatefulWidget {
  final BlogPost blog;
  final VoidCallback onBlogUpdated;
  final VoidCallback onClose;

  const EditBlogModal({
    super.key,
    required this.blog,
    required this.onBlogUpdated,
    required this.onClose,
  });

  @override
  State<EditBlogModal> createState() => _EditBlogModalState();
}

class _EditBlogModalState extends State<EditBlogModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _storageService = StorageService();
  bool _isSubmitting = false;
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    // Initialize with existing blog data
    _titleController.text = widget.blog.title;
    _contentController.text = widget.blog.content;
    _existingImageUrls = widget.blog.imageUrls ?? [];
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface, // ← ADD THIS
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.onSurface, // ← ADD THIS
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface, // ← ADD THIS
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onSurface, // ← ADD THIS
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface, // ← ADD THIS
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error showing image picker: $e');
      final image = await _storageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    }
  }

  Future<void> _uploadImages() async {
    _uploadedImageUrls.clear();

    for (final image in _selectedImages) {
      try {
        final imageUrl = await _storageService.uploadImage(
          bucket: 'blog-images',
          imageFile: image,
        );
        _uploadedImageUrls.add(imageUrl);
      } catch (e) {
        print('Error uploading image: $e');
        rethrow;
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload new images first
      if (_selectedImages.isNotEmpty) {
        await _uploadImages();
      }

      // Combine existing and new image URLs
      final allImageUrls = [..._existingImageUrls, ..._uploadedImageUrls];

      final blogService = BlogService();
      await blogService.updateBlogPost(
        id: widget.blog.id,
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: allImageUrls,
      );

      // Success
      widget.onBlogUpdated();

      // Close modal
      widget.onClose();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blog updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating blog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Blog Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary, // ← FIX
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimary, // ← FIX
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, // ← FIX
                    ),
                    decoration: InputDecoration(
                      labelText: 'Blog Title',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7), // ← FIX
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Enter a title...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5), // ← FIX
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface, // ← FIX
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.length < 10) {
                        return 'Title should be at least 10 characters';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, // ← FIX
                    ),
                    decoration: InputDecoration(
                      labelText: 'Blog Content',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7), // ← FIX
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Write your blog content here...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5), // ← FIX
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface, // ← FIX
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter blog content';
                      }
                      if (value.length < 50) {
                        return 'Content should be at least 50 characters';
                      }
                      return null;
                    },
                    maxLines: 6,
                    maxLength: 5000,
                  ),

                  // Existing images
                  if (_existingImageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Existing Images:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface, // ← FIX
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _existingImageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline, // ← FIX
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        _existingImageUrls[index],
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeExistingImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withOpacity(0.8), // ← FIX
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface, // ← FIX
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Image upload section
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Add New Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface, // ← FIX
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          Icons.add_photo_alternate,
                          color: Theme.of(context).colorScheme.primary, // ← FIX
                        ),
                        label: Text(
                          'Add Image',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary, // ← FIX
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Selected new images preview
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedImages.length} new image(s) selected',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6), // ← FIX
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface, // ← FIX
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline, // ← FIX
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.4), // ← FIX
                                        ),
                                        Text(
                                          'New ${index + 1}',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6), // ← FIX
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeNewImage(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(0.8), // ← FIX
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface, // ← FIX
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary, // ← FIX
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary, // ← FIX
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Blog',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline, // ← FIX
                        ),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface, // ← FIX
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

// Edit Comment Modal Widget
class EditCommentModal extends StatefulWidget {
  final Comment comment;
  final VoidCallback onCommentUpdated;
  final VoidCallback onClose;

  const EditCommentModal({
    super.key,
    required this.comment,
    required this.onCommentUpdated,
    required this.onClose,
  });

  @override
  State<EditCommentModal> createState() => _EditCommentModalState();
}

class _EditCommentModalState extends State<EditCommentModal> {
  final _commentController = TextEditingController();
  final _storageService = StorageService();
  final _blogService = BlogService();
  bool _isSubmitting = false;
  XFile? _newCommentImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    // Initialize with existing comment data
    _commentController.text = widget.comment.content ?? '';
    _existingImageUrl = widget.comment.imageUrl;
  }

  Future<void> _pickCommentImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromGallery();
                if (image != null) {
                  setState(() {
                    _newCommentImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromCamera();
                if (image != null) {
                  setState(() {
                    _newCommentImage = image;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeExistingImage() {
    setState(() {
      _existingImageUrl = null;
    });
  }

  void _removeNewImage() {
    setState(() {
      _newCommentImage = null;
    });
  }

  Future<void> _submitUpdate() async {
    // Check if there's either text or image
    if (_commentController.text.trim().isEmpty &&
        _existingImageUrl == null &&
        _newCommentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or an image to comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl = _existingImageUrl;

      // Upload new comment image if exists
      if (_newCommentImage != null) {
        imageUrl = await _storageService.uploadImage(
          bucket: 'comment-images',
          imageFile: _newCommentImage!,
        );
      }

      // Update comment - content can be null if only image
      final content = _commentController.text.trim();
      await _blogService.updateComment(
        id: widget.comment.id,
        content: content.isNotEmpty ? content : null,
        imageUrl: imageUrl,
      );

      // Success
      widget.onCommentUpdated();

      // Close modal
      widget.onClose();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Comment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            children: [
              // Comment text input
              // In EditCommentModal build method
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant, // ← CHANGE
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3), // ← CHANGE
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Edit your comment...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                          .withOpacity(0.6), // ← CHANGE
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant, // ← CHANGE
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(height: 16),

              // Existing image
              if (_existingImageUrl != null &&
                  _existingImageUrl!.isNotEmpty) ...[
                const Text(
                  'Existing Image:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_existingImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _removeExistingImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Add new image button
              Row(
                children: [
                  const Text(
                    'Change Image:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickCommentImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add/Change Image'),
                  ),
                ],
              ),

              // New image preview
              if (_newCommentImage != null) ...[
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            Text(
                              'New Image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _removeNewImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update Comment',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Blog Detail Modal with comments
class BlogDetailModal extends StatefulWidget {
  final BlogPost blog;
  final VoidCallback onClose;

  const BlogDetailModal({super.key, required this.blog, required this.onClose});

  @override
  State<BlogDetailModal> createState() => _BlogDetailModalState();
}

class _BlogDetailModalState extends State<BlogDetailModal> {
  final _commentController = TextEditingController();
  final _storageService = StorageService();
  final _blogService = BlogService();
  bool _isSubmitting = false;
  XFile? _commentImage;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _blogService.getComments(widget.blog.id);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _pickCommentImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromGallery();
                if (image != null) {
                  setState(() {
                    _commentImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromCamera();
                if (image != null) {
                  setState(() {
                    _commentImage = image;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeCommentImage() {
    setState(() {
      _commentImage = null;
    });
  }

  Future<void> _submitComment() async {
    // Check if there's either text or image
    if (_commentController.text.trim().isEmpty && _commentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or an image to comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;

      // Upload comment image if exists
      if (_commentImage != null) {
        imageUrl = await _storageService.uploadImage(
          bucket: 'comment-images',
          imageFile: _commentImage!,
        );
      }

      // Create comment - content can be null if only image
      final content = _commentController.text.trim();
      await _blogService.createComment(
        postId: widget.blog.id,
        content: content.isNotEmpty ? content : null,
        imageUrl: imageUrl,
      );

      // Refresh comments
      await _loadComments();

      // Clear form
      _commentController.clear();
      setState(() {
        _commentImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      // First, get the comment to check if it has an image
      final comment = _comments.firstWhere((c) => c.id == commentId);

      // Delete the comment
      await _blogService.deleteComment(commentId);

      // If comment has an image, try to delete it from storage
      if (comment.imageUrl != null && comment.imageUrl!.isNotEmpty) {
        try {
          await _storageService.deleteCommentImage(comment.imageUrl!);
        } catch (e) {
          print('Error deleting comment image: $e');
          // Don't fail the whole operation if image deletion fails
        }
      }

      // Refresh comments
      await _loadComments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment deleted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditBlogModal(BlogPost blog) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Theme(
          data: Theme.of(context), // ← ADD THIS
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.background, // ← ADD THIS
            elevation: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: EditBlogModal(
                blog: blog,
                onBlogUpdated: () {
                  // Refresh the blog details and comments
                  _loadComments();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blog updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onClose: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditCommentModal(Comment comment) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: EditCommentModal(
              comment: comment,
              onCommentUpdated: () {
                // Refresh comments
                _loadComments();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comment updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onClose: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Blog Post',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      // Show edit button only for blog author
                      Consumer<AuthService>(
                        builder: (context, authService, child) {
                          final isAuthor =
                              authService.currentUser?.id == widget.blog.userId;
                          if (isAuthor) {
                            return IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context); // Close current modal
                                _showEditBlogModal(widget.blog);
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Blog content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blog title
                    Text(
                      widget.blog.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Author info - FIXED: Safe substring
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue[100],
                          child:
                              widget.blog.authorPhoto != null &&
                                  widget.blog.authorPhoto!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    widget.blog.authorPhoto!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        widget.blog.authorName.isNotEmpty
                                            ? widget.blog.authorName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  widget.blog.authorName.isNotEmpty
                                      ? widget.blog.authorName
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.blog.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat(
                            'MMM d, yyyy',
                          ).format(widget.blog.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Blog content
                    Text(
                      widget.blog.content,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // Blog images - SINGLE IMAGE CENTERED, MULTIPLE IN GRID
                    if (widget.blog.imageUrls.isNotEmpty) ...[
                      const Text(
                        'Images:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // If only one image, center it
                      if (widget.blog.imageUrls.length == 1) ...[
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 400,
                              maxHeight: 300,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.blog.imageUrls[0],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 300,
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 300,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Multiple images in grid
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemCount: widget.blog.imageUrls.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.blog.imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // Comments section
                    // Find this section in BlogDetailModal (around line 2450-2500)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comment input
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant, // ← CHANGE THIS
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3),
                            ), // ← CHANGE
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment...',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.6), // ← CHANGE
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant, // ← CHANGE
                                  ),
                                  maxLines: 3,
                                  minLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.image,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary, // ← CHANGE
                                ),
                                onPressed: _pickCommentImage,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Comment image preview
                        if (_commentImage != null) ...[
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant, // ← CHANGE
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline
                                    .withOpacity(0.3), // ← CHANGE
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.4), // ← CHANGE
                                      ),
                                      Text(
                                        'Selected',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.6), // ← CHANGE
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: _removeCommentImage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .errorContainer, // ← CHANGE
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer, // ← CHANGE
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary, // ← CHANGE
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary, // ← CHANGE
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Post Comment'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Comments list
                    if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Consumer<AuthService>(
                            builder: (context, authService, child) {
                              final isCommentAuthor =
                                  authService.currentUser?.id == comment.userId;
                              return CommentCard(
                                comment: comment,
                                onDelete: isCommentAuthor
                                    ? () => _deleteComment(comment.id)
                                    : null,
                                onEdit: isCommentAuthor
                                    ? () => _showEditCommentModal(comment)
                                    : null,
                                showActions: isCommentAuthor,
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class _TopNavButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TopNavButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class BlogSearchDelegate extends SearchDelegate<String> {
  final SearchService _searchService = SearchService();
  List<BlogPost> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  BlogSearchDelegate()
    : super(
        searchFieldLabel: 'Search blog posts...',
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
      );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _searchResults.clear();
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    print('📊 buildResults called with query: "$query"');
    return _buildSearchContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    print('💡 buildSuggestions called with query: "$query"');

    if (query.isEmpty) {
      return _buildEmptySuggestions(context);
    }

    // Debounce search
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      print('⏰ Debounce timer fired for query: "$query"');
      if (query.isNotEmpty) {
        _performSearch(context);
      }
    });

    return _buildSearchContent(context);
  }

  Widget _buildEmptySuggestions(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _searchService.getTrendingSearches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trendingSearches = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Trending Searches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (trendingSearches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No trending searches',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: trendingSearches
                    .map(
                      (search) => ListTile(
                        leading: const Icon(Icons.trending_up, size: 20),
                        title: Text(search),
                        onTap: () {
                          query = search;
                          showResults(context);
                          _performSearch(context);
                        },
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 24),

            // Search tips section
            const Text(
              'Search Tips',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildSearchTips(),
          ],
        );
      },
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    print('🎨 _buildSearchContent called');
    print('   Query: "$query"');
    print('   Is loading: $_isLoading');
    print('   Results count: ${_searchResults.length}');

    if (_isLoading) {
      print('   Showing loading state');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching for "$query"...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (query.isEmpty) {
      print('   Query empty, showing suggestions');
      return _buildEmptySuggestions(context);
    }

    if (_searchResults.isEmpty) {
      print('   No results to show');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    print('   ✅ Showing ${_searchResults.length} results');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final blog = _searchResults[index];
        print('   Rendering blog #$index: ${blog.title}');

        return BlogCard(
          blog: blog,
          onTap: () {
            // Close search first
            close(context, '');
            // Then show blog detail modal
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (context) {
                  return BlogDetailModal(
                    blog: blog,
                    onClose: () {
                      Navigator.pop(context);
                    },
                  );
                },
              );
            });
          },
        );
      },
    );
  }

  Widget _buildSearchTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Search effectively:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTipItem('Use specific keywords'),
          _buildTipItem('Try different word combinations'),
          _buildTipItem('Check spelling if no results'),
          _buildTipItem('Use quotes for exact phrases'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _performSearch(BuildContext context) async {
    print('🚀 _performSearch started for: "$query"');

    if (query.isEmpty) {
      print('   Query is empty, returning');
      return;
    }

    // Set loading state
    _isLoading = true;
    print('   Set isLoading = true');

    // Update the UI immediately to show loading
    // We need to trigger a rebuild
    if (context.mounted) {
      print('   Triggering UI rebuild for loading state');
      // Force the search delegate to rebuild
      showResults(context);
    }

    try {
      print('   Calling searchService.searchBlogs...');
      final results = await _searchService.searchBlogs(query);
      print('   Search returned ${results.length} results');

      // Update state
      _searchResults = results;
      _isLoading = false;
      print('   Set isLoading = false, results = ${results.length}');

      // Force UI to rebuild with new results
      if (context.mounted) {
        print('   Triggering UI rebuild with results');
        showResults(context);
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in _performSearch: $e');
      print('Stack trace: $stackTrace');

      _isLoading = false;
      _searchResults = [];
      print('   Set isLoading = false, cleared results due to error');

      // Force UI to rebuild with error state
      if (context.mounted) {
        showResults(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
