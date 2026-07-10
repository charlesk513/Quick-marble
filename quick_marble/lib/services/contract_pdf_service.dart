import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    final dateFormat = DateFormat('dd MMM yyyy');

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
          contractNumber: contract.number,
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
          _contractInformation(
            contract: contract,
            startDate: dateFormat.format(contract.startDate),
            completionDate: contract.completionDate == null
                ? null
                : dateFormat.format(contract.completionDate!),
          ),
          pw.SizedBox(height: 18),
          _sectionHeading('FINANCIAL SUMMARY'),
          pw.SizedBox(height: 8),
          _financialSummary(contract),
          if (contract.payments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeading('PAYMENT HISTORY'),
            pw.SizedBox(height: 8),
            _paymentsTable(contract, dateFormat),
          ],
          if (contract.documentName.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeading('DOCUMENT REFERENCE'),
            pw.SizedBox(height: 8),
            _informationBox(contract.documentName.trim()),
          ],
          if (contract.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionHeading('NOTES / SPECIAL INSTRUCTIONS'),
            pw.SizedBox(height: 8),
            _informationBox(contract.notes.trim()),
          ],
          pw.SizedBox(height: 22),
          _termsSection(),
          pw.SizedBox(height: 26),
          _signatureSection(),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: '${contract.number}.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _pageHeader({
    required pw.MemoryImage logo,
    required String contractNumber,
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
                contractNumber,
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
            'CONTRACT AGREEMENT',
            style: const pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1,
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

  pw.Widget _contractInformation({
    required Contract contract,
    required String startDate,
    required String? completionDate,
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
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _labelValue('Client', contract.clientName)),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _labelValue('Status', contract.status.label)),
            ],
          ),
          pw.SizedBox(height: 9),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
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
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _labelValue('Start Date', startDate)),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _labelValue(
                  'Completion Date',
                  completionDate ?? 'Not completed',
                ),
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

  pw.Widget _financialSummary(Contract contract) {
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
          _pdfMoneyLine('Contract Value', contract.value),
          _pdfMoneyLine('Amount Paid', contract.totalPaid),
          pw.Divider(color: PdfColors.green800, thickness: 1),
          _pdfMoneyLine(
            'OUTSTANDING BALANCE',
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

  pw.Widget _termsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeading('AGREEMENT TERMS'),
        pw.SizedBox(height: 8),
        _bullet(
          'Quick Marble & Granite shall supply and/or install the agreed items according to the approved quotation referenced in this contract.',
        ),
        _bullet(
          'The client shall provide access to the site and ensure that the work area is ready on the agreed installation date.',
        ),
        _bullet(
          'Payments shall follow the agreed schedule. Work may be paused where agreed payments are overdue.',
        ),
        _bullet(
          'Any change in measurements, materials or scope must be approved and may affect the final contract value.',
        ),
        _bullet(
          'Client-supplied materials remain the client’s responsibility unless otherwise stated in the approved quotation.',
        ),
        _bullet(
          'Completion dates may change where site conditions, client instructions or material availability cause delays.',
        ),
        _bullet(
          'Signing this contract confirms acceptance of the referenced quotation, payment terms and project conditions.',
        ),
      ],
    );
  }

  pw.Widget _bullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: const pw.TextStyle(fontSize: 9.5)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(
                fontSize: 9,
                lineSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _signatureSection() {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(child: _signatureBox('Client Name & Signature')),
            pw.SizedBox(width: 18),
            pw.Expanded(child: _signatureBox('Company Representative')),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Expanded(child: _signatureBox('Company Stamp')),
            pw.SizedBox(width: 18),
            pw.Expanded(child: _signatureBox('Date')),
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

  pw.Widget _pdfMoneyLine(
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
