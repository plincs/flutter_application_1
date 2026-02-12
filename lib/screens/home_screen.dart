import 'dart:async';
import 'dart:typed_data';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<BlogPost> _recentBlogs = [];
  bool _isLoading = true;
  final bool _isDarkMode = false;
  OverlayEntry? _profileOverlayEntry;
  bool _showCreateBlogModal = false;
  final NotificationService _notificationService = NotificationService();
  final BlogService _blogService = BlogService();

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
      final posts = await _blogService.getBlogPosts();

      if (mounted) {
        setState(() {
          _recentBlogs = posts.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.surface,
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
                                ).colorScheme.onPrimaryContainer,
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
                                    .withOpacity(0.8),
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
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Write Your First Blog'),
                            ),
                          ] else ...[
                            Text(
                              'First time in Aniblog?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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
                                    .withOpacity(0.8),
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
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
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
                                    ).colorScheme.primary,
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withOpacity(0.1),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimeSlider(),
          ),

          const SizedBox(height: 20),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).colorScheme.primary,
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
                          final authService = Provider.of<AuthService>(context);
                          final isAuthor =
                              authService.currentUser?.id == blog.userId;

                          return BlogCard(
                            blog: blog,
                            onTap: () => _viewBlogDetail(blog),
                            onEdit: isAuthor ? () => _editBlog(blog) : null,
                            onDelete: isAuthor
                                ? () => _deleteBlog(blog.id)
                                : null,
                            onRefresh: _loadBlogs,
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
          onBlogCreated: _loadBlogs,
        );
      },
    );
  }

  void _editBlog(BlogPost blog) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.id != blog.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own blog posts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showEditBlogModal(blog);
  }

  void _showEditBlogModal(BlogPost blog) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Theme(
          data: Theme.of(context),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: EditBlogModal(
                blog: blog,
                onBlogUpdated: () {
                  _loadBlogs();
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

  void _deleteBlog(String blogId) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    final blog = _recentBlogs.firstWhere((b) => b.id == blogId);

    if (currentUser == null || currentUser.id != blog.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own blog posts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blog'),
        content: const Text('Are you sure you want to delete this blog post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _blogService.deleteBlogPost(blogId);
                await _loadBlogs();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Blog deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting blog: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateBlogModalDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Theme(
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
                color: Theme.of(context).colorScheme.surface,
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
                  Navigator.pop(context);
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

  void _hideCreateBlogModal() {
    if (_showCreateBlogModal) {
      setState(() {
        _showCreateBlogModal = false;
      });
    }
  }

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
          builder: (context, notificationService, child) {
            return StreamBuilder<int>(
              stream: notificationService.unreadCountStream(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 0) {
        _loadBlogs();
      }
    });

    final screens = [
      _buildHomeContent(),
      BlogListScreen(onBlogCreated: _loadBlogs),
      _buildHomeContent(),
      const ProfileScreen(),
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
                          _showAppSettingsDialog(context);
                        },
                        onLogoutTap: () {
                          _removeProfileDropdown();
                          _showLogoutDialog(context, authService);
                        },
                        onSignInTap: () {
                          _removeProfileDropdown();
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

    _markAsRead(notificationId);

    if (type == 'reaction' || type == 'comment' || type == 'comment_reaction') {
      if (referenceId != null) {
        Navigator.pop(context);
      }
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
  final BlogService _blogService = BlogService();
  bool _isSubmitting = false;
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  final Map<int, Uint8List> _imageCache = {};

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                      _preCacheImage(_selectedImages.length - 1, image);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                      _preCacheImage(_selectedImages.length - 1, image);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      final image = await _storageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
          _preCacheImage(_selectedImages.length - 1, image);
        });
      }
    }
  }

  Future<void> _preCacheImage(int index, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _imageCache[index] = bytes;
        });
      }
    } catch (e) {
      // Ignore cache errors
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

      await _blogService.createBlogPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: _uploadedImageUrls,
      );

      if (widget.onBlogCreated != null) {
        widget.onBlogCreated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
    _imageCache.clear();
  }

  void _removeImage(int index) {
    setState(() {
      _imageCache.remove(index);

      final keysToUpdate = _imageCache.keys
          .where((key) => key > index)
          .toList();
      for (final key in keysToUpdate) {
        final bytes = _imageCache[key]!;
        _imageCache.remove(key);
        _imageCache[key - 1] = bytes;
      }

      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImagePreview(int index) {
    if (_imageCache.containsKey(index)) {
      return Image.memory(
        _imageCache[index]!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else {
      return FutureBuilder<Uint8List>(
        future: _selectedImages[index].readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorImage();
          } else if (snapshot.hasData) {
            final bytes = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && index < _selectedImages.length) {
                setState(() {
                  _imageCache[index] = bytes;
                });
              }
            });

            return Image.memory(
              bytes,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            );
          } else {
            return _buildErrorImage();
          }
        },
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blog Title',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    hintText: 'Enter a title...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blog Content',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    hintText: 'Write your blog content here...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
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

                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Add Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Add Image',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedImages.length} image(s) selected',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
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
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImagePreview(index),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
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
    _imageCache.clear();
    super.dispose();
  }
}

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
  final Map<int, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.blog.title;
    _contentController.text = widget.blog.content;
    _existingImageUrls = widget.blog.imageUrls ?? [];
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                      _preCacheImage(_selectedImages.length - 1, image);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                      _preCacheImage(_selectedImages.length - 1, image);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      final image = await _storageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
          _preCacheImage(_selectedImages.length - 1, image);
        });
      }
    }
  }

  Future<void> _preCacheImage(int index, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _imageCache[index] = bytes;
        });
      }
    } catch (e) {}
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
      if (_selectedImages.isNotEmpty) {
        await _uploadImages();
      }

      final allImageUrls = [..._existingImageUrls, ..._uploadedImageUrls];

      final blogService = BlogService();
      await blogService.updateBlogPost(
        id: widget.blog.id,
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: allImageUrls,
      );

      widget.onBlogUpdated();

      widget.onClose();
    } catch (e) {
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
      _imageCache.remove(index);

      final keysToUpdate = _imageCache.keys
          .where((key) => key > index)
          .toList();
      for (final key in keysToUpdate) {
        final bytes = _imageCache[key]!;
        _imageCache.remove(key);
        _imageCache[key - 1] = bytes;
      }

      _selectedImages.removeAt(index);
    });
  }

  Widget _buildNewImagePreview(int index) {
    if (_imageCache.containsKey(index)) {
      return Image.memory(
        _imageCache[index]!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else {
      return FutureBuilder<Uint8List>(
        future: _selectedImages[index].readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorImage();
          } else if (snapshot.hasData) {
            final bytes = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && index < _selectedImages.length) {
                setState(() {
                  _imageCache[index] = bytes;
                });
              }
            });

            return Image.memory(
              bytes,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            );
          } else {
            return _buildErrorImage();
          }
        },
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Blog Title',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Enter a title...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Blog Content',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Write your blog content here...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
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

                  if (_existingImageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Existing Images:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
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
                                      ).colorScheme.outline,
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
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

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Add New Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          Icons.add_photo_alternate,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          'Add Image',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedImages.length} new image(s) selected',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
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
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildNewImagePreview(index),
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
                                              .withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
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
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
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
    _imageCache.clear();
    super.dispose();
  }
}

