import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_settings.dart';

final companySettingsProvider =
    StateNotifierProvider<CompanySettingsController, CompanySettings>((ref) {
  return CompanySettingsController();
});

class CompanySettingsController extends StateNotifier<CompanySettings> {
  CompanySettingsController()
      : super(
          const CompanySettings(
            vatEnabled: true,
            vatRate: 0.18,
          ),
        );

  void setVatEnabled(bool value) {
    state = state.copyWith(vatEnabled: value);
  }

  void setVatRate(double value) {
    state = state.copyWith(vatRate: value);
  }
}
