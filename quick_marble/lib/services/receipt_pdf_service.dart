import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contract.dart';
import '../screens/shared/money_text.dart';

class ReceiptPdfService {
  Future<void> printReceipt({
    required Contract contract,
    required ContractPayment payment,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/logo.jpg');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final balanceAfterPayment = contract.balance;

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
            'PAYMENT RECEIPT',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Receipt No: ${payment.id}'),
          pw.Text('Contract No: ${contract.number}'),
          pw.Text('Client: ${contract.clientName}'),
          pw.Text('Date: ${payment.paidAt.toString().split(' ').first}'),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _line('Payment Method', payment.method.label),
                if (payment.reference.isNotEmpty)
                  _line('Reference', payment.reference),
                _moneyLine('Amount Paid', payment.amount, bold: true),
                pw.Divider(),
                _moneyLine('Contract Value', contract.value),
                _moneyLine('Total Paid', contract.totalPaid),
                _moneyLine('Balance After Payment', balanceAfterPayment),
              ],
            ),
          ),
          if (payment.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Notes',
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(payment.notes),
          ],
          pw.SizedBox(height: 36),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Received By: __________________'),
              pw.Text('Company Stamp: __________________'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _moneyLine(String label, double amount, {bool bold = false}) {
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
