import 'package:care_flow/screens/visit_schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:care_flow/screens/home_page.dart';

void main(){
  runApp(MyApp());
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Flow',
      initialRoute: '/',
      routes: {
        '/visitSchedule': (context)=> VisitSchedulePage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}



