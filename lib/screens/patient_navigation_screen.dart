import 'package:flutter/material.dart';
import 'maps_screen.dart';

class PatientNavigationScreen extends StatelessWidget {
  final List<Map<String, dynamic>> patients = [
    {
      'name': 'Patient A',
      'address': 'Kampala, Uganda',
      'latitude': 0.3476,
      'longitude': 32.5825,
    },
    {
      'name': 'Patient B',
      'address': 'Entebbe, Uganda',
      'latitude': 0.0457,
      'longitude': 32.4435,
    },
    {
      'name': 'Patient C',
      'address': 'Jinja, Uganda',
      'latitude': 0.4246,
      'longitude': 33.2040,
    },
  ];

  PatientNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patients Navigation')),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text(patient['name']),
              subtitle: Text(patient['address']),
              trailing: ElevatedButton.icon(
                icon: Icon(Icons.map),
                label: Text('Navigate'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        patientName: patient['name'],
                        latitude: patient['latitude'],
                        longitude: patient['longitude'],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
