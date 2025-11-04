import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

/// Widget that shows/hides content based on user role
class RoleBasedWidget extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    required this.requiredRole,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService.getCurrentAppUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data;
        if (user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        // Check if user has required role
        if (user.role == requiredRole || user.role == UserRole.admin) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that shows content only to admins
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      requiredRole: UserRole.admin,
      fallback: fallback,
      child: child,
    );
  }
}

/// Checks if action is allowed for current user
Future<bool> isActionAllowed(Function(AppUser) permissionCheck) async {
  final user = await AuthService.getCurrentAppUser();
  if (user == null) return false;
  return permissionCheck(user);
}

/// Shows dialog if action is not allowed
Future<bool> checkPermissionWithDialog(
  BuildContext context,
  Function(AppUser) permissionCheck,
  String actionName,
) async {
  final allowed = await isActionAllowed(permissionCheck);
  
  if (!allowed && context.mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(
          'You do not have permission to $actionName.\n\nThis action requires Admin privileges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  return allowed;
}