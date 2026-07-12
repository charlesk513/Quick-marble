class CompanySettings {
  final bool vatEnabled;
  final double vatRate;

  const CompanySettings({
    required this.vatEnabled,
    required this.vatRate,
  });

  static const defaults = CompanySettings(
    vatEnabled: true,
    vatRate: 0.18,
  );

  CompanySettings copyWith({
    bool? vatEnabled,
    double? vatRate,
  }) {
    return CompanySettings(
      vatEnabled: vatEnabled ?? this.vatEnabled,
      vatRate: vatRate ?? this.vatRate,
    );
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    final rawRate = (map['vatRate'] as num?)?.toDouble() ?? 0.18;

    return CompanySettings(
      vatEnabled: map['vatEnabled'] as bool? ?? true,
      vatRate: rawRate.clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vatEnabled': vatEnabled,
      'vatRate': vatRate,
    };
  }
}
