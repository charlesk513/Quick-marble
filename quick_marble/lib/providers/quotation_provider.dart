import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/quotation.dart';
import '../providers/activity_log_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_quotation_service.dart';
import '../services/quotation_service.dart';

final quotationServiceProvider = Provider<QuotationService>((ref) {
  return FirebaseQuotationService();
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
  final Ref _ref;
  final QuotationService _service;

  QuotationController(this._ref, this._service)
      : super(const AsyncValue.data(null));

  Future<void> createQuotation({
    required String officeId,
    required String clientId,
    required String clientName,
    required List<QuotationItem> items,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final quotation = await _service.createQuotation(
        officeId: officeId,
        clientId: clientId,
        clientName: clientName,
        items: items,
        notes: notes,
      );

      await _addLog(
        officeId: officeId,
        action: ActivityAction.created,
        entityType: 'Quotation',
        entityLabel: quotation.number,
        message: 'Created quotation for $clientName.',
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

      await _addLog(
        officeId: quotation.officeId,
        action: ActivityAction.updated,
        entityType: 'Quotation',
        entityLabel: quotation.number,
        message: 'Updated quotation for ${quotation.clientName}.',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, QuotationStatus status) async {
    state = const AsyncValue.loading();
    try {
      final quotations =
          _ref.read(quotationsStreamProvider).valueOrNull ?? <Quotation>[];

      final quotation = quotations.firstWhere((quote) => quote.id == id);

      await _service.updateStatus(id, status);

      final action = switch (status) {
        QuotationStatus.draft => ActivityAction.updated,
        QuotationStatus.pendingApproval => ActivityAction.submitted,
        QuotationStatus.approved => ActivityAction.approved,
        QuotationStatus.rejected => ActivityAction.rejected,
      };

      await _addLog(
        officeId: quotation.officeId,
        action: action,
        entityType: 'Quotation',
        entityLabel: quotation.number,
        message: '${action.label} quotation for ${quotation.clientName}.',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> _addLog({
    required String officeId,
    required ActivityAction action,
    required String entityType,
    required String entityLabel,
    required String message,
  }) async {
    final user = _ref.read(currentUserProvider);

    await _ref.read(activityLogServiceProvider).addLog(
          officeId: officeId,
          actorName: user?.name ?? 'System',
          action: action,
          entityType: entityType,
          entityLabel: entityLabel,
          message: message,
        );
  }
}

final quotationControllerProvider =
    StateNotifierProvider<QuotationController, AsyncValue<void>>((ref) {
  return QuotationController(ref, ref.watch(quotationServiceProvider));
});
