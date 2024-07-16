import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'file_operations.dart';

class FileOperationsNonWeb implements FileOperations {
  @override
  Future<Uint8List> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path).readAsBytes();
    }
    throw Exception('No image selected');
  }
}

FileOperations getFileOperations() => FileOperationsNonWeb();
