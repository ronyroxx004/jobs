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

  factory DeletedUserModel.fromRaw(dynamic raw, String key) {
    if (raw is Map) {
      return DeletedUserModel.fromMap(Map<String, dynamic>.from(raw), key);
    }
    final rawStr = raw?.toString().trim() ?? '';
    final isEmail = rawStr.contains('@');
    return DeletedUserModel(
      id: key,
      name: isEmail
          ? rawStr.split('@')[0]
          : (rawStr.isNotEmpty && rawStr != 'true' && rawStr != '1'
              ? rawStr
              : 'User ${key.length > 6 ? key.substring(0, 6) : key}'),
      email: isEmail ? rawStr : '',
      role: 'candidate',
      deletedAt: DateTime.now(),
      deletedBy: '',
    );
  }

  factory DeletedUserModel.fromMap(Map<String, dynamic> map, String key) {
    final rawId = map['uid']?.toString() ??
        map['id']?.toString() ??
        map['userId']?.toString() ??
        '';
    final id = rawId.trim().isNotEmpty ? rawId.trim() : key;
    final name = map['name']?.toString() ??
        map['displayName']?.toString() ??
        '';
    final email = map['email']?.toString() ?? '';
    final role = map['role']?.toString() ?? 'candidate';
    final deletedAt = DateTime.tryParse(map['deletedAt']?.toString() ?? '') ??
        DateTime.now();
    final deletedBy = map['deletedBy']?.toString() ?? '';

    return DeletedUserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
    );
  }
}