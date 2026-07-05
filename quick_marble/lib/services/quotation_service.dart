import '../models/quotation.dart';

abstract class QuotationService {
  Stream<List<Quotation>> watchQuotations();
  Future<Quotation> createQuotation({
    required String officeId,
    required String clientId,
    required String clientName,
    required List<QuotationItem> items,
    required String notes,
  });
  Future<void> updateQuotation(Quotation quotation);
  Future<void> updateStatus(String quotationId, QuotationStatus status);
}
