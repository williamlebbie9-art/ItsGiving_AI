import 'dart:convert';

class UserAccount {
  const UserAccount({
    this.id = '',
    this.name = '',
    this.email = '',
    this.photoUrl = '',
    this.provider = '',
  });

  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String provider;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
    );
  }

  String toCacheKey() => jsonEncode(toJson());
}
