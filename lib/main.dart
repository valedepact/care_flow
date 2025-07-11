import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core
import 'package:care_flow/firebase_options.dart'; // Import firebase_options.dart

import 'package:care_flow/screens/role_router_screen.dart'; // Import the RoleRouterScreen
import 'package:care_flow/screens/visit_schedule_page.dart'; // Keep other necessary imports
// Note: MyHomePage and DashboardPage are now accessed via RoleRouterScreen,
// so direct imports here are not strictly necessary if they are only routes.

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
      // Set RoleRouterScreen as the initial screen to handle authentication and routing
      home: const RoleRouterScreen(),

      // Define named routes if you still need them for specific navigations
      // Note: RoleRouterScreen will handle the initial routing to dashboards/homepage.
      routes: {
        // '/dashboard': (context) => const DashboardPage(), // Handled by RoleRouterScreen
        // '/': (context) => const MyHomePage(), // Handled by RoleRouterScreen
        '/visitSchedule': (context) => const VisitSchedulePage(),
        // Add other routes here as needed
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // useMaterial3: true, // Consider enabling Material 3 for modern UI
      ),
    );
  }
}
