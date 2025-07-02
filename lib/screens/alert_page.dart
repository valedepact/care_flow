import'package:flutter/material.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class AlertListItem extends StatelessWidget {
  final String patientName;
  final String alertType;
  final String timestamp;
  final Function onPressed;
  const AlertListItem({super.key,
    required this.patientName,
    required this.alertType,
    required this.timestamp,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage('assets/patient_image.png'),
      ),
      title: Text(patientName),
      subtitle: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.red,
            child: Text(alertType),
          ),
          SizedBox(width: 8),
          Text(timestamp),
        ],
      ),
      onTap: onPressed as VoidCallback,
    );
  }
}

class _AlertsPageState extends State<AlertsPage> {
  String _selectedAlertType = 'All';
  String _selectedStatus= 'All';
  get _selectedPatientName => 'All Patients';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Text('Alerts'),
          Spacer(),
          Stack(
            children: [
              Icon(Icons.notifications),
              Positioned(
                top:0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        ],
      ),),
      body: Column(
        children: [
          //Filter and Search Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter and search',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton(
                      value: _selectedAlertType,
                      items: [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                        DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                      ],
                      onChanged: (value){
                        setState(() {
                          _selectedAlertType = value!;
                        });
                      },
                    ),
                    DropdownButton(
                      value: _selectedStatus,
                      items:[
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    DropdownButton(
                      value: _selectedPatientName,
                      items:[
                        DropdownMenuItem(value: 'All Patients', child: Text('All Patients')),
                        DropdownMenuItem(value: 'John Kelly', child: Text('John Kelly')),
                        DropdownMenuItem(value: 'Greg teri', child: Text('Greg Teri')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value as String;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          //Main Content Area
          Expanded(child: Row(
            children: [
              //Alert List Column
              Expanded(
                  child: Column(
                    children: [
                      Padding(padding: const EdgeInsets.all(16),
                      child: Text('Alert List',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ),
                      Expanded(
                          child: ListView.builder(
                              itemCount:10, //temporary, shall be replaced with actual data
                            itemBuilder: (context, index){
                                return AlertListItem(
                                  patientName: 'John Kelly',
                                  alertType:'Emergency',
                                  timestamp: '10m ago',
                                  onPressed:(){
                                    //handle Alert tap here
                                  },
                                );
                            },
                          ),
                      ),
                    ],
                  ),
              ),
              //Vertical Divider
              VerticalDivider(
                thickness: 1,
                color: Colors.grey,
              ),
              //Alert Details Column
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Alert Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/patient_image.png'), //should add image from asset, better create asset folder
                    ),
                    SizedBox(height: 16),
                    Text(
                      'John Kelly',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text('Description: Patient is having chest pain',
                    style: TextStyle(fontSize: 16,
                    color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Medical History: Hypertension, Type 2 diabetes',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 24),
                    //action Buttons
                    Column(
                      children: [
                        ElevatedButton(
                            onPressed: () {
                          //Handle Acknowledge tap logic
                              print('Alert acknowledged');
                        },
                            child: Text('Acknowledge'),
                        ),
                        SizedBox(height: 8),
                        OutlinedButton(
                            onPressed: () {
                              //Handle resolve logic here
                              print('Alert resolved');
                            },
                            child: Text('Resolve'),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Resolution notes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(onPressed: () {
                              //Handle the assign logic
                            },
                                child:Text('Assign'),
                            ),
                            ElevatedButton(onPressed: () {
                              //Handle escalate tap
                              print('Alert escalated');
                            },
                              child: Text('Escalate'),
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              //Bottom Navigation Bar
              Align(
                alignment: Alignment.bottomCenter,
                child:  Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(128),
                        spreadRadius: 2,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tamale Denis',
                              style: TextStyle(fontSize: 16),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4
                                  ),
                                  color: Colors.red,
                                  child: Text('EMERGENCY'),
                                ),
                                SizedBox(width:8),
                                Text('Patient is experiencing ches pain,'),
                              ],
                            )
                          ],
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(right: 16.0),
                      child: Text('BPAD 533721',
                      style: TextStyle(fontSize: 16),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),)
        ],
      ),
    );
  }
}