class UserProfile {
  final String uid;
  final String email;
  final String role; // 'student' | 'homeowner' | 'admin'
  final String name;
  final String lastname;
  final String homeAddress;
  final String uniAddress;
  final String photoUrl;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.name = '',
    this.lastname = '',
    this.homeAddress = '',
    this.uniAddress = '',
    this.photoUrl = '',
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) => UserProfile(
    uid: uid,
    email: (m['email'] ?? '') as String,
    role: (m['role'] ?? 'student') as String,
    name: (m['name'] ?? '') as String,
    lastname: (m['lastname'] ?? '') as String,
    homeAddress: (m['homeAddress'] ?? '') as String,
    uniAddress: (m['uniAddress'] ?? '') as String,
    photoUrl: (m['photoUrl'] ?? '') as String,
  );
}
