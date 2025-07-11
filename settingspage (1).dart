import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkMode = false;
  bool backupEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Account', style: sectionTitle),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile Information'),
            subtitle: const Text('Edit your profile details'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Availability Status'),
            subtitle: const Text('Online, Busy, Offline'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Text('Notifications', style: sectionTitle),
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (val) => setState(() => notificationsEnabled = val),
            title: const Text('Enable Notifications'),
            secondary: const Icon(Icons.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.do_not_disturb_on),
            title: const Text('Do Not Disturb'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Text('Chat Settings', style: sectionTitle),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Message Font Size'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(darkMode ? 'Dark' : 'Light'),
            onTap: () {
              setState(() => darkMode = !darkMode);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear Chat History'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Text('Privacy & Security', style: sectionTitle),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Two-Factor Authentication'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('App Lock'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Account'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Text('Storage & Backup', style: sectionTitle),
          SwitchListTile(
            value: backupEnabled,
            onChanged: (val) => setState(() => backupEnabled = val),
            title: const Text('Enable Cloud Backup'),
            secondary: const Icon(Icons.backup),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Clear Cache'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Text('Support', style: sectionTitle),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & FAQs'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a Bug'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Text('Legal', style: sectionTitle),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            onTap: () {},
          ),

          const SizedBox(height: 20),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

const TextStyle sectionTitle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.blue,
);
