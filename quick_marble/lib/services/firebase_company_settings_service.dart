import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/company_settings.dart';

class FirebaseCompanySettingsService {
  final FirebaseFirestore _firestore;

  FirebaseCompanySettingsService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore.collection('settings').doc('company');

  Stream<CompanySettings> watchSettings() {
    return _document.snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return CompanySettings.defaults;
      }

      return CompanySettings.fromMap(data);
    });
  }

  Future<void> saveSettings(CompanySettings settings) async {
    await _document.set(
      {
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
