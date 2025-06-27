import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main(){
  runApp(MyApp());
}
class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Flow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget{
  @override
  _MyHomePageState createState()=> _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = "Nurse";
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
              Expanded(child: _LoginCard()),
              SizedBox(width: 16),
              Expanded(child: _RegisterCard()),
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
class _LoginCard extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Card(
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
}
class _RegisterCard extends StatelessWidget{
  @override
  Widget build(BuildContext context){
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
              DropdownMenuItem(child:Text("Nurse"),
              value:"Nurse",
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
class DashboardPage extends StatelessWidget {
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