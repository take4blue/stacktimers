import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';

import '../mockviewcontrol.dart';
import '../testutil.dart';

// 時間を取り扱うための係数
// timercontrolvm.dart内の同名の変数に合わせて評価する
const _kScale = 10;

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
  int counter = 80;
  TestWidgetsFlutterBinding.ensureInitialized();

  late DbAccess db;
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
  });
  tearDown(Get.reset);

  test("ControlItem", () {
    final data =
        TimeTable(titleid: 1, iColor: Colors.white, iDuration: 500, iTime: 10);
    final target = ControlItem(data, 10);
    expect(target.startTime, 10 * _kScale);
    expect(target.endTime, (data.iTime + 10) * _kScale);
    expect(target.iTime, data.iTime * _kScale);
    expect(target.iColor, data.iColor);
    expect(target.iDuration, data.iDuration);

    expect(target.within(9 * _kScale), WithinType.outer);
    expect(target.within(10 * _kScale), WithinType.inner);
    expect(target.within(19 * _kScale), WithinType.inner);
    expect(target.within(20 * _kScale), WithinType.last);
    expect(target.within(21 * _kScale), WithinType.outer);
  });

  test("loader", () async {
    var updated1 = false;
    final top = TimerControlVM(3);
    top.addListener(() {
      updated1 = true;
    });
    await top.loader();
    expect(updated1, true);
    expect(top.currentTime, 0);
    expect(top.isRunning, true);
    expect(top.isNotLoadDb, false);
    expect(top.title, "Hoge 3");
    expect(top.times.length, 3);
    int sum = 0; // これは秒
    for (int i = 0; i < top.times.length; i++) {
      expect(top.times[i].iTime, 12 * (i + 1) * _kScale);
      expect(top.times[i].startTime, sum * _kScale);
      sum += 12 * (i + 1);
    }
    expect(top.totalTime, sum * _kScale);
    expect(top.totalRemain, TimeTable.formatter(sum));
    expect(top.lapRemain, TimeTable.formatter(top.times[0].endTime ~/ _kScale));
    expect(await top.closePage(), true);
  });

  test("pause", () async {
    // ポーズをして時間計測が停止しているかの確認として
    // ポーズ後にリスナーを定義してそこに飛んでこないことを確認する
    bool updated1 = false;
    bool updated2 = false;
    final top = TimerControlVM(3);
    await top.loader();
    top.addListenerId("icons", () {
      updated2 = true;
    });
    await top.pause();
    top.addListener(() {
      updated1 = true;
    });
    expect(top.isRunning, false);
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(updated1, false); // タイマー割り込み実施可否
    expect(updated2, true); // アイコン領域の更新指示可否
    expect(view.func, "playNotification false 1"); // 音停止
    await top.closePage();
  });

  test("start1", () async {
    // currentTimeが更新されているかどうかで判断する
    bool updated2 = false;
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();
    final work = top.currentTime ~/ _kScale;
    top.addListenerId("icons", () {
      updated2 = true;
    });
    await top.start();
    expect(top.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(updated2, true); // アイコン領域の更新指示可否
    expect(top.currentTime ~/ _kScale, work + 2); // 時間単位が秒を基準としていたのでそれに合わせてある
    await top.closePage();
  });

  test("start2", () async {
    // 良い定時間経過後ポーズして、その後startした時に、ポーズした
    // 時間から計測を開始するか
    // またポーズ後一定時間経過させ再スタート時に、時間が経過していないことを確認
    final top = TimerControlVM(3);
    await top.loader();
    await Future.delayed(const Duration(milliseconds: 2500));
    await top.pause();
    await Future.delayed(const Duration(milliseconds: 2000));
    final work = top.currentTime ~/ _kScale;
    await top.start();
    await Future.delayed(const Duration(milliseconds: 200));
    expect(top.currentTime ~/ _kScale, work); // 時間単位が秒を基準としていたのでそれに合わせてある
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

  test("currentTime", () async {
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

    top.currentTime = 5 * _kScale;
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
    expect(top.currentTime, 12 * _kScale);
    await top.next();
    expect(top.currentTime, 36 * _kScale);
    await top.start();
    await Future.delayed(const Duration(milliseconds: 2500));
    await top.next();
    expect(top.currentTime != 36 * _kScale, true);
    expect(top.currentTime != 72 * _kScale, true);
    await top.closePage();
  });
  test("prev", () async {
    final top = TimerControlVM(3);
    await top.loader();
    await top.pause();
    await top.next();
    await top.next();
    await top.start();
    await Future.delayed(const Duration(milliseconds: 2500));
    await top.prev();
    expect(top.currentTime, 36 * _kScale);

    // 以下のdelayタイムは_kScaleによって変わる。
    // _kScaleが1の場合は1500、10の場合は500
    // 1の場合は単位は秒なので0～2未満がチェック対象になるが10の場合は
    // 単位が100msなので0.0～1.1未満がチェック対象になるので。
    await Future.delayed(const Duration(milliseconds: 500));
    await top.prev();
    expect(top.currentTime, 12 * _kScale);
    await top.prev();
    expect(top.currentTime, 0 * _kScale);
    await top.closePage();
  });
  test("alarm", () async {
    final top = TimerControlVM(6);
    await top.loader();
    await Future.delayed(const Duration(milliseconds: 1500));
    expect(view.func, "playNotification true 3000");
    await Future.delayed(const Duration(milliseconds: 4500));
    expect(top.currentTime, 5 * _kScale);
    expect(view.func, "playNotification true 500"); // 末尾まで行ったので
    expect(top.isRunning, false);
    await top.closePage();
    expect(view.func, "playNotification false 1"); // 音を止める
  });
  test("restart", () async {
    final top = TimerControlVM(6);
    await top.loader();
    await top.next();
    await top.next();
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(top.isRunning, false);
    await top.start();
    expect(top.currentTime, 0);
    await top.closePage();
  });

  test("remain", () async {
    final top = TimerControlVM(6);
    await top.loader();
    await top.pause();
    top.currentTime = 0;
    expect(top.lapRemain, "00:01");
    expect(top.totalRemain, "00:05");
    top.currentTime = 1;
    expect(top.lapRemain, "00:01");
    expect(top.totalRemain, "00:05");
    top.currentTime = 9;
    expect(top.lapRemain, "00:01");
    expect(top.totalRemain, "00:05");
    top.currentTime = 10;
    expect(top.lapRemain, "00:00");
    expect(top.totalRemain, "00:04");
    await top.next();
    await top.next();
    top.currentTime = 49;
    expect(top.lapRemain, "00:01");
    expect(top.totalRemain, "00:01");
    top.currentTime = 50;
    expect(top.lapRemain, "00:00");
    expect(top.totalRemain, "00:00");
  });
}
