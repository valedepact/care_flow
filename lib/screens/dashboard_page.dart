import 'package:flutter/material.dart';
import 'package:care_flow/screens/login_page.dart'; // Import LoginPage for navigation
import 'package:care_flow/screens/register_page.dart'; // Import RegisterCard from its dedicated file

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // These variables are no longer needed in DashboardPage as it's a landing page
  // String _patientName = 'Loading...';
  // String _patientId = '';
  // bool _isLoadingUserData = true; // Separate loading for user data
  //
  // Appointment? _upcomingAppointment; // To store the fetched upcoming appointment
  // bool _isLoadingUpcomingAppointment = true;
  // String _upcomingAppointmentErrorMessage = '';

  @override
  void initState() {
    super.initState();
    // This DashboardPage is now the initial landing page.
    // It should not fetch patient data directly unless a user is already logged in.
    // The main purpose here is to present login/register options.
    // We can keep the data fetching logic for the actual PatientDashboardPage.
  }

  // Helper method to build primary CTA buttons
  Widget _buildCTAButton(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: Text(text),
    );
  }

  // Helper method to build outlined CTA buttons
  Widget _buildOutlinedCTAButton(BuildContext context, String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text),
    );
  }

  // Helper method to build feature list items
  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the features
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar for a clean welcome screen look
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 1. Logo and System Name
              Image.network(
                'https://placehold.co/100x100/007BFF/FFFFFF?text=Logo', // Placeholder logo
                height: 100,
                width: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_hospital,
                  size: 100,
                  color: Colors.blue,
                ), // Fallback icon
              ),
              const SizedBox(height: 16),
              Text(
                'CareFlow',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Tagline
              Text(
                "Streamlining healthcare for a better patient experience",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),

              // 3. Short Description
              Text(
                "CareFlow is a comprehensive healthcare management system connecting patients, providers, and facilities for efficient care coordination.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 4. Key Features Highlights
              Text(
                'Key Features',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(context, Icons.medical_services, 'Patient portal for secure access to medical records'),
              _buildFeatureItem(context, Icons.calendar_today, 'Appointment scheduling and reminders'),
              _buildFeatureItem(context, Icons.video_call, 'Telemedicine consultations'),
              _buildFeatureItem(context, Icons.receipt_long, 'Prescription management'),
              _buildFeatureItem(context, Icons.group, 'Care team collaboration tools'),
              const SizedBox(height: 40),

              // 5. Call-to-Action (CTA) Buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust button layout based on screen width
                  if (constraints.maxWidth > 600) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded( // Added Expanded
                          child: _buildCTAButton(context, 'Login', () {
                            // Navigate to Login Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()), // Correct LoginPage
                            );
                            debugPrint('Login button pressed');
                          }),
                        ),
                        const SizedBox(width: 20),
                        Expanded( // Added Expanded
                          child: _buildCTAButton(context, 'Sign Up', () {
                            // Navigate to Sign Up Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterCard()), // Correct RegisterCard
                            );
                            debugPrint('Sign Up button pressed');
                          }),
                        ),
                        const SizedBox(width: 20),
                        Expanded( // Added Expanded
                          child: _buildOutlinedCTAButton(context, 'Learn More', () {
                            // Handle Learn More action (e.g., scroll to a section, open a URL)
                            debugPrint('Learn More button pressed');
                          }),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildCTAButton(context, 'Login', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        }),
                        const SizedBox(height: 16),
                        _buildCTAButton(context, 'Sign Up', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterCard()), // Correct RegisterCard
                          );
                        }),
                        const SizedBox(height: 16),
                        _buildOutlinedCTAButton(context, 'Learn More', () {
                          debugPrint('Learn More button pressed');
                        }),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),

              // 6. Visuals (Placeholder)
              Image.network(
                'https://placehold.co/600x300/E0F2F7/007BFF?text=Healthcare+Illustration', // Placeholder illustration
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.blue.shade50,
                  child: Center(
                    child: Text(
                      'Healthcare Illustration Placeholder',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
