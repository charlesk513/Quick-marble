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
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <Quotation>[]);

  final officeId = user.isAdministrator ? null : user.assignedOfficeId;
  if (!user.isAdministrator && (officeId == null || officeId.trim().isEmpty)) {
    return Stream.value(const <Quotation>[]);
  }

  return ref
      .watch(quotationServiceProvider)
      .watchQuotations(officeId: officeId);
});

final visibleQuotationsProvider = Provider<List<Quotation>>((ref) {
  return ref.watch(quotationsStreamProvider).valueOrNull ?? const <Quotation>[];
});

class QuotationController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final QuotationService _service;

  QuotationController(this._ref, this._service)
      : super(const AsyncValue.data(null));

  Quotation? _findQuotation(String id) {
    final quotations =
        _ref.read(quotationsStreamProvider).valueOrNull ?? const <Quotation>[];
    for (final quotation in quotations) {
      if (quotation.id == id) return quotation;
    }
    return null;
  }

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
        officeId: quotation.officeId,
        action: ActivityAction.created,
        entityType: 'Quotation',
        entityLabel: quotation.number,
        message:
            'Created quotation ${quotation.number} for ${quotation.clientName}.',
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
        message:
            'Updated quotation ${quotation.number} for ${quotation.clientName}.',
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, QuotationStatus status) async {
    state = const AsyncValue.loading();
    try {
      final quotation = _findQuotation(id);
      if (quotation == null) throw StateError('Quotation not found.');

      await _service.updateStatus(id, status);

      final action = switch (status) {
        QuotationStatus.draft => ActivityAction.updated,
        QuotationStatus.pendingApproval => ActivityAction.submitted,
        QuotationStatus.approved => ActivityAction.approved,
        QuotationStatus.rejected => ActivityAction.rejected,
      };

      final message = switch (status) {
        QuotationStatus.draft =>
          'Quotation ${quotation.number} returned to draft.',
        QuotationStatus.pendingApproval =>
          'Quotation ${quotation.number} submitted for approval.',
        QuotationStatus.approved =>
          'Quotation ${quotation.number} approved for ${quotation.clientName}.',
        QuotationStatus.rejected =>
          'Quotation ${quotation.number} rejected for ${quotation.clientName}.',
      };

      await _addLog(
        officeId: quotation.officeId,
        action: action,
        entityType: 'Quotation',
        entityLabel: quotation.number,
        message: message,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
    try {
      await _ref.read(activityLogServiceProvider).addLog(
            officeId: officeId,
            actorName: user?.name ?? 'System',
            action: action,
            entityType: entityType,
            entityLabel: entityLabel,
            message: message,
          );
    } catch (_) {
      // Logging must not make the main quotation action fail.
    }
  }
}

final quotationControllerProvider =
    StateNotifierProvider<QuotationController, AsyncValue<void>>((ref) {
  return QuotationController(ref, ref.watch(quotationServiceProvider));
});
