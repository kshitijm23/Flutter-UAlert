import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const UrbanAlertApp());
}

class UrbanAlertApp extends StatelessWidget {
  const UrbanAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Alert',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UrbanAlertHomePage(),
    );
  }
}

// Shaed storage for reported events
class EventStorage {
  static final List<Map<String, String>> reportedEvents = [];
}

// New Page: Reported Events Page
class ReportedEventsPage extends StatelessWidget {
  const ReportedEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = EventStorage.reportedEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Events'),
      ),
      body: events.isEmpty
          ? const Center(
              child: Text(
                'No events reported yet.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: const Icon(Icons.report),
                  title: Text(event['type']!),
                  subtitle: Text(event['location']!),
                );
              },
            ),
    );
  }
}

class UrbanAlertHomePage extends StatelessWidget {
  const UrbanAlertHomePage({super.key});

  // Function to get the current location with high accuracy
  Future<Position> _getAccurateLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Request location with high accuracy
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Retry for better accuracy if needed
    if (position.accuracy > 50) {
      await Future.delayed(const Duration(seconds: 2)); // Wait for better accuracy
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    return position;
  }

  // Function to send an email
  Future<void> _sendEmail(String subject, String body) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'recipient@example.com', // Replace with the recipient's email
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      print('Could not launch email client');
    }
  }

  // Helper function to encode query parameters (for subject and body)
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Function to handle the action when a button is clicked
  Future<void> _handleReport(String reportType) async {
    try {
      Position position = await _getAccurateLocation();
      String mapLink =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      // Add the event to shared storage
      EventStorage.reportedEvents.add({
        'type': reportType,
        'location': mapLink,
      });

      // Prepare email body
      String body =
          'Hello, I am reporting $reportType located at this location:\n\nLocation: $mapLink\n\n  Please look into it as soon as possible.\n\nThank you.';
      _sendEmail('$reportType Report', body);
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            // Navigate to the ReportedEventsPage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportedEventsPage()),
            );
          },
        ),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UrbanAlertHomePage()),
            );
          },
          child: Image.asset(
            'assets/UA1.png', // Your logo image path
            height: 40,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/adobestock_1453011972x.jpg"), // Your background image path
            fit: BoxFit.cover, // Cover the entire screen with the image
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Highlighted Text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), // Highlight color with transparency
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  child: const Text(
                    'Welcome to Urban Alert',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text color
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Stay updated with the latest alerts in your area.',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _handleReport('Pothole');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Report Pothole'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _handleReport('Water Leakage');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Report Water Leakage'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _handleReport('Garbage');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Report Garbage'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 