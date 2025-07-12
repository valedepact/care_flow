import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:care_flow/screens/patient_dashboard_page.dart';
import 'package:care_flow/screens/nurse_dashboard_board.dart';
import 'package:care_flow/screens/dashboard_page.dart'; // The initial landing page

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
      // If no user is logged in, navigate to the initial DashboardPage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      });
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (role == 'Patient') {
              debugPrint('RoleRouter: Navigating to PatientDashboardPage.');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
              );
            } else if (role == 'Nurse') {
              debugPrint('RoleRouter: Navigating to CaregiverDashboard.');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
              );
            } else {
              debugPrint('RoleRouter: Unknown role ($role) or incomplete profile for UID: ${user.uid}. Signing out.');
              // Handle unknown role or incomplete profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unknown role or incomplete profile. Please log in again.')),
              );
              FirebaseAuth.instance.signOut().then((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardPage()),
                  );
                }
              });
            }
          }
        });
      } else {
        // User document does not exist, meaning user is authenticated but profile is not set up
        debugPrint('RoleRouter: User profile not found for UID: ${user.uid}. Signing out.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User profile not found. Please complete registration or log in.')),
            );
            FirebaseAuth.instance.signOut().then((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint("RoleRouter: Error checking user role: $e. Navigating to DashboardPage.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error checking user role: $e')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      });
    }
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
