import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quotation.dart';
import '../providers/auth_provider.dart';
import '../services/mock_quotation_service.dart';
import '../services/quotation_service.dart';

final quotationServiceProvider = Provider<QuotationService>((ref) {
  return MockQuotationService();
});

final quotationsStreamProvider = StreamProvider<List<Quotation>>((ref) {
  return ref.watch(quotationServiceProvider).watchQuotations();
});

final visibleQuotationsProvider = Provider<List<Quotation>>((ref) {
  final user = ref.watch(currentUserProvider);
  final quotations = ref.watch(quotationsStreamProvider).valueOrNull ?? [];
  if (user == null) return [];
  if (user.isAdministrator) return quotations;
  return quotations.where((q) => q.officeId == user.assignedOfficeId).toList();
});

class QuotationController extends StateNotifier<AsyncValue<void>> {
  final QuotationService _service;
  QuotationController(this._service) : super(const AsyncValue.data(null));

  Future<void> createQuotation({
    required String officeId,
    required String clientId,
    required String clientName,
    required List<QuotationItem> items,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createQuotation(
        officeId: officeId,
        clientId: clientId,
        clientName: clientName,
        items: items,
        notes: notes,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateQuotation(Quotation quotation) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateQuotation(quotation);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, QuotationStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final quotationControllerProvider =
    StateNotifierProvider<QuotationController, AsyncValue<void>>((ref) {
  return QuotationController(ref.watch(quotationServiceProvider));
});
