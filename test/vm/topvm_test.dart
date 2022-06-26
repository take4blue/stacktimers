import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/topvm.dart';

import '../mockviewcontrol.dart';
import '../testutil.dart';

Future<void> dbsetup(DbAccess db) async {
  for (int i = 0; i < 5; i++) {
    final title = TitleTable(sTitle: "Hoge ${i + 1}");
    await db.updateTitle(title);
    final times = <TimeTable>[];
    for (int j = 0; j <= 7; j++) {
      times.add(TimeTable.fromTitleTable(
          title: title, iTime: (i + 10) * (j + 1), iNo: j));
    }
    await db.updateTimes(times, <int>[]);
  }
}

void main() {
  sqfliteFfiInit();
  int counter = 40;

  late DbAccess db;
  setUp(() async {
    final dbName = "test${counter++}.db";
    await removeDbFile(dbName);
    db = await DbAccess.create(dbName);
    await dbsetup(db);
    Get.put<DbAccess>(db);
  });
  tearDown(Get.reset);

  test("titlelist", () async {
    final title = await db.getTitle(2);
    final target = TitleList(title);
    expect(target.id, title.id);
    expect(target.sTitle, title.sTitle);
    expect(await target.time(), "06:36");
  });

  test("loader", () async {
    final top = TopVM();
    await top.loader();
    expect(top.isNotLoadDb, false);
    expect(top.titles.length, 5);
    for (int i = 0; i < 5; i++) {
      expect(top.titles[i].sTitle, "Hoge ${i + 1}");
    }
  });

  test("addTitle", () async {
    bool updated = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TopVM();
    top.addListenerId("all", () {
      updated = true;
    });
    await top.loader();
    await top.addTitle();
    expect(top.titles.length, 6);
    expect(top.isNotLoadDb, true);
    expect(view.func, "toEdit 6");
    final title = await db.getTitle(6);
    expect(title.sTitle.isEmpty, true);
    final times = await db.getTimes(6);
    expect(times.length, 1);
    expect(times[0].iNo, 0);
    expect(times[0].iTime, 0);
    expect(updated, true);
  });
  test("startTimer", () async {
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TopVM();
    await top.loader();
    await top.startTimer(1);
    expect(top.titles.length, 5);
    expect(top.isNotLoadDb, false);
    expect(view.func, "toControl 2");
  });
  test("editTimer", () async {
    bool updated = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TopVM();
    top.addListenerId("2", () {
      updated = true;
    });
    await top.loader();
    await top.editTimer(2);
    expect(view.func, "toEdit 3");
    expect(updated, true);
  });
  test("deleteTitle", () async {
    bool updated = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TopVM();
    top.addListenerId("all", () {
      updated = true;
    });
    await top.loader();
    await top.deleteTitle(2);
    expect(top.isNotLoadDb, true);
    expect(updated, true);
    final title =
        await db.db.query(DbAccess.titleTable, where: 'id = ?', whereArgs: [3]);
    expect(title.isEmpty, true);
  });
}
