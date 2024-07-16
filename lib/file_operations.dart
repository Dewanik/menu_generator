import 'dart:typed_data';

abstract class FileOperations {
  Future<Uint8List> pickImage();
}

FileOperations getFileOperations() {
  // TODO: implement getFileOperations
  throw UnimplementedError();
}
