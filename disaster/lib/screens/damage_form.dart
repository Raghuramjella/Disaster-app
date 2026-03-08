import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DamageForm extends StatefulWidget {
  final String victimId;

  const DamageForm({super.key, required this.victimId});

  @override
  State<DamageForm> createState() => _DamageFormState();
}

class _DamageFormState extends State<DamageForm> {
  String propertyType = 'Crop';
  double damagePercent = 50;
  bool loading = false;
  File? _image;
  Position? _currentPosition;

  final ImagePicker _picker = ImagePicker();

  final Map<String, int> baseValues = {
    'Crop': 20000, // per acre/unit approx
    'Kutcha House': 50000,
    'Pucca House': 200000,
    'Other': 10000,
  };

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.camera);
    if (selected != null) {
      setState(() {
        _image = File(selected.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  double calculateCompensation() {
    int baseValue = baseValues[propertyType] ?? 10000;
    return (damagePercent / 100) * baseValue;
  }

  Future<void> submitDamageReport() async {
    if (_image == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture image and location")),
      );
      return;
    }

    setState(() => loading = true);

    double compensation = calculateCompensation();

    try {
      // Upload image
      String fileName = 'reports/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask =
          FirebaseStorage.instance.ref().child(fileName).putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('reports').add({
        'victimId': widget.victimId,
        'propertyType': propertyType,
        'damagePercent': damagePercent,
        'estimatedCompensation': compensation,
        'imageUrl': imageUrl,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'status': 'Submitted',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Report submitted successfully\nEstimated Compensation: ₹${compensation.toStringAsFixed(0)}",
          ),
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit damage report")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Damage Assessment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Property Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: propertyType,
              isExpanded: true,
              items: baseValues.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  propertyType = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            const Text(
              "Damage Percentage",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: damagePercent,
              min: 0,
              max: 100,
              divisions: 10,
              label: "${damagePercent.round()}%",
              onChanged: (value) {
                setState(() {
                  damagePercent = value;
                });
              },
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture Image"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Get Location"),
                  ),
                ),
              ],
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("✅ Image Captured", style: TextStyle(color: Colors.green)),
              ),
            if (_currentPosition != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text("✅ Location Captured", style: TextStyle(color: Colors.green)),
              ),
            const SizedBox(height: 20),
            Text(
              "Estimated Compensation: ₹${calculateCompensation().toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const Spacer(),
            loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitDamageReport,
                      child: const Text("Submit Report"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
