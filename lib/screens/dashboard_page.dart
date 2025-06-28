import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text("Care Flow Dashboard"),
      ),
      body:Center(
        child: Text("Welcome to Care Flow!"),
      ),
    );
  }
}