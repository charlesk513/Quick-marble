class CompanySettings {
  final bool vatEnabled;
  final double vatRate;

  const CompanySettings({
    required this.vatEnabled,
    required this.vatRate,
  });

  CompanySettings copyWith({
    bool? vatEnabled,
    double? vatRate,
  }) {
    return CompanySettings(
      vatEnabled: vatEnabled ?? this.vatEnabled,
      vatRate: vatRate ?? this.vatRate,
    );
  }
}
