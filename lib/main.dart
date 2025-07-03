import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nurse Patient Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: PatientProfilePage(),
    );
  }
}

class PatientProfilePage extends StatelessWidget {
  final Map<String, dynamic> patientData = {
    'name': 'HELLEN ',
    'age': 20,
    'gender': 'Female',
    'contact': '0709497401',
    'location': 'Kakoba,Mbarara',
    'emergency': false,
    'vitals': {
      'Heart Rate': '70 bpm',
      'Temperature': '35.8 °C',
      'Blood Pressure': '100/80 mmHg',
    }
  };

  PatientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isEmergency = patientData['emergency'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Profile"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildVitalsCard(),
            SizedBox(height: 20),
            _buildLocationCard(context),
            if (isEmergency) _buildEmergencyBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orange[100],
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(patientData['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("Age: ${patientData['age']} | Gender: ${patientData['gender']}"),
            SizedBox(height: 5),
            Text("Contact: ${patientData['contact']}"),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard() {
    final vitals = patientData['vitals'] as Map<String, String>;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vitals", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Divider(),
            ...vitals.entries.map((entry) => ListTile(
              leading: Icon(Icons.monitor_heart, color: Colors.red),
              title: Text(entry.key),
              trailing: Text(entry.value, style: TextStyle(fontWeight: FontWeight.w600)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Location", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(child: Text(patientData['location'])),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Launching directions..."))
                );
              },
              icon: Icon(Icons.directions),
              label: Text("Get Directions"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Emergency detected! Immediate attention needed.",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
