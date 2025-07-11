import'package:flutter/material.dart';

class EmergencyAlertsPage extends StatefulWidget {
  const EmergencyAlertsPage({super.key});
  @override
  State<EmergencyAlertsPage> createState() => _EmergencyAlertsPageState();
}
class _EmergencyAlertsPageState extends State<EmergencyAlertsPage> {
  bool _alertSent = false;
  final TextEditingController _notesController = TextEditingController();
  void _sendAlert() {
    setState(() {
      _alertSent = true;
    });
  }
  void _cancelAlert() {
    setState(() {
      _alertSent = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
      ),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            ),
            elevation: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('EMERGENCY ALERT',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.black87),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _alertSent ? null : () => _sendAlert(),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(242),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: const Offset(0,3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SEND ALERT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Press to send immediate alert for emergency service',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16, color: Colors.black54,
                    ),
                  ),
                  //Alert Sent screen Content
                  if(_alertSent)
                    ...[
                      const SizedBox(height: 30),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alert successfully sent',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildStatusRow(
                        icon: Icons.location_on,
                        text: 'Patient location shared with emergency response service',
                        iconColor: Colors.black54,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Add additional notes(e.g. patient condition)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(value: true,//temporary value, add actual logic
                              onChanged: (bool? value){//add actual logic
                          },
                          activeColor: Colors.blue,
                          ),
                          const Expanded(child: Text(
                            'Notify emergency contacts',
                            style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(onPressed: _cancelAlert,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          child: const Text(
                            'CANCEL ALERT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildStatusRow({
    required IconData icon,
    required String text,
    required Color iconColor,
}){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
        ),
      ],
    );
  }
}