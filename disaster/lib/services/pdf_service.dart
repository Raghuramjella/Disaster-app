import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateReport(Map<String, dynamic> reportData, Map<String, dynamic> victimData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Disaster Damage Assessment Report")),
              pw.SizedBox(height: 20),
              pw.Text("Victim Details:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Name: ${victimData['name']}"),
              pw.Text("Mobile: ${victimData['mobile']}"),
              pw.Text("Aadhaar: ${victimData['aadhaar']}"),
              pw.Text("Address: ${victimData['address']}"),
              pw.SizedBox(height: 10),
              pw.Text("Bank Details:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Bank: ${victimData['bankName']}"),
              pw.Text("A/C: ${victimData['accountNo']}"),
              pw.Text("IFSC: ${victimData['ifsc']}"),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Damage Assessment:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Property Type: ${reportData['propertyType']}"),
              pw.Text("Damage Percentage: ${reportData['damagePercent']}%"),
              pw.Text("Estimated Compensation: INR ${reportData['estimatedCompensation']}"),
              pw.Text("Status: ${reportData['status']}"),
              pw.SizedBox(height: 20),
              pw.Text("Location: ${reportData['latitude']}, ${reportData['longitude']}"),
              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Authorized Signature", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
