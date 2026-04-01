class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String role;

  Profile({required this.id, this.fullName, this.phone, this.email, required this.role});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String,
    );
  }
}
