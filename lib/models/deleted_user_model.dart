/// Record left behind when an admin removes a user, so the account can be
/// restored later. Stored at `deleted_users/{uid}` in Realtime Database.
class DeletedUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime deletedAt;
  final String deletedBy;

  const DeletedUserModel({
    required this.id,
    this.name = '',
    this.email = '',
    this.role = 'candidate',
    required this.deletedAt,
    this.deletedBy = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'role': role,
      'deletedAt': deletedAt.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  factory DeletedUserModel.fromMap(Map<String, dynamic> map, String key) {
    return DeletedUserModel(
      id: (map['uid']?.toString() ?? map['id']?.toString() ?? key),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'candidate',
      deletedAt: DateTime.tryParse(map['deletedAt']?.toString() ?? '') ??
          DateTime.now(),
      deletedBy: map['deletedBy']?.toString() ?? '',
    );
  }
}