class BlogDetailModal extends StatefulWidget {
  final BlogPost blog;
  final VoidCallback onClose;
  final VoidCallback? onBlogCreated;

  const BlogDetailModal({
    super.key,
    required this.blog,
    required this.onClose,
    this.onBlogCreated,
  });

  @override
  State<BlogDetailModal> createState() => _BlogDetailModalState();
}

class _BlogDetailModalState extends State<BlogDetailModal> {
  final _commentController = TextEditingController();
  final _storageService = StorageService();
  final BlogService _blogService = BlogService();
  bool _isSubmitting = false;
  final List<XFile> _selectedCommentImages = [];
  List<Comment> _comments = [];
  final Map<int, Uint8List> _commentImageCache = {};

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

  Future<void> _pickCommentImages() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final images = await _storageService
                      .pickMultipleImagesFromGallery();
                  if (images != null && images.isNotEmpty) {
                    setState(() {
                      final startIndex = _selectedCommentImages.length;
                      _selectedCommentImages.addAll(images);
                      for (int i = 0; i < images.length; i++) {
                        _preCacheCommentImage(startIndex + i, images[i]);
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _storageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedCommentImages.add(image);
                      _preCacheCommentImage(
                        _selectedCommentImages.length - 1,
                        image,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error picking images: $e');
      final image = await _storageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedCommentImages.add(image);
          _preCacheCommentImage(_selectedCommentImages.length - 1, image);
        });
      }
    }
  }

