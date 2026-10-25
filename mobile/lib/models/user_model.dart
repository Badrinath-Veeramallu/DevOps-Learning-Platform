/// User data model representing the authenticated profile from the backend.
///
/// Handles contract nuances between endpoints:
/// - In `POST /api/auth/login` and `POST /api/auth/verify-email`, the backend returns `{ id: "..." }`.
/// - In `GET /api/auth/me`, Mongoose serializes the document with `{ _id: "..." }`.
/// This model safely checks `json['id'] ?? json['_id']`.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final bool isEmailVerified;
  final String authProvider;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.role = 'user',
    this.isEmailVerified = true,
    this.authProvider = 'local',
  });

  /// Factory constructor to deserialize JSON received from Express API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: json['avatar'] as String?,
      role: (json['role'] ?? 'user').toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      authProvider: (json['authProvider'] ?? 'local').toString(),
    );
  }

  /// Serialize to JSON if needed for testing or local caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
    };
  }

  /// Immutability helper to create a modified copy of this user.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    bool? isEmailVerified,
    String? authProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
    );
  }
}
