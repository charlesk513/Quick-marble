import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

    final dateFormat = DateFormat('dd MMM yyyy');
    final deliveryNoteNumber = 'DN-${contract.number}';

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
          deliveryNoteNumber: deliveryNoteNumber,
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
          _deliveryInformation(
            contract: contract,
            deliveryNoteNumber: deliveryNoteNumber,
            deliveryDate: dateFormat.format(DateTime.now()),
          ),
          pw.SizedBox(height: 20),
          _sectionHeading('ITEMS / WORK DELIVERED'),
          pw.SizedBox(height: 8),
          _deliveryDescription(contract),
          if (contract.documentName.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('DOCUMENT REFERENCE'),
            pw.SizedBox(height: 8),
            _informationBox(contract.documentName.trim()),
          ],
          if (contract.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('DELIVERY NOTES'),
            pw.SizedBox(height: 8),
            _informationBox(contract.notes.trim()),
          ],
          pw.SizedBox(height: 22),
          _sectionHeading('DELIVERY CONFIRMATION'),
          pw.SizedBox(height: 8),
          _informationBox(
            'The undersigned confirms that the materials and/or installation work described above were delivered in the stated condition, subject to any written notes recorded on this delivery note.',
          ),
          pw.SizedBox(height: 28),
          _signatureSection(),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: '$deliveryNoteNumber.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _pageHeader({
    required pw.MemoryImage logo,
    required String deliveryNoteNumber,
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
          pw.Text(
            deliveryNoteNumber,
            style: const pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
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
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: pw.BoxDecoration(
            color: PdfColors.green800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'DELIVERY NOTE',
            style: const pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.1,
            ),
          ),
        ),
        pw.Text(
          'Delivery confirmation document',
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _deliveryInformation({
    required Contract contract,
    required String deliveryNoteNumber,
    required String deliveryDate,
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
              pw.Expanded(
                child: _labelValue('Delivery Note No.', deliveryNoteNumber),
              ),
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
              pw.Expanded(child: _labelValue('Delivery Date', deliveryDate)),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _labelValue('Contract Status', contract.status.label),
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

  pw.Widget _deliveryDescription(Contract contract) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Materials and/or installation work delivered under contract ${contract.number}, based on approved quotation ${contract.quotationNumber}.',
            style: const pw.TextStyle(
              fontSize: 10,
              lineSpacing: 3,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400),
          _moneyLine('Contract Value', contract.value),
          _moneyLine('Total Paid', contract.totalPaid),
          _moneyLine('Outstanding Balance', contract.balance, bold: true),
        ],
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
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(child: _signatureBox('Delivered By')),
            pw.SizedBox(width: 18),
            pw.Expanded(child: _signatureBox('Received By')),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Expanded(child: _signatureBox('Client Signature')),
            pw.SizedBox(width: 18),
            pw.Expanded(child: _signatureBox('Company Stamp')),
          ],
        ),
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

  pw.Widget _moneyLine(
    String label,
    double amount, {
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 9.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
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
