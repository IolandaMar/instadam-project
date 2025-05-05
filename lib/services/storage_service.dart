import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> pujarImatge(File imatge, String carpeta) async {
    try {
      final String nomFitxer = const Uuid().v4();
      final Reference ref = _storage.ref().child(carpeta).child('$nomFitxer.jpg');
      final UploadTask task = ref.putFile(imatge);
      final TaskSnapshot snapshot = await task;
      final String url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error pujant imatge a Firebase Storage: $e');
      rethrow;
    }
  }
}
