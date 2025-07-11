import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For authentication state changes
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching user role from Firestore

import 'package:care_flow/screens/homepage.dart'; // Import your MyHomePage
import 'package:care_flow/screens/patient_dashboard_page.dart'; // Patient's dashboard
import 'package:care_flow/screens/nurse_dashboard_board.dart'; // Nurse's dashboard (CaregiverDashboard)

class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        // No user is signed in, go to login/register page
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()), // Correctly refers to MyHomePage
                (route) => false, // Remove all previous routes
          );
        }
      } else {
        // User is signed in, fetch their role from Firestore
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            String? role = userDoc.get('role'); // Get the 'role' field

            if (mounted) {
              if (role == 'Patient') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
                      (route) => false,
                );
              } else if (role == 'Nurse') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const CaregiverDashboard()), // Correctly refers to CaregiverDashboard
                      (route) => false,
                );
              } else {
                // Handle unknown role or no role found
                debugPrint('Unknown role or role not set for user: ${user.uid}');
                // Optionally sign out and go to login page
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                        (route) => false,
                  );
                }
              }
            }
          } else {
            // User document does not exist in Firestore (e.g., deleted manually)
            debugPrint('User document not found for UID: ${user.uid}');
            await FirebaseAuth.instance.signOut(); // Sign out the invalid user
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
                    (route) => false,
              );
            }
          }
        } catch (e) {
          debugPrint('Error fetching user role: $e');
          // In case of error, sign out and go to login page
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage()),
                  (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while determining the route
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading user profile...'),
          ],
        ),
      ),
    );
  }
}
