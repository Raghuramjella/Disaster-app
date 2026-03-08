import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'damage_form.dart';

class VictimForm extends StatefulWidget {
  const VictimForm({super.key});

  @override
  State<VictimForm> createState() => _VictimFormState();
}

class _VictimFormState extends State<VictimForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNoController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();

  bool loading = false;

  Future<void> saveVictim() async {
    if (nameController.text.isEmpty ||
        mobileController.text.isEmpty ||
        addressController.text.isEmpty ||
        aadhaarController.text.isEmpty ||
        bankNameController.text.isEmpty ||
        accountNoController.text.isEmpty ||
        ifscController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      DocumentReference victimRef =
          await FirebaseFirestore.instance.collection('victims').add({
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'address': addressController.text.trim(),
        'aadhaar': aadhaarController.text.trim(),
        'bankName': bankNameController.text.trim(),
        'accountNo': accountNoController.text.trim(),
        'ifsc': ifscController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DamageForm(victimId: victimRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save victim data")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Victim Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Victim Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aadhaarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Aadhaar Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Bank Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(
                labelText: "Bank Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountNoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Account Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ifscController,
              decoration: const InputDecoration(
                labelText: "IFSC Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveVictim,
                    child: const Text("Next: Damage Details"),
                  ),
          ],
        ),
      ),
    );
  }
}
