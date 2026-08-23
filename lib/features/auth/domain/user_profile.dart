/// Perfil do usuário (tabela `users` do Supabase).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.plan = 'free',
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String plan; // 'free' | 'premium'
  final DateTime? createdAt;

  bool get isPremium => plan == 'premium';

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    plan: (json['plan'] as String?) ?? 'free',
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'plan': plan,
  };

  UserProfile copyWith({String? name, String? plan}) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    plan: plan ?? this.plan,
    createdAt: createdAt,
  );
}
