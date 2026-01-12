import 'pick_file_stub.dart'
    if (dart.library.html) 'pick_file_web.dart';

class PickedFileData {
  final List<int> bytes;
  final String filename;
  PickedFileData(this.bytes, this.filename);
}

Future<PickedFileData?> pickFileBytes() => pickFileBytesImpl();
