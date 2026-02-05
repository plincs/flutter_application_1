import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.add_circle,
            label: 'Create',
            isActive: currentIndex == 2,
            isCenter: true,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.article,
            label: 'Blogs',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final outlineColor = Theme.of(context).colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: isCenter
            ? BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isCenter
                  ? onPrimaryColor
                  : isActive
                  ? primaryColor
                  : outlineColor,
              size: isCenter ? 28 : 24,
            ),
            if (!isCenter) const SizedBox(height: 4),
            if (!isCenter)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? primaryColor : outlineColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
