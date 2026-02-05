// widgets/profile_menu_dropdown.dart
import 'package:flutter/material.dart';

class ProfileMenuDropdown extends StatelessWidget {
  final String userName;
  final String? userEmail;
  final String? profilePhotoUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onSignInTap;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final bool isLoggedIn;

  const ProfileMenuDropdown({
    super.key,
    required this.userName,
    this.userEmail,
    this.profilePhotoUrl,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
    required this.onSignInTap,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    // Safely get the first character of user name
    final userInitial = userName.isNotEmpty
        ? userName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            profilePhotoUrl != null &&
                                profilePhotoUrl!.isNotEmpty
                            ? Image.network(
                                profilePhotoUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildProfileFallback(
                                    userInitial,
                                    context,
                                  );
                                },
                              )
                            : _buildProfileFallback(userInitial, context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? userName : 'Guest',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userEmail != null &&
                              userEmail!.isNotEmpty &&
                              isLoggedIn) ...[
                            const SizedBox(height: 2),
                            Text(
                              userEmail!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onProfileTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Menu items
          ..._buildMenuItems(context),
        ],
      ),
    );
  }

  // FIXED: Added context parameter
  Widget _buildProfileFallback(String initial, BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    if (!isLoggedIn) {
      // Show only Sign In button for logged-out users
      return [
        Divider(height: 1, color: Theme.of(context).dividerColor),
        _MenuItem(
          icon: Icons.login_rounded,
          label: 'Sign In',
          color: Theme.of(context).colorScheme.primary,
          onTap: onSignInTap,
        ),
      ];
    }

    // Show simplified menu for logged-in users
    return [
      Divider(height: 1, color: Theme.of(context).dividerColor),
      _MenuItem(
        icon: Icons.person_rounded,
        label: 'My Profile',
        onTap: onProfileTap,
      ),
      _MenuItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        onTap: onSettingsTap,
      ),
      _MenuItem(
        icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        label: isDarkMode ? 'Light Mode' : 'Dark Mode',
        trailing: Switch(
          value: isDarkMode,
          onChanged: (value) => onThemeToggle(),
          activeColor: Theme.of(context).colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onTap: () {},
      ),
      Divider(height: 1, color: Theme.of(context).dividerColor),
      _MenuItem(
        icon: Icons.logout_rounded,
        label: 'Logout',
        color: Colors.red,
        onTap: onLogoutTap,
      ),
    ];
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface;
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
