import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacktimers/controller/backgroundtimer.dart';
import 'package:stacktimers/controller/timers.dart';
import 'package:stacktimers/model/timetable.dart';

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

const _kSValue = "data";

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test("standard", () async {
    final data = <TimeTable>[
      TimeTable(titleid: 1, iTime: 1, iDuration: 200),
      TimeTable(titleid: 1, iTime: 1, iDuration: 300),
      TimeTable(titleid: 1, iTime: 1, iDuration: 400)
    ];
    final target = BackgroundTimer();
    target.initialize();
    target.execute(data);
    await Future.delayed(const Duration(milliseconds: 500));
    expect(await target.isRunning(), true);
    await Future.delayed(const Duration(milliseconds: 3000));
    expect(await target.isRunning(), false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kSValue) != null, true);
  });
  test("stop", () async {
    final data = <TimeTable>[
      TimeTable(titleid: 1, iTime: 1, iDuration: 200),
      TimeTable(titleid: 1, iTime: 1, iDuration: 300),
      TimeTable(titleid: 1, iTime: 1, iDuration: 400)
    ];
    final target = BackgroundTimer();
    target.initialize();
    target.execute(data);
    await Future.delayed(const Duration(milliseconds: 500));
    target.kill();
    await Future.delayed(const Duration(milliseconds: 500));
    expect(await target.isRunning(), false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kSValue), null);
  });
  test("action1", () async {
    // 単純なデータでのアクション呼び出しチェック
    final data = <TimeTable>[
      TimeTable(titleid: 1, iTime: 1, iDuration: 200),
      TimeTable(titleid: 1, iTime: 1, iDuration: 300),
      TimeTable(titleid: 1, iTime: 1, iDuration: 400)
    ];
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    target.execute(data);
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
      TimeTable(titleid: 1, iTime: 1, iDuration: 200),
      TimeTable(titleid: 1, iTime: 1, iDuration: 300),
      TimeTable(titleid: 1, iTime: 1, iDuration: 400)
    ];
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    target.execute(data);
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
      TimeTable(titleid: 1, iTime: 2, iDuration: 200),
      TimeTable(titleid: 1, iTime: 3, iDuration: 300),
      TimeTable(titleid: 1, iTime: 3, iDuration: 400)
    ];
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    target.execute(data);
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
  test("pause-start", () async {
    final data = <TimeTable>[
      TimeTable(titleid: 1, iTime: 1, iDuration: 200),
      TimeTable(titleid: 1, iTime: 1, iDuration: 300),
      TimeTable(titleid: 1, iTime: 1, iDuration: 400)
    ];
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    target.execute(data);
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
      TimeTable(titleid: 1, iTime: 2, iDuration: 200),
      TimeTable(titleid: 1, iTime: 3, iDuration: 300),
      TimeTable(titleid: 1, iTime: 1, iDuration: 400)
    ];
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    target.execute(data);
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
      TimeTable(titleid: 1, iTime: 2, iDuration: 200),
      TimeTable(titleid: 1, iTime: 3, iDuration: 300),
      TimeTable(titleid: 1, iTime: 2, iDuration: 400)
    ];
    final target = BackgroundTimer();
    final action = _TestAction();
    target.action = action;
    target.initialize();
    target.execute(data);
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
