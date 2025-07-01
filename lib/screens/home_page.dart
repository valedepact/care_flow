import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:care_flow/screens/login_page.dart';
import 'package:care_flow/screens/register_page.dart';

class MyHomePage extends StatefulWidget{
  const MyHomePage({super.key});
  @override
  MyHomePageState createState() {
    return MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final String _selectedRole = "Nurse"; //this variable's value won't change
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 32),
            Center(
              child: Text("Care Flow",
                style: TextStyle(fontSize:24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: LoginCard()),
                SizedBox(width: 16),
                Expanded(child: RegisterCard()),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () {},
                  child:Text("Terms and Conditions"),
                ),
                VerticalDivider(),
                TextButton(
                  onPressed: () {},
                  child: Text("Privacy Policy"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text("Or login with"),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: FaIcon(FontAwesomeIcons.google),
                  label: Text("Google"),
                  onPressed: () {},
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.facebook),
                  label: Text("Facebook"),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
