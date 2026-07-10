import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    final dateFormat = DateFormat('dd MMM yyyy');
    final invoiceNumber = 'INV-${contract.number}';

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
          invoiceNumber: invoiceNumber,
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
          _invoiceInformation(
            contract: contract,
            invoiceNumber: invoiceNumber,
            invoiceDate: dateFormat.format(DateTime.now()),
          ),
          pw.SizedBox(height: 20),
          _sectionHeading('AMOUNT SUMMARY'),
          pw.SizedBox(height: 8),
          _amountSummary(contract),
          if (contract.payments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeading('PAYMENT HISTORY'),
            pw.SizedBox(height: 8),
            _paymentsTable(contract, dateFormat),
          ],
          pw.SizedBox(height: 22),
          _paymentStatus(contract),
          pw.SizedBox(height: 22),
          _sectionHeading('PAYMENT NOTICE'),
          pw.SizedBox(height: 8),
          _informationBox(
            contract.isPaidFully
                ? 'This invoice is fully settled. No outstanding balance remains.'
                : 'Please quote the invoice number when making payment. The outstanding balance shown above remains payable under the agreed contract terms.',
          ),
          if (contract.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeading('NOTES'),
            pw.SizedBox(height: 8),
            _informationBox(contract.notes.trim()),
          ],
          pw.SizedBox(height: 28),
          _signatureSection(),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: '$invoiceNumber.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _pageHeader({
    required pw.MemoryImage logo,
    required String invoiceNumber,
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
                invoiceNumber,
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
            'INVOICE',
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

  pw.Widget _invoiceInformation({
    required Contract contract,
    required String invoiceNumber,
    required String invoiceDate,
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
              pw.Expanded(child: _labelValue('Invoice No.', invoiceNumber)),
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
              pw.Expanded(child: _labelValue('Invoice Date', invoiceDate)),
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

  pw.Widget _amountSummary(Contract contract) {
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
          _moneyLine('Contract Value', contract.value),
          _moneyLine('Total Paid', contract.totalPaid),
          pw.Divider(color: PdfColors.green800, thickness: 1),
          _moneyLine(
            'BALANCE DUE',
            contract.balance,
            bold: true,
            highlight: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _paymentsTable(Contract contract, DateFormat dateFormat) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Date', 'Method', 'Reference', 'Amount'],
      data: contract.payments.map((payment) {
        return [
          dateFormat.format(payment.paidAt),
          payment.method.label,
          payment.reference.trim().isEmpty ? '-' : payment.reference.trim(),
          formatUgx(payment.amount),
        ];
      }).toList(),
      headerStyle: const pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.green800,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellPadding: const pw.EdgeInsets.all(6),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.7),
        3: pw.FlexColumnWidth(1.4),
      },
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
        isPaid ? 'PAYMENT STATUS: FULLY PAID' : 'PAYMENT STATUS: BALANCE DUE',
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
        pw.Expanded(child: _signatureBox('Prepared By')),
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
