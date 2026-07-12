import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_settings.dart';
import '../services/firebase_company_settings_service.dart';

final companySettingsServiceProvider =
    Provider<FirebaseCompanySettingsService>((ref) {
  return FirebaseCompanySettingsService();
});

final companySettingsStreamProvider = StreamProvider<CompanySettings>((ref) {
  return ref.watch(companySettingsServiceProvider).watchSettings();
});

final companySettingsProvider = Provider<CompanySettings>((ref) {
  return ref.watch(companySettingsStreamProvider).valueOrNull ??
      CompanySettings.defaults;
});

class CompanySettingsController extends StateNotifier<AsyncValue<void>> {
  final FirebaseCompanySettingsService _service;

  CompanySettingsController(this._service) : super(const AsyncValue.data(null));

  Future<void> save(CompanySettings settings) async {
    state = const AsyncValue.loading();

    try {
      await _service.saveSettings(settings);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setVatEnabled(
    CompanySettings current,
    bool value,
  ) {
    return save(current.copyWith(vatEnabled: value));
  }

  Future<void> setVatRate(
    CompanySettings current,
    double value,
  ) {
    return save(
      current.copyWith(
        vatRate: value.clamp(0.0, 1.0),
      ),
    );
  }
}

final companySettingsControllerProvider =
    StateNotifierProvider<CompanySettingsController, AsyncValue<void>>((ref) {
  return CompanySettingsController(
    ref.watch(companySettingsServiceProvider),
  );
});
