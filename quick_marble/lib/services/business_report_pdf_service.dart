import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contract.dart';
import '../screens/shared/money_text.dart';

class BusinessReportPdfService {
  Future<void> printReport({
    required String title,
    required int clients,
    required int quotations,
    required int pendingQuotations,
    required int approvedQuotations,
    required List<Contract> contracts,
    required double quotationValue,
    required double contractValue,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/logo.jpg');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final dateFormat = DateFormat('dd MMM yyyy');
    final generatedAt = DateTime.now();

    final filteredContracts = startDate == null || endDate == null
        ? [...contracts]
        : contracts.where((contract) {
            final start = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            );
            final endExclusive = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            ).add(const Duration(days: 1));

            return !contract.createdAt.isBefore(start) &&
                contract.createdAt.isBefore(endExclusive);
          }).toList();

    filteredContracts.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    final activeProjects = filteredContracts
        .where(
          (contract) =>
              contract.status != ContractStatus.completed &&
              contract.status != ContractStatus.cancelled,
        )
        .length;

    final completedProjects = filteredContracts
        .where((contract) => contract.status == ContractStatus.completed)
        .length;

    final cancelledProjects = filteredContracts
        .where((contract) => contract.status == ContractStatus.cancelled)
        .length;

    final paidAmount = filteredContracts.fold<double>(
      0,
      (sum, contract) => sum + contract.totalPaid,
    );

    final outstandingAmount = filteredContracts.fold<double>(
      0,
      (sum, contract) => sum + contract.balance,
    );

    final filteredContractValue = filteredContracts.fold<double>(
      0,
      (sum, contract) => sum + contract.value,
    );

    final collectionRate = filteredContractValue <= 0
        ? 0.0
        : (paidAmount / filteredContractValue) * 100;

    final reportPeriod = startDate != null && endDate != null
        ? '${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}'
        : 'Current business position';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 34),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.05,
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
          reportTitle: title,
          currentPage: context.pageNumber,
          totalPages: context.pagesCount,
        ),
        footer: (context) => _pageFooter(
          generatedAt: generatedAt,
          currentPage: context.pageNumber,
          totalPages: context.pagesCount,
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _documentTitle(title),
          pw.SizedBox(height: 16),
          _reportInformation(
            generatedDate: dateFormat.format(generatedAt),
            period: reportPeriod,
            contractCount: filteredContracts.length,
          ),
          pw.SizedBox(height: 20),
          _sectionHeading('OPERATIONS SUMMARY'),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metricCard('Clients', clients.toString()),
              _metricCard('Quotations', quotations.toString()),
              _metricCard(
                'Pending Quotations',
                pendingQuotations.toString(),
              ),
              _metricCard(
                'Approved Quotations',
                approvedQuotations.toString(),
              ),
              _metricCard('Active Projects', activeProjects.toString()),
              _metricCard(
                'Completed Projects',
                completedProjects.toString(),
              ),
              _metricCard(
                'Cancelled Projects',
                cancelledProjects.toString(),
              ),
              _metricCard(
                'Contracts in Report',
                filteredContracts.length.toString(),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          _sectionHeading('FINANCIAL SUMMARY'),
          pw.SizedBox(height: 8),
          _financialSummary(
            quotationValue: quotationValue,
            contractValue: contractValue,
            filteredContractValue: filteredContractValue,
            paidAmount: paidAmount,
            outstandingAmount: outstandingAmount,
            collectionRate: collectionRate,
          ),
          pw.SizedBox(height: 20),
          _sectionHeading('CONTRACTS SUMMARY'),
          pw.SizedBox(height: 8),
          if (filteredContracts.isEmpty)
            _emptyState('No contracts are available for this report.')
          else
            _contractsTable(filteredContracts, dateFormat),
          pw.SizedBox(height: 20),
          _sectionHeading('REPORT NOTES'),
          pw.SizedBox(height: 8),
          _informationBox(
            startDate == null || endDate == null
                ? 'This report is a snapshot of the current business position. '
                    'Financial totals are calculated from the contracts currently available in the system.'
                : 'This report covers contracts created during the selected period. '
                    'Client and quotation counts are the summary values supplied by the application for this report.',
          ),
          pw.SizedBox(height: 24),
          _signatureSection(),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: '${_safeFileName(title)}.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return cleaned.isEmpty ? 'business_report' : cleaned;
  }

  pw.Widget _pageHeader({
    required pw.MemoryImage logo,
    required String reportTitle,
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
                reportTitle,
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(
                  fontSize: 9,
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
    required DateTime generatedAt,
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
            'Generated ${DateFormat('dd MMM yyyy HH:mm').format(generatedAt)}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
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

  pw.Widget _documentTitle(String title) {
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
            title.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
        pw.Text(
          'Business performance report',
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _reportInformation({
    required String generatedDate,
    required String period,
    required int contractCount,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: _labelValue('Generated', generatedDate)),
          pw.SizedBox(width: 18),
          pw.Expanded(child: _labelValue('Report Period', period)),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: _labelValue('Contracts Included', '$contractCount'),
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
            fontSize: 10,
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

  pw.Widget _metricCard(String label, String value) {
    return pw.Container(
      width: 122,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _financialSummary({
    required double quotationValue,
    required double contractValue,
    required double filteredContractValue,
    required double paidAmount,
    required double outstandingAmount,
    required double collectionRate,
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
          _moneyLine('Quotation Value', quotationValue),
          _moneyLine('All Contract Value', contractValue),
          _moneyLine('Contract Value in Report', filteredContractValue),
          _moneyLine('Paid Amount', paidAmount),
          pw.Divider(color: PdfColors.green800, thickness: 1),
          _moneyLine(
            'OUTSTANDING BALANCE',
            outstandingAmount,
            bold: true,
            highlight: true,
          ),
          pw.SizedBox(height: 5),
          _textLine(
            'Collection Rate',
            '${collectionRate.toStringAsFixed(1)}%',
            bold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _contractsTable(
    List<Contract> contracts,
    DateFormat dateFormat,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Date',
        'Contract',
        'Client',
        'Status',
        'Value',
        'Paid',
        'Balance',
      ],
      data: contracts.map((contract) {
        return [
          dateFormat.format(contract.createdAt),
          contract.number,
          contract.clientName,
          contract.status.label,
          formatUgx(contract.value),
          formatUgx(contract.totalPaid),
          formatUgx(contract.balance),
        ];
      }).toList(),
      headerStyle: const pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.green800,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.all(5),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.45),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.05),
        1: pw.FlexColumnWidth(1.35),
        2: pw.FlexColumnWidth(1.65),
        3: pw.FlexColumnWidth(1.05),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.2),
        6: pw.FlexColumnWidth(1.2),
      },
    );
  }

  pw.Widget _emptyState(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        message,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey700,
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
          fontSize: 9.5,
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
        pw.Expanded(child: _signatureBox('Approved By')),
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
          height: 30,
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

  pw.Widget _textLine(
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 9.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 12),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
