import'package:flutter/material.dart';

class CaregiverDashboard extends StatelessWidget{
  const CaregiverDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CAREGIVER DASHBOARD'),
      ),
      body: SafeArea(
          child:SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  //Patient list and upcoming Patient visits row
                  Row(
                    children: [
                      Expanded(child: _patientListCard(),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                          child: _upcomingPatientsVisitsCard(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  //Patient Activity Log and Alerts/Notifications row
                  Row(
                    children: [
                      Expanded(
                        child: _patientActivityLogCard(),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                          child:_alertsAndNotificationsCard(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  //Second Patient Activity Log ad quick Actions row
                  Row(
                    children: [
                      Expanded(child: _patientActivityLogCard(),
                      ),
                      SizedBox(width: 16),
                      Expanded(child: _quickActionsCard(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ) ,
      ),
    );
  }
  //Patient List Card
  _patientListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATIENT LIST',
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold
            ),
          ),
          Divider(thickness: 1.5),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 10, //Replace with actual patient list length
            itemBuilder: (context, index){
              return Row(
                children: [
                  Text('Patient Name $index'),
                  Spacer(),
                  Text('Status'),//Replace with actual status
                ],
              );
            },
          ),
        ],
      ),
      ),
    );
  }
  //Upcoming Patients Visits Card
  _upcomingPatientsVisitsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPCOMING PATIENT VISITS',
              style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 1.5),
            ListView.builder(
                shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 10, //replace with actual visits length
              itemBuilder: (context, index){
                  return Row(
                    children: [
                      Text(
                        'Patient Name $index'
                      ),
                      SizedBox(width: 10),
                      Text('Location'), //replace with actual location, i think it will b google maps
                      Spacer(),
                      Text('9:00 AM'), //replace with actual time
                    ],
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
  //Patient Activity Log Card
  _patientActivityLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PATIENT ACTIVITY LOG',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 1.5),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 10,//replace with actual log length
              itemBuilder: (context, index){
                return Row(
                  children: [
                    Text('Took Medication'), //replace with actual task
                    Spacer(),
                    Text('Completed'), //Relace with the actual status
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  _alertsAndNotificationsCard(){
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALERTS AND NOTIFICATIONS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 1.5),
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning),
                    SizedBox(width: 10),
                    Text('Emergency alert John Kelly'), //Shall be replaced with actual alert logic
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.circle),
                    SizedBox(width: 10),
                    Text('Jane is reminded to take her medicine'), //Shall be replaced with actual alert logic
                  ],
                ),
                //more alerts shall be loaded queue fully
              ],
            ),
          ],
        ),
      ),
    );
  }
  _quickActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUICK ACTIONS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 1.5),
            Column(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.message),
                  label: Text('Send Message'),
                  onPressed: () {
                    //Add send message logic here
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                  onPressed: () {
                    //Add settings logic here
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.medical_services),
                  label: Text('View Medical History'),
                  onPressed: () {
                    //Add view medical history logic here
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}