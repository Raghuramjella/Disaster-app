import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_service.dart';

class ReportsList extends StatelessWidget {
  const ReportsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submitted Reports")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading reports"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No reports found"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("${data['propertyType']} - ${data['damagePercent']}%"),
                  subtitle: Text("₹${(data['estimatedCompensation'] as double).toStringAsFixed(0)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(data['status'] ?? 'Submitted'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () async {
                          final victimDoc = await FirebaseFirestore.instance
                              .collection('victims')
                              .doc(data['victimId'])
                              .get();
                          if (victimDoc.exists) {
                            await PdfService.generateReport(
                              data,
                              victimDoc.data() as Map<String, dynamic>,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
