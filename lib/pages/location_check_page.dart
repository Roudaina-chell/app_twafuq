import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationCheckPage extends StatefulWidget {
  const LocationCheckPage({super.key});

  @override
  State<LocationCheckPage> createState() => _LocationCheckPageState();
}

class _LocationCheckPageState extends State<LocationCheckPage> {
  Position? position;
  bool loading = false;
  String message = 'اضغط على الزر للحصول على موقعك';

  Future<void> checkLocation() async {
    setState(() {
      loading = true;
      message = 'جاري تحديد موقعك...';
    });

    final result = await LocationService.getCurrentLocation();

    setState(() {
      loading = false;

      if (result != null) {
        position = result;
        message = 'تم تحديد موقعك ✅';
      } else {
        message = 'لم نتمكن من الحصول على موقعك ❌';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Check'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              if (position != null) ...[
                Text('Latitude: ${position!.latitude}'),
                Text('Longitude: ${position!.longitude}'),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: loading ? null : checkLocation,
                child: Text(
                  loading ? 'جاري التحقق...' : 'تحقق من موقعي',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}