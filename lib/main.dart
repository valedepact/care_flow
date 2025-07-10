import 'package:flutter/material.dart';
import 'package:care_flow/screens/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Flow',
      // Set DashboardPage as the initial screen of the application.
      home: const DashboardPage(),

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
