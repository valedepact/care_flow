import 'package:flutter/material.dart';
import 'package:care_flow/screens/dashboard_page.dart';

class RegisterCard extends StatelessWidget{
  const RegisterCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Create a New Account",
              style: TextStyle(fontSize:18,fontWeight:FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Email",
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
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
              value: "Nurse",
              onChanged: (newValue){
                //Role selection logic falls here
              },
              items: [
                DropdownMenuItem(value:"Nurse",child:Text("Nurse"),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(child: Text("Register"),
              onPressed: () {
                //registration logic lies over here
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}