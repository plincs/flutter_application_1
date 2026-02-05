class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? profilePhotoUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? notificationsEnabled;
  final bool? emailNotifications;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.profilePhotoUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.notificationsEnabled,
    this.emailNotifications,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'profile_photo_url': profilePhotoUrl,
      'bio': bio,
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
