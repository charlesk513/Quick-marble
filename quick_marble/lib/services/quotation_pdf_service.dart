import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/quotation.dart';
import '../screens/shared/money_text.dart';

class QuotationPdfService {
  Future<void> printQuotation({
    required Quotation quotation,
    required bool vatEnabled,
    required double vatRate,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/logo.jpg');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final subtotal = quotation.subtotal;
    final vat = vatEnabled ? subtotal * vatRate : 0.0;
    final total = subtotal + vat;

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
        build: (context) {
          return [
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
            pw.SizedBox(height: 20),
            pw.Text(
              'QUOTATION',
              style: const pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Quotation No: ${quotation.number}'),
            pw.Text('Client: ${quotation.clientName}'),
            pw.Text('Date: ${quotation.createdAt.toString().split(' ').first}'),
            pw.SizedBox(height: 20),
            ...quotation.items.map(_itemBlock),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 240,
                child: pw.Column(
                  children: [
                    _pdfMoneyLine('Subtotal', subtotal),
                    if (vatEnabled)
                      _pdfMoneyLine(
                        'VAT ${(vatRate * 100).toStringAsFixed(0)}%',
                        vat,
                      ),
                    pw.Divider(),
                    _pdfMoneyLine('Grand Total', total, bold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Prepared by Quick Marble & Granite'),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Client Signature: __________________'),
                pw.Text('Company Stamp: __________________'),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _itemBlock(QuotationItem item) {
    if (item.type == QuotationItemType.material) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              item.materialName ?? item.description,
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Width: ${item.widthCm?.toStringAsFixed(0) ?? '-'}cm · '
              'Length: ${item.lengthCm?.toStringAsFixed(0) ?? '-'}cm',
            ),
            pw.Text('Mode: ${item.fixingMode.label}'),
            pw.SizedBox(height: 8),
            _pdfMoneyLine('Material pieces', item.materialAmount),
            if (item.mainLabourAmount > 0)
              _pdfMoneyLine('Main fixing labour', item.mainLabourAmount),
            if (item.hasSkirting) ...[
              _pdfMoneyLine('Skirting pieces', item.skirtingAmount),
              if (item.skirtingLabourAmount > 0)
                _pdfMoneyLine(
                    'Skirting fixing labour', item.skirtingLabourAmount),
            ],
            if (item.chargeableFixingMaterialsAmount > 0)
              _pdfMoneyLine(
                'Fixing materials charge',
                item.chargeableFixingMaterialsAmount,
              ),
            if (item.transportAmount > 0)
              _pdfMoneyLine('Transport / delivery', item.transportAmount),
            pw.Divider(),
            _pdfMoneyLine('Item subtotal', item.subtotal, bold: true),
            if (item.fixingMode == FixingMode.supplyAndFix &&
                item.fixingPlaceType != null) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                'Required fixing materials: ${item.fixingPlaceType!.requiredMaterials}.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                item.fixingMaterialPayment.label,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.description,
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          _pdfMoneyLine(
            '${item.quantity.toStringAsFixed(2)} × ${formatUgx(item.unitPrice)}',
            item.subtotal,
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMoneyLine(String label, double amount, {bool bold = false}) {
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
