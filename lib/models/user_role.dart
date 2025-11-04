enum UserRole {
  admin,
  cco, // Chief Commercial Officer
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String displayName;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
  });

  // Role-based permissions
  bool get canDeleteInvoices => role == UserRole.admin;
  bool get canDeleteParties => role == UserRole.admin;
  bool get canDeleteItems => role == UserRole.admin;
  bool get canManageUsers => role == UserRole.admin;
  bool get canViewReports => true; // Both roles can view reports
  bool get canCreateInvoices => true; // Both roles can create invoices
  bool get canEditPrices => role == UserRole.admin;
  
  String get roleLabel => role == UserRole.admin ? 'Admin' : 'CCO';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'displayName': displayName,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.cco,
      displayName: map['displayName'] ?? '',
    );
  }
}

// Predefined user credentials
class UserCredentials {
  static const String adminEmail = 'zamnaniakash@gmail.com';
  static const String ccoEmail = 'cco@saitronics.com';
  
  static const String adminPassword = 'Sam@0512'; // Change this in production
  static const String ccoPassword = 'cco@123'; // Change this in production
  
  static String getEmailForRole(UserRole role) {
    return role == UserRole.admin ? adminEmail : ccoEmail;
  }
  
  static String getPasswordForRole(UserRole role) {
    return role == UserRole.admin ? adminPassword : ccoPassword;
  }
}