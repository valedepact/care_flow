import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:care_flow/screens/patient_dashboard_page.dart';
import 'package:care_flow/screens/nurse_dashboard_board.dart'; // IMPORTANT: Ensure this path and filename are correct
import 'package:care_flow/screens/dashboard_page.dart'; // The initial landing page

// Define role constants for better maintainability and to avoid typos.
class AppRoles {
  static const String patient = 'Patient';
  static const String nurse = 'Nurse';
}

class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('RoleRouter: No user logged in. Navigating to DashboardPage.');
      _navigateToPage(const DashboardPage());
      return;
    }

    debugPrint('RoleRouter: User logged in: ${user.uid}. Checking Firestore role...');
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!mounted) {
        debugPrint('RoleRouter: Widget unmounted after Firestore fetch.');
        return; // Check mounted after await
      }

      if (userDoc.exists) {
        String? role = userDoc.get('role');
        debugPrint('RoleRouter: User document exists. Role found: $role');

        if (role == AppRoles.patient) {
          debugPrint('RoleRouter: Navigating to PatientDashboardPage.');
          _navigateToPage(const PatientDashboardPage());
        } else if (role == AppRoles.nurse) {
          debugPrint('RoleRouter: Navigating to CaregiverDashboard.');
          _navigateToPage(const CaregiverDashboard()); // IMPORTANT: This must match the class name in caregiver_dashboard.dart
        } else {
          debugPrint('RoleRouter: Unknown role ($role) or incomplete profile for UID: ${user.uid}. Signing out.');
          _showSnackBarAndSignOut('Unknown role or incomplete profile. Please log in again.');
        }
      } else {
        // User document does not exist, meaning user is authenticated but profile is not set up
        debugPrint('RoleRouter: User profile not found for UID: ${user.uid}. Signing out.');
        _showSnackBarAndSignOut('User profile not found. Please complete registration or log in.');
      }
    } catch (e) {
      debugPrint("RoleRouter: Error checking user role: $e. Navigating to DashboardPage.");
      _showSnackBarAndSignOut('Error checking user role: $e');
    }
  }

  // Helper method to navigate and ensure mounted state
  void _navigateToPage(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
    });
  }

  // Helper method to show snack-bar, sign out, and navigate to DashboardPage
  void _showSnackBarAndSignOut(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        FirebaseAuth.instance.signOut().then((_) {
          if (mounted) {
            _navigateToPage(const DashboardPage());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
