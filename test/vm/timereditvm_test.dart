import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/timereditvm.dart';

import '../mockviewcontrol.dart';
import '../testutil.dart';

Future<void> dbsetup(DbAccess db) async {
  for (int i = 0; i < 5; i++) {
    final title = TitleTable(sTitle: "Hoge ${i + 1}");
    await db.updateTitle(title);
    final times = <TimeTable>[];
    for (int j = 0; j < 3; j++) {
      times.add(TimeTable.fromTitleTable(
          title: title, iTime: (i + 10) * (j + 1), iNo: j));
    }
    await db.updateTimes(times, <int>[]);
  }
}

void main() {
  sqfliteFfiInit();
  int counter = 60;

  late DbAccess db;
  setUp(() async {
    final dbName = "test${counter++}.db";
    await removeDbFile(dbName);
    db = await DbAccess.create(dbName);
    await dbsetup(db);
    Get.put<DbAccess>(db);
  });
  tearDown(Get.reset);

  test("timerlist", () async {
    final target = EditItem(TimeTable(iTime: 100, titleid: 1, iDuration: 1500));
    expect(target.timer.id, -1);
    expect(target.timer.titleid, 1);
    expect(target.time, "01:40");
    expect(target.duration, "1.5");
  });

  test("loader", () async {
    final top = TimerEditVM(3);
    await top.loader();
    expect(top.isNotLoadDb, false);
    expect(top.title, "Hoge 3");
    expect(top.removeRecord.isEmpty, true);
    expect(top.times.length, 3);
    int sum = 0;
    for (int i = 0; i < top.times.length; i++) {
      expect(top.times[i].timer.titleid, 3);
      expect(top.times[i].timer.iTime, 12 * (i + 1));
      sum += 12 * (i + 1);
    }
    expect(top.total, "Total : ${TimeTable.formatter(sum)}");
  });

  test("addTimer", () async {
    bool updated = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TimerEditVM(3);
    top.addListenerId("all", () {
      updated = true;
    });
    await top.loader();
    await top.addTimer();
    expect(top.times.length, 4);
    expect(top.times[3].timer.id, -1);
    expect(top.times[3].timer.titleid, 3);
    expect(top.times[3].timer.iDuration, 500);
    expect(top.times[3].timer.iNo, 3);
    expect(top.times[3].timer.iTime, 0);
    expect(top.isNotLoadDb, false);
    expect(updated, true);
  });
  test("changeTitle", () async {
    final top = TimerEditVM(2);
    await top.loader();
    await top.changeTitle("hoge");
    expect(top.title, "hoge");
  });
  test("deleteTime", () async {
    bool updated = false;
    final top = TimerEditVM(2);
    top.addListenerId("all", () {
      updated = true;
    });
    await top.loader();
    final removeId = top.times[1].timer.id;
    await top.deleteTime(1);
    expect(top.times.length, 2);
    expect(top.times[0].timer.iNo, 0);
    expect(top.times[1].timer.iNo, 2);
    expect(top.removeRecord.length, 1);
    expect(top.removeRecord[0], removeId);
    expect(updated, true);
  });
  test("editTime", () async {
    bool updated1 = false;
    bool updated2 = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TimerEditVM(2);
    top.addListenerId("total", () {
      updated1 = true;
    });
    top.addListenerId("2", () {
      updated2 = true;
    });
    await top.loader();
    final prevTime = top.times[2].timer.iTime;
    await top.editTime(2);
    expect(top.isNotLoadDb, false);
    expect(updated1, true);
    expect(updated2, true);
    expect(view.func, "getTime $prevTime");
    expect(top.times[2].timer.iTime, prevTime + 1);
  });

  test("editColor", () async {
    bool updated2 = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TimerEditVM(2);
    top.addListenerId("2", () {
      updated2 = true;
    });
    await top.loader();
    final prevColor = top.times[2].timer.iColor;
    await top.editColor(2);
    expect(top.isNotLoadDb, false);
    expect(updated2, true);
    expect(view.func, "getColor $prevColor");
    expect(top.times[2].timer.iColor, Colors.blue);
  });
  test("editDuration", () async {
    bool updated2 = false;
    final view = MockViewControl();
    Get.put<ViewControl>(view);
    final top = TimerEditVM(2);
    top.addListenerId("2", () {
      updated2 = true;
    });
    await top.loader();
    final prevDuration = top.times[2].timer.iDuration;
    await top.editDuration(2);
    expect(top.isNotLoadDb, false);
    expect(updated2, true);
    expect(view.func, "getDuration $prevDuration");
    expect(top.times[2].timer.iDuration, prevDuration + 1);
  });

  test("updateDb", () async {
    final top = TimerEditVM(3);
    await top.loader();
    await top.deleteTime(1);
    await top.addTimer();
    top.times.last.timer.iTime = 111;
    top.title = "hage";
    top.reorder(1, 0);
    final timeList = List.generate(
        top.times.length, (index) => top.times[index].timer.iTime);
    final result = await top.updateDb();
    expect(result, true);
    final titleTbl = await db.getTitle(3);
    expect(titleTbl.sTitle, "hage");
    final timesTbl = await db.getTimes(3);
    expect(timesTbl.length, timeList.length);
    for (int i = 0; i < timesTbl.length; i++) {
      expect(timesTbl[i].iTime, timeList[i]);
    }
  });
}
