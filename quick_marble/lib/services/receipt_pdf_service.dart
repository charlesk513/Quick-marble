import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

    final dateFormat = DateFormat('dd MMM yyyy');
    final receiptNumber = 'RCP-${payment.id}';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.055,
                child: pw.Image(
                  logo,
                  width: 340,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        header: (context) => _pageHeader(
          logo: logo,
          receiptNumber: receiptNumber,
          currentPage: context.pageNumber,
          totalPages: context.pagesCount,
        ),
        footer: (context) => _pageFooter(
          currentPage: context.pageNumber,
          totalPages: context.pagesCount,
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _documentTitle(),
          pw.SizedBox(height: 16),
          _receiptInformation(
            contract: contract,
            payment: payment,
            receiptNumber: receiptNumber,
            paymentDate: dateFormat.format(payment.paidAt),
          ),
          pw.SizedBox(height: 20),
          _sectionHeading('PAYMENT DETAILS'),
          pw.SizedBox(height: 8),
          _paymentDetails(contract, payment),
          pw.SizedBox(height: 20),
          _paymentStatus(contract),
          if (payment.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeading('NOTES'),
            pw.SizedBox(height: 8),
            _informationBox(payment.notes.trim()),
          ],
          pw.SizedBox(height: 22),
          _sectionHeading('ACKNOWLEDGEMENT'),
          pw.SizedBox(height: 8),
          _informationBox(
            'Quick Marble & Granite acknowledges receipt of the payment shown above. '
            'Please retain this receipt for your records.',
          ),
          pw.SizedBox(height: 28),
          _signatureSection(),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: '$receiptNumber.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _pageHeader({
    required pw.MemoryImage logo,
    required String receiptNumber,
    required int currentPage,
    required int totalPages,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.green800,
            width: 1.4,
          ),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 62,
            height: 62,
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 13),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'QUICK MARBLE & GRANITE',
                  style: const pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'A Service On Your Time',
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                receiptNumber,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              if (totalPages > 1)
                pw.Text(
                  'Page $currentPage of $totalPages',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter({
    required int currentPage,
    required int totalPages,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.7),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Quick Marble & Granite',
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Page $currentPage of $totalPages',
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _documentTitle() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: pw.BoxDecoration(
            color: PdfColors.green800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'PAYMENT RECEIPT',
            style: const pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.1,
            ),
          ),
        ),
        pw.Text(
          'All amounts are in Uganda Shillings (UGX)',
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _receiptInformation({
    required Contract contract,
    required ContractPayment payment,
    required String receiptNumber,
    required String paymentDate,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: _labelValue('Client', contract.clientName)),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _labelValue('Receipt No.', receiptNumber)),
            ],
          ),
          pw.SizedBox(height: 9),
          pw.Row(
            children: [
              pw.Expanded(
                child: _labelValue('Contract No.', contract.number),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _labelValue(
                  'Quotation No.',
                  contract.quotationNumber,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 9),
          pw.Row(
            children: [
              pw.Expanded(child: _labelValue('Payment Date', paymentDate)),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _labelValue('Payment Method', payment.method.label),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionHeading(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green800, width: 1),
        ),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _paymentDetails(
    Contract contract,
    ContractPayment payment,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          _line('Payment Method', payment.method.label),
          if (payment.reference.trim().isNotEmpty)
            _line('Reference', payment.reference.trim()),
          pw.SizedBox(height: 4),
          _moneyLine(
            'AMOUNT RECEIVED',
            payment.amount,
            bold: true,
            highlight: true,
          ),
          pw.Divider(color: PdfColors.green800, thickness: 1),
          _moneyLine('Contract Value', contract.value),
          _moneyLine('Total Paid', contract.totalPaid),
          _moneyLine(
            'Balance After Payment',
            contract.balance,
            bold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _paymentStatus(Contract contract) {
    final isPaid = contract.isPaidFully;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: isPaid ? PdfColors.green50 : PdfColors.amber50,
        border: pw.Border.all(
          color: isPaid ? PdfColors.green300 : PdfColors.amber300,
        ),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        isPaid
            ? 'PAYMENT STATUS: CONTRACT FULLY PAID'
            : 'PAYMENT STATUS: OUTSTANDING BALANCE ${formatUgx(contract.balance)}',
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: isPaid ? PdfColors.green800 : PdfColors.orange800,
        ),
      ),
    );
  }

  pw.Widget _informationBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 10,
          lineSpacing: 3,
        ),
      ),
    );
  }

  pw.Widget _signatureSection() {
    return pw.Row(
      children: [
        pw.Expanded(child: _signatureBox('Received By')),
        pw.SizedBox(width: 18),
        pw.Expanded(child: _signatureBox('Company Stamp')),
      ],
    );
  }

  pw.Widget _signatureBox(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 32,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _moneyLine(
    String label,
    double amount, {
    bool bold = false,
    bool highlight = false,
  }) {
    final style = pw.TextStyle(
      fontSize: highlight ? 11 : 9.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: highlight ? PdfColors.green800 : PdfColors.black,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 12),
          pw.Text(formatUgx(amount), style: style),
        ],
      ),
    );
  }
}
