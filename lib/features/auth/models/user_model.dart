class UserModel {
  final String id;
  final String username;
  final String role; // 'admin' | 'client'
  final String? clientsFkId; // Relevante solo si role == 'client'

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.clientsFkId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'client',
      clientsFkId: json['clients_fk_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
    'clients_fk_id': clientsFkId,
  };
}
