import 'package:care_flow/screens/alert_page.dart';
import 'package:care_flow/screens/emergency_alerts_page.dart';
import 'package:care_flow/screens/login_page.dart';
import 'package:care_flow/screens/visit_schedule_page.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text("Care Flow Dashboard"),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: LoginCard()),
          SizedBox(width: 16),
          Expanded(child: ElevatedButton(child: Text('Visit Schedule'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VisitSchedulePage()),
            );
          },
          ),
          ),
          Expanded(child: ElevatedButton(child: Text('Alerts'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlertsPage()),
              );
            },
          ),
          ),
          Expanded(child: ElevatedButton(child: Text('Emergency'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergencyAlertsPage()),
              );
            },
          ),
          ),
        ],
      ),
    );
  }
}