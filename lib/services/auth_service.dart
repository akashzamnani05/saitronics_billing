import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Get current app user with role
  static Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  // Login with role
  static Future<AppUser?> loginWithRole(UserRole role, String password) async {
    try {
      final email = UserCredentials.getEmailForRole(role);
      
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Login failed');
      }
      
      // Get or create user document
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      AppUser appUser;
      
      if (!userDoc.exists) {
        // Create new user document
        appUser = AppUser(
          id: userCredential.user!.uid,
          email: email,
          role: role,
          displayName: role == UserRole.admin ? 'Administrator' : 'CCO',
        );
        
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(appUser.toMap());
      } else {
        appUser = AppUser.fromMap(userDoc.data()!);
      }
      
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      
      // Handle specific error codes
      if (e.code == 'user-not-found') {
        // Try to create the user
        return await _createUserAccount(role, password);
      } else if (e.code == 'wrong-password') {
        throw Exception('Invalid password');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }
  
  // Create user account (called automatically if user doesn't exist)
  static Future<AppUser?> _createUserAccount(UserRole role, String password) async {
    try {
      final email = UserCredentials.getEmailForRole(role);
      
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }
      
      // Create user document
      final appUser = AppUser(
        id: userCredential.user!.uid,
        email: email,
        role: role,
        displayName: role == UserRole.admin ? 'Administrator' : 'CCO',
      );
      
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(appUser.toMap());
      
      return appUser;
    } catch (e) {
      print('Error creating user account: $e');
      throw Exception('Failed to create user account: $e');
    }
  }
  
  // Logout
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed');
    }
  }
  
  // Check if user has specific role
  static Future<bool> hasRole(UserRole role) async {
    final appUser = await getCurrentAppUser();
    return appUser?.role == role;
  }
  
  // Check if user is admin
  static Future<bool> isAdmin() async {
    return await hasRole(UserRole.admin);
  }
  
  // Check if user is CCO
  static Future<bool> isCCO() async {
    return await hasRole(UserRole.cco);
  }
  
  // Verify password for re-authentication
  static Future<bool> verifyPassword(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return false;
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Password verification error: $e');
      return false;
    }
  }
}