  Future<void> _preCacheCommentImage(int index, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _commentImageCache[index] = bytes;
        });
      }
    } catch (e) {
      // Ignore caching errors for comments
    }
  }

  void _removeCommentImage(int index) {
    setState(() {
      _commentImageCache.remove(index);

      final keysToUpdate = _commentImageCache.keys
          .where((key) => key > index)
          .toList();
      for (final key in keysToUpdate) {
        final bytes = _commentImageCache[key]!;
        _commentImageCache.remove(key);
        _commentImageCache[key - 1] = bytes;
      }

      _selectedCommentImages.removeAt(index);
    });
  }

  Widget _buildCommentImagePreview(int index) {
    if (_commentImageCache.containsKey(index)) {
      return Image.memory(
        _commentImageCache[index]!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else {
      return FutureBuilder<Uint8List>(
        future: _selectedCommentImages[index].readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorImage();
          } else if (snapshot.hasData) {
            final bytes = snapshot.data!;
            // FIX: Don't use addPostFrameCallback here - it's causing the issue
            // Instead, cache the image without setState first, then use a microtask
            if (!_commentImageCache.containsKey(index)) {
              // Use scheduleMicrotask instead of addPostFrameCallback
              scheduleMicrotask(() {
                if (mounted && index < _selectedCommentImages.length) {
                  setState(() {
                    _commentImageCache[index] = bytes;
                  });
                }
              });
            }
            return Image.memory(
              bytes,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            );
          } else {
            return _buildErrorImage();
          }
        },
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 20, color: Colors.grey),
      ),
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty &&
        _selectedCommentImages.isEmpty) {
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
      List<String> imageUrls = [];

      if (_selectedCommentImages.isNotEmpty) {
        imageUrls = await _storageService.uploadMultipleImages(
          bucket: 'comment-images',
          imageFiles: _selectedCommentImages,
          customFileNamePrefix: 'comment',
        );
      }

      final content = _commentController.text.trim();
      await _blogService.createComment(
        postId: widget.blog.id,
        content: content.isNotEmpty ? content : null,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      );

      await _loadComments();

      _commentController.clear();
      setState(() {
        _selectedCommentImages.clear();
        _commentImageCache.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _editComment(Comment comment) async {
    final TextEditingController editController = TextEditingController(
      text: comment.content,
    );
    List<String> currentImageUrls = List.from(comment.imageUrls ?? []);
    List<XFile> newSelectedImages = [];
    final Map<int, Uint8List> editImageCache = {};

    final BuildContext dialogContext = context;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Comment',
                          style: TextStyle(
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: editController,
                      decoration: const InputDecoration(
                        hintText: 'Edit your comment...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      minLines: 2,
                    ),
                    const SizedBox(height: 16),

                    if (currentImageUrls.isNotEmpty) ...[
                      const Text(
                        'Current Images:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentImageUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          currentImageUrls[index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        dialogSetState(() {
                                          currentImageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
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

                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              final images = await _storageService
                                  .pickMultipleImagesFromGallery();
                              if (images != null && images.isNotEmpty) {
                                if (context.mounted) {
                                  dialogSetState(() {
                                    newSelectedImages.addAll(images);
                                  });
                                  // Cache images after adding
                                  for (int i = 0; i < images.length; i++) {
                                    try {
                                      final bytes = await images[i]
                                          .readAsBytes();
                                      if (context.mounted) {
                                        dialogSetState(() {
                                          editImageCache[newSelectedImages
                                                      .length -
                                                  images.length +
                                                  i] =
                                              bytes;
                                        });
                                      }
                                    } catch (e) {
                                      // Ignore cache errors
                                    }
                                  }
                                }
                              }
                            } catch (e) {
                              // Handle error silently
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),

                    if (newSelectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'New Images:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: newSelectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: editImageCache.containsKey(index)
                                          ? Image.memory(
                                              editImageCache[index]!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : FutureBuilder<Uint8List>(
                                              future: newSelectedImages[index]
                                                  .readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        ),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                } else if (snapshot.hasData) {
                                                  final bytes = snapshot.data!;
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        if (context.mounted) {
                                                          dialogSetState(() {
                                                            editImageCache[index] =
                                                                bytes;
                                                          });
                                                        }
                                                      });
                                                  return Image.memory(
                                                    bytes,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                  );
                                                } else {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.image,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        dialogSetState(() {
                                          newSelectedImages.removeAt(index);
                                          editImageCache.remove(index);
                                          // Reindex remaining images
                                          final updatedCache =
                                              <int, Uint8List>{};
                                          for (
                                            int i = 0;
                                            i < newSelectedImages.length;
                                            i++
                                          ) {
                                            if (editImageCache.containsKey(
                                              i + 1,
                                            )) {
                                              updatedCache[i] =
                                                  editImageCache[i + 1]!;
                                            }
                                          }
                                          editImageCache.clear();
                                          editImageCache.addAll(updatedCache);
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
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
                    ],

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // Close dialog first
                            Navigator.pop(context);

                            // Use a mounted check before any state operations
                            if (!mounted) return;

                            setState(() {
                              _isSubmitting = true;
                            });

                            try {
                              List<String> uploadedImageUrls = [];

                              if (newSelectedImages.isNotEmpty) {
                                uploadedImageUrls = await _storageService
                                    .uploadMultipleImages(
                                      bucket: 'comment-images',
                                      imageFiles: newSelectedImages,
                                      customFileNamePrefix: 'comment',
                                    );
                              }

                              final allImageUrls = [
                                ...currentImageUrls,
                                ...uploadedImageUrls,
                              ];

                              final content = editController.text.trim();

                              await _blogService.editComment(
                                commentId: comment.id,
                                content: content.isNotEmpty ? content : null,
                                imageUrls: allImageUrls.isNotEmpty
                                    ? allImageUrls
                                    : null,
                              );

                              await _loadComments();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Comment updated successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Error updating comment: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error updating comment: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Dispose controller after dialog is closed
    editController.dispose();
  }

  void _preCacheEditImageForDialog(
    Map<int, Uint8List> cache,
    int index,
    XFile image,
    void Function(void Function()) dialogSetState,
  ) async {
    try {
      final bytes = await image.readAsBytes();
      try {
        dialogSetState(() {
          cache[index] = bytes;
        });
      } catch (e) {
        // Dialog might be closed, ignore
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  Widget _buildEditImagePreviewForDialog(
    Map<int, Uint8List> cache,
    List<XFile> images,
    int index,
    void Function(void Function()) dialogSetState,
  ) {
    if (cache.containsKey(index)) {
      return Image.memory(
        cache[index]!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return FutureBuilder<Uint8List>(
        future: images[index].readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (snapshot.hasError) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          } else if (snapshot.hasData) {
            final bytes = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              dialogSetState(() {
                cache[index] = bytes;
              });
            });
            return Image.memory(
              bytes,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey),
            );
          }
        },
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _blogService.deleteComment(commentId);

      if (mounted) {
        setState(() {
          _comments.removeWhere((comment) => comment.id == commentId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
                      Consumer<AuthService>(
                        builder: (context, authService, child) {
                          final isAuthor =
                              authService.currentUser?.id == widget.blog.userId;
                          if (isAuthor) {
                            return IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.blog.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    Text(
                      widget.blog.content,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    if (widget.blog.imageUrls.isNotEmpty) ...[
                      const Text(
                        'Images:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3),
                            ),
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
                                          .withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 3,
                                  minLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.image,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                onPressed: _pickCommentImages,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_selectedCommentImages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedCommentImages.length} image(s) selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedCommentImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: _buildCommentImagePreview(
                                            index,
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _removeCommentImage(index),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCommentImages.clear();
                                  _commentImageCache.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 24),
                              ),
                              child: Text(
                                'Remove All',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
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
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Post Comment'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                                showActions: isCommentAuthor,
                                onDelete: isCommentAuthor
                                    ? () => _showDeleteCommentDialog(comment.id)
                                    : null,
                                onEdit: isCommentAuthor
                                    ? () => _editComment(comment)
                                    : null,
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

  void _showEditBlogModal(BlogPost blog) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Theme(
          data: Theme.of(context),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: EditBlogModal(
                blog: blog,
                onBlogUpdated: () {
                  _loadComments();
                  if (widget.onBlogCreated != null) {
                    widget.onBlogCreated!();
                  }
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

  @override
  void dispose() {
    _commentController.dispose();
    _selectedCommentImages.clear();
    _commentImageCache.clear();
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
    return _buildSearchContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptySuggestions(context);
    }

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
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
    if (_isLoading) {
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
      return _buildEmptySuggestions(context);
    }

    if (_searchResults.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final blog = _searchResults[index];

        return BlogCard(
          blog: blog,
          onTap: () {
            close(context, '');
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
    if (query.isEmpty) {
      return;
    }

    _isLoading = true;

    if (context.mounted) {
      showResults(context);
    }

    try {
      final results = await _searchService.searchBlogs(query);

      _searchResults = results;
      _isLoading = false;

      if (context.mounted) {
        showResults(context);
      }
    } catch (e, stackTrace) {
      _isLoading = false;
      _searchResults = [];

      if (context.mounted) {
        showResults(context);

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
