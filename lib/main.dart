import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core
import 'package:care_flow/firebase_options.dart'; // Import firebase_options.dart

import 'package:care_flow/screens/role_router_screen.dart'; // Import the new RoleRouterScreen
// Remove direct imports for DashboardPage and MyHomePage if they are only accessed via RoleRouterScreen
// import 'package:care_flow/screens/dashboard_page.dart';
// import 'package:care_flow/screens/homepage.dart';
import 'package:care_flow/screens/visit_schedule_page.dart'; // Keep other necessary imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use generated options
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Flow',
      // Set RoleRouterScreen as the initial screen
      home: const RoleRouterScreen(),

      // Define named routes if you still need them, but main navigation will be via RoleRouter
      routes: {
        // '/dashboard': (context) => const DashboardPage(), // Now handled by RoleRouter
        '/visitSchedule': (context) => const VisitSchedulePage(),
        // Add other routes here as needed
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // useMaterial3: true, // Consider enabling Material 3
      ),
    );
  }
}
