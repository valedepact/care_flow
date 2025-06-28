import 'package:flutter/material.dart';
import 'package:care_flow/screens/dashboard_page.dart';

class LoginCard extends StatelessWidget{
  const LoginCard({super.key});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Login in into your account",
              style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Username or email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text("Login"),
              onPressed: () {
                //login logic lies here
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
            SizedBox(height: 8),
            TextButton(child: Text("Forgot Password?"),
              onPressed: () {
                //forgot password logic will lie here
              },
            ),
          ],
        ),),
    );
}