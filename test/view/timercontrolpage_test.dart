import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:stacktimers/l10n/message.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/view/timercontrolpage.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';

// 時間を取り扱うための係数
// timercontrolvm.dart内の同名の変数に合わせて評価する
const _kScale = 10;

class _Test1 extends TimerControlVM {
  _Test1(int titleid) : super(titleid);

  String func = "";

  bool wIsRunning = true;

  @override
  bool get isRunning => wIsRunning;

  @override
  Future<bool> closePage() async {
    func = "closePage";
    return true;
  }

  @override
  FutureOr<void> start() async {
    func = "start";
  }

  @override
  FutureOr<void> pause() async {
    func = "pause";
  }

  @override
  FutureOr<void> next() async {
    func = "next";
  }

  @override
  FutureOr<void> prev() async {
    func = "prev";
  }

  @override
  FutureOr<void> toggleRunnning() async {
    func = "toggleRunnning";
  }

  @override
  Future<void> loadDB() async {
    times.add(ControlItem(TimeTable(titleid: 1, iNo: 0, iTime: 30), 0));
    times.add(ControlItem(TimeTable(titleid: 1, iNo: 1, iTime: 40), 30));
    times.add(ControlItem(TimeTable(titleid: 1, iNo: 2, iTime: 10), 70));
    totalTime = (30 + 40 + 10) * _kScale;
  }
}

class _Test2 extends TimerControlVM {
  _Test2(int titleid) : super(titleid);
  @override
  Future<void> loadDB() async {
    return Future.error("illegal");
  }
}

void main() {
  setUp(() {
    Get.addTranslations(Messages().keys);
  });
  tearDown(Get.reset);
  for (final lang in ["ja", "en"]) {
    ThemeData? theme;
    Locale? locale;
    switch (lang) {
      case "en":
        locale = const Locale('en', 'US');
        theme = null;
        break;
      case "ja":
        locale = const Locale('ja', 'JP');
        theme = ThemeData(fontFamily: "IPAGothic");
        break;
    }

    testGoldens('initial_$lang', (WidgetTester tester) async {
      final top = _Test1(1);
      top.title = "hoge";
      top.lapRemain = "Remain1";
      top.totalRemain = "Remain1";
      Get.put<TimerControlVM>(top);
      final testWidget =
          GetMaterialApp(locale: locale, theme: theme, home: const Text("X"));
      await tester.pumpWidgetBuilder(testWidget);
      Get.to(
        () => const TimerControlPage(),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'TimerControlPage_${lang}_1');
    });
    testGoldens('error_$lang', (WidgetTester tester) async {
      final top = _Test2(1);
      Get.put<TimerControlVM>(top);
      final testWidget =
          GetMaterialApp(locale: locale, theme: theme, home: const Text("X"));
      await tester.pumpWidgetBuilder(testWidget);
      Get.to(
        () => const TimerControlPage(),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'TimerControlPage_${lang}_error');
    });
  }
  testGoldens('changeicon', (WidgetTester tester) async {
    final top = _Test1(1);
    top.wIsRunning = false;
    Get.put<TimerControlVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text("X"));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerControlPage(),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerControlPage_icon1');
    top.wIsRunning = true;
    top.update(["icons"]);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerControlPage_icon2');
  });

  testGoldens('changetimes', (WidgetTester tester) async {
    // updateの呼び出しでstop/play_arrowの切り替えが起こっているか
    final top = _Test1(1);
    top.lapRemain = "Remain1";
    top.totalRemain = "Remain1";
    Get.put<TimerControlVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text("X"));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerControlPage(),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerControlPage_time1');
    top.wIsRunning = true;
    top.lapRemain = "hoge";
    top.totalRemain = "hage";
    top.update(["time"]);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerControlPage_time2');
  });

  testWidgets('tap', (WidgetTester tester) async {
    final top = _Test1(1);
    top.wIsRunning = true;
    Get.put<TimerControlVM>(top);
    const testWidget = GetMaterialApp(home: Text("X"));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerControlPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key("tap")));
    expect(top.func, "toggleRunnning");
    await tester.tap(find.byIcon(Icons.skip_previous));
    expect(top.func, "prev");
    await tester.tap(find.byIcon(Icons.skip_next));
    expect(top.func, "next");
    await tester.tap(find.byIcon(Icons.pause));
    expect(top.func, "pause");
    top.wIsRunning = false;
    top.update(["icons"]);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(top.func, "start");
  });
}
