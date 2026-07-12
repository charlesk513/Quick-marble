import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadedContractDocument {
  final String name;
  final String downloadUrl;
  final String storagePath;

  const UploadedContractDocument({
    required this.name,
    required this.downloadUrl,
    required this.storagePath,
  });
}

class ContractStorageService {
  final FirebaseStorage _storage;

  ContractStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<UploadedContractDocument?> pickAndUpload({
    required String contractId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception('Could not read the selected file.');
    }

    final safeName = file.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final storagePath =
        'contracts/$contractId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final reference = _storage.ref().child(storagePath);

    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: _contentType(file.extension),
        customMetadata: {
          'contractId': contractId,
          'originalName': file.name,
        },
      ),
    );

    final downloadUrl = await reference.getDownloadURL();

    return UploadedContractDocument(
      name: file.name,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }

  String _contentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> deleteByPath(String storagePath) async {
    if (storagePath.trim().isEmpty) return;

    try {
      await _storage.ref().child(storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}
