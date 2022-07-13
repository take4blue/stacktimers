import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacktimers/controller/backgroundtimer.dart';
import 'package:stacktimers/controller/timers.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';

import '../testutil.dart';

class _TestAction implements ITiemrsAction {
  final func = <String>[];
  @override
  void reach(int index, TimeItem? item) {
    func.add("reach $index ${item?.iDuration}");
  }

  @override
  void updateTime(int currentTime, int index, TimeItem? item) {
    func.add("updateTime $currentTime $index ${item?.endTime}");
  }
}

const _kSTimes = "times";

void main() {
  DbAccess.initialize();
  int counter = 100;
  late DbAccess db;
  final titleid = <int>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    db = await DbAccess.create(fileName);
    Get.put<DbAccess>(db);
    final title1 = TitleTable(sTitle: "Hoge");
    await db.updateTitle(title1);
    titleid.add(title1.id);
    final title2 = TitleTable(sTitle: "Hage");
    await db.updateTitle(title2);
    titleid.add(title2.id);
    final times = List<TimeTable>.generate(2,
        (i) => TimeTable.fromTitleTable(title: title2, iTime: i + 1, iNo: i));
    await db.updateTimes(times, <int>[]);
  });
  tearDown(Get.reset);

  test("standard", () async {
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    target.initialize();
    expect(await target.isRunningId(), null);

    var result = await target.execute(titleid[0]);
    expect(result[0], "Hoge");
    {
      final times = result[1] as List<TimeTable>;
      expect(times.length, 3);
      expect(times[0].iDuration, 200);
      expect(times[1].iDuration, 300);
      expect(times[2].iDuration, 400);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    expect(await target.isRunning(), true);
    expect(await target.isRunningId(), titleid[0]);
    await Future.delayed(const Duration(milliseconds: 3000));
    expect(await target.isRunning(), false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kSTimes) != null, true);
    expect(await target.isRunningId(), titleid[0]);
    result = await target.execute(titleid[0]);
    expect(result[0], "Hoge");
    {
      final times = result[1] as List<TimeTable>;
      expect(times.length, 3);
      expect(times[0].iDuration, 200);
      expect(times[1].iDuration, 300);
      expect(times[2].iDuration, 400);
    }
    target.kill();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(await target.isRunningId(), null);
  });
  test("stop", () async {
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 500));
    target.kill();
    await Future.delayed(const Duration(milliseconds: 500));
    expect(await target.isRunning(), false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kSTimes), null);
  });
  test("action1", () async {
    // 単純なデータでのアクション呼び出しチェック
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(action.func.length, 6);
    int i = 0;
    expect(action.func[i++], "reach 0 null");
    expect(action.func[i++], "updateTime 1 1 null");
    expect(action.func[i++], "reach 1 null");
    expect(action.func[i++], "updateTime 2 2 null");
    expect(action.func[i++], "reach 2 null");
    expect(action.func[i++], "updateTime 3 2 null");
  });
  test("action2", () async {
    // 単純なデータでのアクション呼び出しチェック
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 3500));
    target.start();
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(action.func.length, 13);
    int i = 0;
    expect(action.func[i++], "reach 0 null");
    expect(action.func[i++], "updateTime 1 1 null");
    expect(action.func[i++], "reach 1 null");
    expect(action.func[i++], "updateTime 2 2 null");
    expect(action.func[i++], "reach 2 null");
    expect(action.func[i++], "updateTime 3 2 null");
    expect(action.func[i++], "updateTime 0 0 null");
    expect(action.func[i++], "reach 0 null");
    expect(action.func[i++], "updateTime 1 1 null");
    expect(action.func[i++], "reach 1 null");
    expect(action.func[i++], "updateTime 2 2 null");
    expect(action.func[i++], "reach 2 null");
    expect(action.func[i++], "updateTime 3 2 null");
  });

  test("action3", () async {
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 2, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 3, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 3, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 8500));
    expect(action.func.length, 11);
    int i = 0;
    expect(action.func[i++], "updateTime 1 0 null");
    expect(action.func[i++], "reach 0 null");
    expect(action.func[i++], "updateTime 2 1 null");
    expect(action.func[i++], "updateTime 3 1 null");
    expect(action.func[i++], "updateTime 4 1 null");
    expect(action.func[i++], "reach 1 null");
    expect(action.func[i++], "updateTime 5 2 null");
    expect(action.func[i++], "updateTime 6 2 null");
    expect(action.func[i++], "updateTime 7 2 null");
    expect(action.func[i++], "reach 2 null");
    expect(action.func[i++], "updateTime 8 2 null");
  });
  test("action4", () async {
    // 違うtitleidでリスタートしているかどうか
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 3500));
    await target.execute(titleid[1]);
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(action.func.length, 11);
    int i = 0;
    expect(action.func[i++], "reach 0 null");
    expect(action.func[i++], "updateTime 1 1 null");
    expect(action.func[i++], "reach 1 null");
    expect(action.func[i++], "updateTime 2 2 null");
    expect(action.func[i++], "reach 2 null");
    expect(action.func[i++], "updateTime 3 2 null");

    expect(action.func[i++], "reach 0 null");
    expect(action.func[i++], "updateTime 1 1 null");
    expect(action.func[i++], "updateTime 2 1 null");
    expect(action.func[i++], "reach 1 null");
    expect(action.func[i++], "updateTime 3 1 null");
  });
  test("pause-start", () async {
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 1500));
    target.pause();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(await target.isRunning(), false);
    target.start();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(await target.isRunning(), true);
    await Future.delayed(const Duration(milliseconds: 2000));
    expect(await target.isRunning(), false);
    expect(action.func.length, 6);
    expect(action.func[0], "reach 0 null");
    expect(action.func[1], "updateTime 1 1 null");
    expect(action.func[2], "reach 1 null");
    expect(action.func[3], "updateTime 2 2 null");
    expect(action.func[4], "reach 2 null");
    expect(action.func[5], "updateTime 3 2 null");
  });
  test("next", () async {
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 2, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 3, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 1, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 100));
    target.next();
    await Future.delayed(const Duration(milliseconds: 100));
    target.next();
    await Future.delayed(const Duration(milliseconds: 1500));
    expect(await target.isRunning(), false);
    expect(action.func.length, 4);
    expect(action.func[0], "updateTime 2 1 null");
    expect(action.func[1], "updateTime 5 2 null");
    expect(action.func[2], "reach 2 null");
    expect(action.func[3], "updateTime 6 2 null");
  });
  test("prev", () async {
    final data = <TimeTable>[
      TimeTable(titleid: titleid[0], iTime: 2, iDuration: 200, iNo: 0),
      TimeTable(titleid: titleid[0], iTime: 3, iDuration: 300, iNo: 1),
      TimeTable(titleid: titleid[0], iTime: 2, iDuration: 400, iNo: 2)
    ];
    await db.updateTimes(data, <int>[]);
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    await target.execute(titleid[0]);
    await Future.delayed(const Duration(milliseconds: 100));
    target.pause();
    await Future.delayed(const Duration(milliseconds: 100));
    target.next();
    await Future.delayed(const Duration(milliseconds: 100));
    target.next();
    await Future.delayed(const Duration(milliseconds: 100));
    target.prev();
    await Future.delayed(const Duration(milliseconds: 100));
    target.prev();
    await Future.delayed(const Duration(milliseconds: 100));
    target.prev(); // すでに最初だが、再度最初に戻るという状況は許容する(*1)
    await Future.delayed(const Duration(milliseconds: 100));
    expect(action.func.length, 5);
    int i = 0;
    expect(action.func[i++], "updateTime 2 1 null");
    expect(action.func[i++], "updateTime 5 2 null");
    expect(action.func[i++], "updateTime 2 1 null");
    expect(action.func[i++], "updateTime 0 0 null");
    expect(action.func[i++], "updateTime 0 0 null"); // *1
  });
}
