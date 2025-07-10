import'package:flutter/material.dart';

class VisitSchedulePage extends StatelessWidget{
  const VisitSchedulePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Column(
        children: [
          _TopHeaderSection(), //top header/control section
          Expanded(child: Row(
            children: [
              Flexible(flex: 2,
                child: _PatientListSection(),//left panel is for patient list
              ),
              Flexible(
                flex: 3,
                child: _CalenderAndVisitDetailsSection(),//right panel is for calender
              ),
            ],
          )
          )
        ],
      ),
    );
  }
}

class _TopHeaderSection extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text('Visit Schedule',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                children: [
                  ElevatedButton.icon(
                    label: Text('Schedule Visit'),
                    icon:Icon(Icons.calendar_today),
                    onPressed: () {},
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(onPressed: () {},
                    child: Text('Reschedule'),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(onPressed: () {},
                    child: Text('Cancel'),
                  ),
                  SizedBox(width:8),
                  DropdownButton(
                    value:'Options',
                    items: const [
                      DropdownMenuItem(value: 'Options',child: Text('Options'),
                      ),
                    ],
                    onChanged: (value){},
                  )
                ],
              )
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filters',
                  border: OutlineInputBorder(),
                ),
                value: 'Filters',
                items: const[
                  DropdownMenuItem(value: 'Filters',child: Text('Filters'),
                  ),
                ],
                onChanged: (value) {},
              ),
              ),
              SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText:'Date Range',
                  border: OutlineInputBorder(),
                ),
                value: 'Date Range',
                items: const[
                  DropdownMenuItem(value: 'Date Range',child: Text('Date Range'),
                  ),
                ],
                onChanged: (value) {},
              ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search patient or visit...',
                    border: OutlineInputBorder(),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _PatientListSection extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('April 2024',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildPatientVisitCard('Anna Davis'),
                SizedBox(height: 8),
                _buildPatientVisitCard('Walter Reed', isSelected: true),
                SizedBox(height: 8),
                _buildPatientVisitCard('Fred Somme'),
                SizedBox(height: 8),
                _buildPatientVisitCard('Sara grids'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_buildPatientVisitCard(String name, {bool isSelected = false}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/avatar.png'), //will replace with an actual image. create assets folder
        ),
        SizedBox(width: 16),
        Text(name),
      ],
    ),
  );
}

class _CalenderAndVisitDetailsSection extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalenderSection(),
          SizedBox(height: 16),
          Text('Visit Details'),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Health Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        _buildDetailInfoRow('Conditions'),
                        SizedBox(height: 8),
                        _buildDetailInfoRow('Allergies'),
                        SizedBox(height: 8),
                        _buildDetailInfoRow('Medications'),
                        SizedBox(height: 8),
                        _buildDetailInfoRow('Key History'),
                      ],
                    ),
                  ),
                ),
                ),
                SizedBox(width: 16),
                Expanded(child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visit Specific Notes and Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        _buildDetailInfoRow('Required Actions'),
                        SizedBox(height: 16),
                        Text('Add New Notes:'),
                        SizedBox(height: 8),
                        Expanded(child: TextField(
                          minLines: 5,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        ),
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed:() {},
                            child: Text('Update Notes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
_buildDetailInfoRow(String title) {
  return Row(
    children: [
      Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      Text(
        'Sample Info Sample Info Sample Info Sample Info Sample Info Sample Info',//Replace with actual data
        style: TextStyle(fontSize: 16),
      ),
    ],
  );
}
_buildCalenderSection() {
  return Column(
    children: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {},
          ),
          Text(
            'April 2024',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ],
      ),
      SizedBox(height: 16),
      Row(
        children: [
          Text('Sun', style: TextStyle(fontSize: 16)),
          SizedBox(width: 32),
          Text('Mon', style: TextStyle(fontSize: 16)),
          SizedBox(width: 32),
          Text('Tue', style: TextStyle(fontSize: 16)),
          SizedBox(width: 32),
          Text('Wed', style: TextStyle(fontSize: 16)),
          SizedBox(width: 32),
          Text('Thu', style: TextStyle(fontSize: 16)),
          SizedBox(width: 32),
          Text('Fri', style: TextStyle(fontSize: 16)),
          SizedBox(width: 32),
          Text('Sat', style: TextStyle(fontSize: 16)),
        ],
      ),
      SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7,),
        itemCount: 31, //assuming 31 days in a month
        itemBuilder: (context, index){
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    ],
  );
}