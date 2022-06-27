import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/vm/timereditvm.dart';

import '../testutil.dart';

Future<int> dbsetup(DbAccess db) async {
  final title = TitleTable(sTitle: "Hoge");
  await db.updateTitle(title);
  final times = List<TimeTable>.generate(
      20,
      (i) => TimeTable.fromTitleTable(
          title: title, iTime: 10 * (i + 1) + i + 1, iNo: i));
  await db.updateTimes(times, <int>[]);
  return title.id;
}

void main() {
  sqfliteFfiInit();
  int counter = 70;

  late DbAccess db;
  late int titleid;
  setUp(() async {
    final dbName = "test${counter++}.db";
    await removeDbFile(dbName);
    db = await DbAccess.create(dbName);
    titleid = await dbsetup(db);
    Get.put<DbAccess>(db);
  });
  tearDown(Get.reset);

  test("loader", () async {
    final top = TimerEditVM(titleid);
    await top.loader();
    expect(top.isNotLoadDb, false);
    expect(top.title, "Hoge");
    expect(top.removeRecord.isEmpty, true);
    expect(top.times.length, 20);
    int sum = 0;
    for (int i = 0; i < top.times.length; i++) {
      expect(top.times[i].timer.titleid, titleid);
      expect(top.times[i].timer.iTime, 10 * (i + 1) + (i + 1));
      sum += top.times[i].timer.iTime;
    }
    expect(top.total, "Total : ${TimeTable.formatter(sum)}");
  });
}
