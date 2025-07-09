import 'package:flutter/material.dart';

void main() {
  runApp(PatientProfileApp());
}

class PatientProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Profile',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: PatientProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PatientProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Profile'),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              children: [
                _buildProfileHeader(),
                SizedBox(height: 16),
                _buildSectionCard(
                  title: '1. Personal & Demographic Information',
                  items: [
                    _infoRow('Full Name', ' Hellen Namwesezi'),
                    _infoRow('Age', '20'),
                    _infoRow('Gender', 'Female'),
                    _infoRow('Contact', '+256 709497401'),
                    _infoRow('Insurance', 'Jubilee Health Plan'),
                    _infoRow('Emergency Contact', 'cathy - +256 757099046'),
                  ],
                ),
                _buildSectionCard(
                  title: '2. Medical History',
                  items: [
                    _infoRow('Past Illnesses', 'Asthma, Hypertension'),
                    _infoRow('Surgeries', 'Appendectomy - 2018'),
                    _infoRow('Chronic Conditions', 'Hypertension'),
                    _infoRow('Immunizations', 'COVID-19, Tetanus'),
                    _infoRow('Family History', 'Diabetes (Mother)'),
                  ],
                ),
                _buildSectionCard(
                  title: '3. Medications',
                  items: [
                    _infoRow('Current Medications', 'Metformin, Ventolin Inhaler'),
                    _infoRow('OTC Drugs', 'Paracetamol'),
                    _infoRow('Supplements', 'Vitamin D'),
                    _infoRow('Allergies', 'Penicillin'),
                  ],
                ),
                _buildSectionCard(
                  title: '4. Vital Signs',
                  items: [
                    _infoRow('Blood Pressure', '120/80 mmHg'),
                    _infoRow('Heart Rate', '75 bpm'),
                    _infoRow('Temperature', '36.8°C'),
                    _infoRow('Respiratory Rate', '16 breaths/min'),
                    _infoRow('Oxygen Saturation', '98%'),
                    _infoRow('Weight & Height', '65 kg / 170 cm (BMI: 22.5)'),
                  ],
                ),
                _buildSectionCard(
                  title: '5. Lab & Test Results',
                  items: [
                    _infoRow('Blood Tests', 'CBC: Normal, Sugar: 5.5 mmol/L'),
                    _infoRow('Imaging', 'Chest X-ray: Clear'),
                    _infoRow('ECG', 'Normal sinus rhythm'),
                    _infoRow('Biopsy Reports', 'N/A'),
                  ],
                ),
                _buildSectionCard(
                  title: '6. Recent Visit Notes',
                  items: [
                    _infoRow('Symptoms', 'Shortness of breath, fatigue'),
                    _infoRow('Physical Exam', 'Lungs clear, BP stable'),
                    _infoRow('Diagnosis', 'Mild asthma attack'),
                    _infoRow('Treatment', 'Inhaler, Rest'),
                    _infoRow('Doctor\'s Notes', 'Follow-up in 2 weeks'),
                  ],
                ),
                _buildSectionCard(
                  title: '7. Mental & Social Health',
                  items: [
                    _infoRow('Mental Health', 'Mild anxiety'),
                    _infoRow('Lifestyle', 'Non-smoker, Occasional alcohol'),
                    _infoRow('Support System', 'Lives with spouse, 2 kids'),
                    _infoRow('Occupation', 'Teacher, moderate stress'),
                  ],
                ),
                _buildSectionCard(
                  title: '8. Progress Notes',
                  items: [
                    _infoRow('Response to Treatment', 'Improving, less wheezing'),
                    _infoRow('Next Visit', '10 July 2025'),
                    _infoRow('Complications', 'None'),
                  ],
                ),
              ],
            ),
          ),
          // Floating directions button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.directions, color: Colors.white),
              label: Text(
                'Get Directions to Patient',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening map directions...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.teal[300],
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Hellen Namwesezi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'ID: 1001 | Female, 20',
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(height: 4),
          Text(
            'Contact: +256 709497401',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> items}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800])),
            SizedBox(height: 10),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Expanded(
              flex: 5,
              child: Text(value,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14))),
        ],
      ),
    );
  }
}
