class UserProfile {
  final String uid;
  final String email;
  final String role; // 'student' | 'homeowner' | 'admin'
  final String name;
  final String lastname;
  final String homeAddress;
  final String uniAddress;
  final String photos;
  final bool isAdmin; // New field for admin access

  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.name = '',
    this.lastname = '',
    this.homeAddress = '',
    this.uniAddress = '',
    this.photos = '',
    this.isAdmin = false, // Default to false
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) => UserProfile(
    uid: uid,
    email: (m['email'] ?? '') as String,
    role: (m['role'] ?? 'student') as String,
    name: (m['name'] ?? '') as String,
    lastname: (m['lastname'] ?? '') as String,
    homeAddress: (m['homeAddress'] ?? '') as String,
    uniAddress: (m['uniAddress'] ?? '') as String,
    photos: (m['photos'] ?? '') as String,
    isAdmin: (m['isAdmin'] ?? false) as bool, // Parse admin status
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
    'name': name,
    'lastname': lastname,
    'homeAddress': homeAddress,
    'uniAddress': uniAddress,
    'photos': photos,
    'isAdmin': isAdmin,
  };

  // Helper method to get display name
  String get displayName {
    if (name.isNotEmpty && lastname.isNotEmpty) {
      return '$name $lastname';
    } else if (name.isNotEmpty) {
      return name;
    }
    return email;
  }
}