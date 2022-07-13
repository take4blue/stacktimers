import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/controller/backgroundtimer.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';

import '../mockviewcontrol.dart';
import '../testutil.dart';

class _Test1 extends BackgroundTimer {
  String func = "";
  @override
  void kill() {
    func = "kill";
    super.kill();
  }

  @override
  void start() {
    func = "start";
  }

  @override
  void pause() {
    func = "pause";
  }

  @override
  void next() {
    func = "next";
  }

  @override
  void prev() {
    func = "prev";
  }
}

Future<void> dbsetup(DbAccess db) async {
  int i = 0;
  for (; i < 5; i++) {
    final title = TitleTable(sTitle: "Hoge ${i + 1}");
    await db.updateTitle(title);
    final times = <TimeTable>[];
    for (int j = 0; j < 3; j++) {
      times.add(TimeTable.fromTitleTable(
          title: title, iTime: (i + 10) * (j + 1), iNo: j));
    }
    await db.updateTimes(times, <int>[]);
  }
  final title = TitleTable(sTitle: "Hoge ${i + 1}");
  await db.updateTitle(title);
  final times = <TimeTable>[
    TimeTable.fromTitleTable(title: title, iTime: 1, iDuration: 3000, iNo: 0),
    TimeTable.fromTitleTable(title: title, iTime: 2, iDuration: 500, iNo: 0),
    TimeTable.fromTitleTable(title: title, iTime: 2, iDuration: 500, iNo: 0),
  ];
  await db.updateTimes(times, <int>[]);
}

void main() {
  sqfliteFfiInit();

  int counter = 80;

  late DbAccess db;
  late _Test1 ctrl;
  late MockViewControl view;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final dbName = "test${counter++}.db";
    await removeDbFile(dbName);
    db = await DbAccess.create(dbName);
    await dbsetup(db);
    Get.put<DbAccess>(db);
    view = MockViewControl();
    Get.put<ViewControl>(view);
    ctrl = _Test1();
    await ctrl.initialize();
    Get.put<BackgroundTimer>(ctrl);
  });
  tearDown(Get.reset);

  test("ControlItem", () {
    final data =
        TimeTable(titleid: 1, iColor: Colors.white, iDuration: 500, iTime: 10);
    final target = ControlItem(data, 10);
    expect(target.startTime, 10);
    expect(target.endTime, data.iTime + 10);
    expect(target.iTime, data.iTime);
    expect(target.iColor, data.iColor);
    expect(target.iDuration, data.iDuration);
  });

  test("loader", () async {
    var updated1 = false;
    final top = TimerControlVM(3);
    top.addListener(() {
      updated1 = true;
    });
    await top.loader();
    await Future.delayed(const Duration(microseconds: 10));
    expect(await ctrl.isRunning(), true);
    expect(updated1, true);
    expect(top.currentTime, 0);
    expect(top.isRunning, true);
    expect(top.isNotLoadDb, false);
    expect(top.title, "Hoge 3");
    expect(top.times.length, 3);
    int sum = 0;
    for (int i = 0; i < top.times.length; i++) {
      expect(top.times[i].iTime, 12 * (i + 1));
      expect(top.times[i].startTime, sum);
      sum += 12 * (i + 1);
    }
    expect(top.totalTime, sum);
    expect(top.totalRemain, TimeTable.formatter(sum));
    expect(top.lapRemain, TimeTable.formatter(top.times[0].endTime));
    expect(await top.closePage(), true);
    expect(ctrl.func, "kill");
    expect(await ctrl.isRunning(), false);
  });

  test("pause", () async {
    bool updated2 = false;
    final top = TimerControlVM(3);
    await top.loader();
    top.addListenerId("icons", () {
      updated2 = true;
    });
    await top.pause();
    expect(ctrl.func, "pause");
    expect(top.isRunning, false);
    expect(updated2, true); // アイコン領域の更新指示可否
    expect(view.func, "playNotification false 1"); // 音停止
    await top.closePage();
  });

  test("start", () async {
    bool updated2 = false;
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();
    top.addListenerId("icons", () {
      updated2 = true;
    });
    await top.start();
    expect(top.isRunning, true);
    expect(updated2, true); // アイコン領域の更新指示可否
    expect(ctrl.func, "start");
    await top.closePage();
  });

  test("toggleRunnning", () async {
    // isRunningの状態で判断
    final top = TimerControlVM(3);
    await top.loader();
    expect(top.isRunning, true);
    await top.toggleRunnning();
    expect(top.isRunning, false);
    await top.toggleRunnning();
    expect(top.isRunning, true);
    await top.closePage();
  });

  test("currentTime1", () async {
    // currentTimeへの設定で現在時間、残り時間文字列が更新されているか
    bool updated1 = false;
    bool updated2 = false;
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();

    top.addListenerId("time", () {
      updated1 = true;
    });
    top.addListener(() {
      updated2 = true;
    });

    top.currentTime = 5;
    expect(updated1, true);
    expect(updated2, true);
    expect(top.lapRemain, "00:07");
    expect(top.totalRemain, "01:07");
    await top.closePage();
  });
  test("updateTime", () async {
    // updateTimeの呼び出しで時間の更新をしているかどうか
    bool updated1 = false;
    bool updated2 = false;
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();

    top.addListenerId("time", () {
      updated1 = true;
    });
    top.addListener(() {
      updated2 = true;
    });
    top.updateTime(5, 0, null);
    expect(updated1, true);
    expect(updated2, true);
    expect(top.lapRemain, "00:07");
    expect(top.totalRemain, "01:07");
    await top.closePage();
  });

  test("next", () async {
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();
    await top.next();
    expect(ctrl.func, "next");
    await top.closePage();
  });
  test("prev", () async {
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();
    await top.prev();
    expect(ctrl.func, "prev");
    await top.closePage();
  });
  test("alarm", () async {
    final top = TimerControlVM(6);
    await top.loader();
    top.reach(0, null);
    expect(view.func, "playNotification true 3000");
    top.reach(1, null);
    expect(view.func, "playNotification true 500");
    await top.closePage();
  });
}
