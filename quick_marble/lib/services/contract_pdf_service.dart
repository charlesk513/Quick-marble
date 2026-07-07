import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contract.dart';
import '../screens/shared/money_text.dart';

class ContractPdfService {
  Future<void> printContract({required Contract contract}) async {
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
                      color: PdfColors.green800,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
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
          pw.SizedBox(height: 20),
          pw.Text(
            'CONTRACT AGREEMENT',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Contract No: ${contract.number}'),
          pw.Text('From Quotation: ${contract.quotationNumber}'),
          pw.Text('Client: ${contract.clientName}'),
          pw.Text('Status: ${contract.status.label}'),
          pw.Text(
              'Start Date: ${contract.startDate.toString().split(' ').first}'),
          if (contract.completionDate != null)
            pw.Text(
              'Completion Date: ${contract.completionDate.toString().split(' ').first}',
            ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _pdfMoneyLine('Contract Value', contract.value),
                _pdfMoneyLine('Amount Paid', contract.amountPaid),
                pw.Divider(),
                _pdfMoneyLine('Balance', contract.balance, bold: true),
              ],
            ),
          ),
          if (contract.documentName.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Attached Document/Reference: ${contract.documentName}'),
          ],
          if (contract.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Notes',
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(contract.notes),
          ],
          pw.SizedBox(height: 30),
          pw.Text(
            'Agreement Terms',
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This contract confirms that Quick Marble & Granite will deliver the agreed work/items based on the referenced approved quotation. Payment, delivery, installation, and completion shall follow the agreed terms between the company and the client.',
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Client Signature: __________________'),
              pw.Text('Company Signature/Stamp: __________________'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _pdfMoneyLine(String label, double amount, {bool bold = false}) {
    final style =
        bold ? const pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(formatUgx(amount), style: style),
        ],
      ),
    );
  }
}
