import 'package:flutter/services.dart';
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

    final filteredContracts = startDate == null || endDate == null
        ? contracts
        : contracts.where((contract) {
            final date = contract.createdAt;
            return !date.isBefore(startDate) &&
                !date.isAfter(endDate.add(const Duration(days: 1)));
          }).toList();

    final activeProjects = filteredContracts
        .where((contract) => contract.status != ContractStatus.completed)
        .length;

    final completedProjects = filteredContracts
        .where((contract) => contract.status == ContractStatus.completed)
        .length;

    final paidAmount = filteredContracts.fold<double>(
      0,
      (sum, contract) => sum + contract.totalPaid,
    );

    final outstandingAmount = filteredContracts.fold<double>(
      0,
      (sum, contract) => sum + contract.balance,
    );

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
            title,
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text('Generated: ${DateTime.now().toString().split(' ').first}'),
          if (startDate != null && endDate != null)
            pw.Text(
              'Period: ${startDate.toString().split(' ').first} to ${endDate.toString().split(' ').first}',
            ),
          pw.SizedBox(height: 20),
          _sectionTitle('Operations'),
          _line('Clients', clients.toString()),
          _line('Quotations', quotations.toString()),
          _line('Pending Quotations', pendingQuotations.toString()),
          _line('Approved Quotations', approvedQuotations.toString()),
          _line('Active Projects', activeProjects.toString()),
          _line('Completed Projects', completedProjects.toString()),
          pw.SizedBox(height: 16),
          _sectionTitle('Financial Summary'),
          _moneyLine('Quotation Value', quotationValue),
          _moneyLine('Contract Value', contractValue),
          _moneyLine('Paid Amount', paidAmount),
          _moneyLine('Outstanding Balance', outstandingAmount, bold: true),
          pw.SizedBox(height: 20),
          _sectionTitle('Contracts Summary'),
          if (filteredContracts.isEmpty)
            pw.Text('No contracts available for this report.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Contract',
                'Client',
                'Status',
                'Value',
                'Paid',
                'Balance'
              ],
              data: filteredContracts.map((contract) {
                return [
                  contract.number,
                  contract.clientName,
                  contract.status.label,
                  formatUgx(contract.value),
                  formatUgx(contract.totalPaid),
                  formatUgx(contract.balance),
                ];
              }).toList(),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
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
