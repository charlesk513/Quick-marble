import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contract.dart';
import '../screens/shared/money_text.dart';

class InvoicePdfService {
  Future<void> printInvoice({required Contract contract}) async {
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
            'INVOICE',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Invoice No: INV-${contract.number}'),
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
              children: [
                _moneyLine('Contract Value', contract.value),
                _moneyLine('Total Paid', contract.totalPaid),
                pw.Divider(),
                _moneyLine('Balance Due', contract.balance, bold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (contract.payments.isNotEmpty) ...[
            pw.Text(
              'Payment Summary',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...contract.payments.map(
              (payment) => _paymentLine(payment),
            ),
          ],
          pw.SizedBox(height: 36),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Prepared By: __________________'),
              pw.Text('Company Stamp: __________________'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _paymentLine(ContractPayment payment) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${payment.paidAt.toString().split(' ').first} · ${payment.method.label}',
          ),
          pw.Text(formatUgx(payment.amount)),
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
