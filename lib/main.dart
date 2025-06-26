import 'package:flutter/material.dart';

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
  final _passwordContoller = TextEditingController();
  final _fullNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEnailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordContoller = TextEditingController();
  String _selectedRole = "Patient";
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
              )
            ],
          ),
        ],
      ),
    ),
  )
  }
}