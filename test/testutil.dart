import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> removeDbFile(String dbName) async {
  final file = File(join(await databaseFactoryFfi.getDatabasesPath(), dbName));
  if (await file.exists()) {
    await file.delete();
  }
}
