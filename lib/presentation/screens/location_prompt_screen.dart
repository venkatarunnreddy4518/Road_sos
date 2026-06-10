// lib/presentation/screens/location_prompt_screen.dart
import 'package:flutter/material.dart';

class LocationPromptScreen extends StatefulWidget {
  const LocationPromptScreen({super.key});

  @override
  State<LocationPromptScreen> createState() => _LocationPromptScreenState();
}

class _LocationPromptScreenState extends State<LocationPromptScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  void _submitLocation() {
    final city = _cityController.text.trim();
    final area = _areaController.text.trim();

    if (city.isNotEmpty && area.isNotEmpty) {
      // In a real app, this would call a geocoding service to get coordinates
      // For now, we simulate successful manual entry
      Navigator.pop(context, {'city': city, 'area': area});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both city and area')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Location Manually')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We cannot access your GPS. Please enter your location to find the nearest helpers.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Area/Locality',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitLocation,
                child: const Text('Find Helpers'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
