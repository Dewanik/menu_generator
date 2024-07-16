import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'file_operations.dart';

class FileOperationsWeb implements FileOperations {
  @override
  Future<Uint8List> pickImage() async {
    final completer = Completer<Uint8List>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.onChange.listen((e) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(input.files!.first);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as Uint8List);
      });
    });
    input.click();
    return completer.future;
  }
}

FileOperations getFileOperations() => FileOperationsWeb();
