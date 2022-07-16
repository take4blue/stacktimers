import 'package:flutter_test/flutter_test.dart';
import 'package:stacktimers/controller/timers.dart';

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

  @override
  void status(bool isRunning) {
    func.add("status $isRunning");
  }
}

void main() {
  test("TimeItem", () {
    final target = TimeItem(10, 500, 15);
    expect(target.startTime, 15);
    expect(target.endTime, 25);
    expect(target.iTime, 10);
    expect(target.iDuration, 500);

    expect(target.within(14), WithinType.outer);
    expect(target.within(15), WithinType.inner);
    expect(target.within(24), WithinType.inner);
    expect(target.within(25), WithinType.last);
    expect(target.within(26), WithinType.outer);
  });

  test("initialize", () {
    final listMap = [
      {"iTime": 5, "iDuration": 500},
      {"iTime": 3, "iDuration": 500},
      {"iTime": 7, "iDuration": 500},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    expect(result.totalTime, 15);
    expect(result.currentTime, 0);
    expect(result.isRunning, false);
  });

  test("start1", () async {
    // 単純チェック。及びiTimeが1の場合に正しく動作しているか。
    final listMap = [
      {"iTime": 1, "iDuration": 100},
      {"iTime": 1, "iDuration": 200},
      {"iTime": 1, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(result.isRunning, false);
    expect(action.func.length, 8);
    var i = 0;
    expect(action.func[i++], "status true");
    expect(action.func[i++], "reach 0 100");
    expect(action.func[i++], "updateTime 1 1 2");
    expect(action.func[i++], "reach 1 200");
    expect(action.func[i++], "updateTime 2 2 3");
    expect(action.func[i++], "reach 2 300");
    expect(action.func[i++], "updateTime 3 2 3");
    expect(action.func[i++], "status false");
  });
  test("start2", () async {
    // きちんと3このデータを順番通りに進めているか。
    final listMap = [
      {"iTime": 2, "iDuration": 100},
      {"iTime": 3, "iDuration": 200},
      {"iTime": 3, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 8500));
    expect(result.isRunning, false);
    expect(action.func.length, 13);
    int i = 0;
    expect(action.func[i++], "status true");
    expect(action.func[i++], "updateTime 1 0 2");
    expect(action.func[i++], "reach 0 100");
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "updateTime 3 1 5");
    expect(action.func[i++], "updateTime 4 1 5");
    expect(action.func[i++], "reach 1 200");
    expect(action.func[i++], "updateTime 5 2 8");
    expect(action.func[i++], "updateTime 6 2 8");
    expect(action.func[i++], "updateTime 7 2 8");
    expect(action.func[i++], "reach 2 300");
    expect(action.func[i++], "updateTime 8 2 8");
    expect(action.func[i++], "status false");
  });
  test("start3", () async {
    // Action無しの場合
    final listMap = [
      {"iTime": 1, "iDuration": 100},
      {"iTime": 1, "iDuration": 200},
      {"iTime": 1, "iDuration": 300},
    ];
    final result = Timers.fromMap(listMap);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(result.isRunning, false);
  });
  test("start4", () async {
    // Action後付け
    final listMap = [
      {"iTime": 1, "iDuration": 100},
      {"iTime": 1, "iDuration": 200},
      {"iTime": 1, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 1500));
    result.action = action;
    await Future.delayed(const Duration(milliseconds: 2000));
    expect(result.isRunning, false);
    expect(action.func.length, 5);
    int i = 0;
    expect(action.func[i++], "reach 1 200");
    expect(action.func[i++], "updateTime 2 2 3");
    expect(action.func[i++], "reach 2 300");
    expect(action.func[i++], "updateTime 3 2 3");
    expect(action.func[i++], "status false");
  });

  test("pause1", () async {
    // ポーズしているかどうか
    final listMap = [
      {"iTime": 1, "iDuration": 100},
      {"iTime": 1, "iDuration": 200},
      {"iTime": 1, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 1500));
    result.pause();
    await Future.delayed(const Duration(milliseconds: 2000));
    expect(result.isRunning, false);
    expect(action.func.length, 4);
    var i = 0;
    expect(action.func[i++], "status true");
    expect(action.func[i++], "reach 0 100");
    expect(action.func[i++], "updateTime 1 1 2");
    expect(action.func[i++], "status false");
  });
  test("pause-start", () async {
    // pauseした後startで再スタートするかどうか
    final listMap = [
      {"iTime": 1, "iDuration": 100},
      {"iTime": 1, "iDuration": 200},
      {"iTime": 1, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 1500));
    result.pause();
    result.start();
    await Future.delayed(const Duration(milliseconds: 2000));
    expect(result.isRunning, false);
    expect(action.func.length, 10);
    var i = 0;
    expect(action.func[i++], "status true");
    expect(action.func[i++], "reach 0 100");
    expect(action.func[i++], "updateTime 1 1 2");
    expect(action.func[i++], "status false");
    expect(action.func[i++], "status true");
    expect(action.func[i++], "reach 1 200");
    expect(action.func[i++], "updateTime 2 2 3");
    expect(action.func[i++], "reach 2 300");
    expect(action.func[i++], "updateTime 3 2 3");
    expect(action.func[i++], "status false");
  });
  test("restart", () async {
    // 最後まで行って、startでリスタートするかどうか
    final listMap = [
      {"iTime": 1, "iDuration": 100},
      {"iTime": 1, "iDuration": 200},
      {"iTime": 1, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(result.isRunning, false);
    expect(action.func.length, 8);
    action.func.clear();
    result.start();
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 3500));
    expect(result.isRunning, false);
    expect(action.func.length, 9);
    int i = 0;
    expect(action.func[i++], "updateTime 0 0 1"); // 0リセットが入る
    expect(action.func[i++], "status true");
    expect(action.func[i++], "reach 0 100");
    expect(action.func[i++], "updateTime 1 1 2");
    expect(action.func[i++], "reach 1 200");
    expect(action.func[i++], "updateTime 2 2 3");
    expect(action.func[i++], "reach 2 300");
    expect(action.func[i++], "updateTime 3 2 3");
    expect(action.func[i++], "status false");
  });
  test("next1", () async {
    // stop中にnextを試す
    final listMap = [
      {"iTime": 2, "iDuration": 100},
      {"iTime": 3, "iDuration": 200},
      {"iTime": 4, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.next();
    expect(result.currentTime, 2);
    result.next();
    expect(result.currentTime, 5);
    result.next(); // ここが最後なので何もしないかどうかの確認
    expect(result.currentTime, 5);
    expect(action.func.length, 2);
    int i = 0;
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "updateTime 5 2 9");
  });
  test("next2", () async {
    // start中のnext動作が正しく行われているかどうか
    final listMap = [
      {"iTime": 2, "iDuration": 100},
      {"iTime": 3, "iDuration": 200},
      {"iTime": 2, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.start();
    await Future.delayed(const Duration(milliseconds: 1500));
    result.next();
    expect(result.currentTime, 2);
    expect(result.isRunning, true);
    await Future.delayed(const Duration(milliseconds: 1500));
    result.next();
    expect(result.currentTime, 5);
    await Future.delayed(const Duration(milliseconds: 1500));
    result.next();
    expect(result.currentTime, 6);
    await Future.delayed(const Duration(milliseconds: 1500));
    expect(result.isRunning, false);
    expect(action.func.length, 9);
    int i = 0;
    expect(action.func[i++], "status true");
    expect(action.func[i++], "updateTime 1 0 2");
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "updateTime 3 1 5");
    expect(action.func[i++], "updateTime 5 2 7");
    expect(action.func[i++], "updateTime 6 2 7");
    expect(action.func[i++], "reach 2 300");
    expect(action.func[i++], "updateTime 7 2 7");
    expect(action.func[i++], "status false");
  });
  test("prev1", () async {
    // stop中にnextを試す
    final listMap = [
      {"iTime": 2, "iDuration": 100},
      {"iTime": 3, "iDuration": 200},
      {"iTime": 2, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.next();
    result.next();
    result.prev();
    expect(result.currentTime, 2);
    result.prev();
    expect(result.currentTime, 0);
    result.prev(); // すでに最初だが、再度最初に戻るという状況は許容する(*1)
    expect(result.currentTime, 0);
    expect(action.func.length, 5);
    int i = 0;
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "updateTime 5 2 7");
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "updateTime 0 0 2");
    expect(action.func[i++], "updateTime 0 0 2"); // *1
  });
  test("prev2", () async {
    // start中にprevを行う
    final listMap = [
      {"iTime": 2, "iDuration": 100},
      {"iTime": 3, "iDuration": 200},
      {"iTime": 2, "iDuration": 300},
    ];
    final action = _TestAction();
    final result = Timers.fromMap(listMap, action: action);
    result.next();
    result.start(); // 2秒から開始
    await Future.delayed(const Duration(milliseconds: 2500));
    result.prev();
    expect(result.isRunning, true);
    expect(result.currentTime, 2);
    await Future.delayed(const Duration(milliseconds: 1500));
    result.prev();
    expect(result.currentTime, 0);
    result.pause();
    expect(action.func.length, 8);
    int i = 0;
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "status true");
    expect(action.func[i++], "updateTime 3 1 5");
    expect(action.func[i++], "updateTime 4 1 5");
    expect(action.func[i++], "updateTime 2 1 5");
    expect(action.func[i++], "updateTime 3 1 5");
    expect(action.func[i++], "updateTime 0 0 2");
    expect(action.func[i++], "status false");
  });
}
