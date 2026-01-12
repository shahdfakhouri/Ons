// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

import 'pick_file.dart';

Future<PickedFileData?> pickFileBytesImpl() async {
  final input = html.FileUploadInputElement()..accept = 'image/*,video/*';
  input.click();

  final completer = Completer<PickedFileData?>();
  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    reader.onLoadEnd.listen((_) {
      final data = reader.result as ByteBuffer?;
      if (data == null) {
        completer.complete(null);
        return;
      }
      final bytes = Uint8List.view(data).toList();
      completer.complete(PickedFileData(bytes, file.name));
    });
  });

  return completer.future;
}
