import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contract.dart';
import '../screens/shared/money_text.dart';

class DeliveryNotePdfService {
  Future<void> printDeliveryNote({required Contract contract}) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/logo.jpg');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          buildBackground: (context) => pw.Center(
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Image(logo, width: 360),
            ),
          ),
        ),
        build: (context) => [
          pw.Row(
            children: [
              pw.Image(logo, width: 70, height: 70),
              pw.SizedBox(width: 14),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'QUICK MARBLE & GRANITE',
                    style: const pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    'A Service On Your Time',
                    style: const pw.TextStyle(
                      color: PdfColors.red800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'DELIVERY NOTE',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Delivery Note No: DN-${contract.number}'),
          pw.Text('Contract No: ${contract.number}'),
          pw.Text('Quotation No: ${contract.quotationNumber}'),
          pw.Text('Client: ${contract.clientName}'),
          pw.Text('Date: ${DateTime.now().toString().split(' ').first}'),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Items / Work Delivered',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Materials and/or installation work delivered under contract ${contract.number}, based on approved quotation ${contract.quotationNumber}.',
                ),
                pw.SizedBox(height: 12),
                pw.Text('Contract Value: ${formatUgx(contract.value)}'),
                pw.Text('Balance: ${formatUgx(contract.balance)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 36),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Delivered By: __________________'),
              pw.Text('Received By: __________________'),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Client Signature: __________________'),
              pw.Text('Company Stamp: __________________'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
