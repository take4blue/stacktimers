import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:stacktimers/l10n/message.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/view/timereditpage.dart';
import 'package:stacktimers/vm/timereditvm.dart';

class _Test1 extends TimerEditVM {
  _Test1(int titleid) : super(titleid);

  String func = "";

  @override
  FutureOr<void> deleteTime(int index) async {
    func = "deleteTime $index";
  }

  @override
  FutureOr<void> editTime(int index) async {
    func = "editTime $index";
  }

  @override
  FutureOr<void> editColor(int index) async {
    func = "editColor $index";
  }

  @override
  FutureOr<void> editDuration(int index) async {
    func = "editDuration $index";
  }
}

void main() {
  setUp(() {
    Get.addTranslations(Messages().keys);
  });
  tearDown(Get.reset);
  testGoldens('initial', (WidgetTester tester) async {
    final top = TimerEditVM(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i < 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TimerListItem(0)));
    await tester.pumpWidgetBuilder(testWidget);
    await screenMatchesGolden(tester, 'TimeListItem_1');
  });
  testGoldens('update', (WidgetTester tester) async {
    // updateの呼び出しでListItemの内容が更新されているかどうかの確認
    final top = TimerEditVM(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i < 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TimerListItem(0)));
    await tester.pumpWidgetBuilder(testWidget);
    top.times[0].timer.iTime = 3000;
    top.times[0].timer.iColor = Colors.blue;
    top.update(["0"]);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimeListItem_2');
  });

  testGoldens('swipe', (WidgetTester tester) async {
    final top = TimerEditVM(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i < 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    await tester.pumpWidgetBuilder(
      SlidableAutoCloseBehavior(
        child: Column(
          children: const [
            TimerListItem(0),
            TimerListItem(1),
          ],
        ),
      ),
      wrapper: materialAppWrapper(
        theme: ThemeData(fontFamily: "IPAGothic"),
        localeOverrides: [const Locale('en', 'US')],
        platform: TargetPlatform.android,
      ),
    );
    // 1行目をスワイプ
    await tester.drag(find.byType(TimerListItem).first, const Offset(-500, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimeListItem_drag1');

    // 2行目をスワイプ・この時1行目のスワイプが解除される。
    // SlidableAutoCloseBehaviorが上にあるおかげで実施されるので
    // ここでは[DismissiblePane]と[key]がきちんと設定されているかどうかの確認になる
    await tester.drag(find.byType(TimerListItem).last, const Offset(-500, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimeListItem_drag2');
  });

  testWidgets('steditTimeart', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TimerListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.tap(find.byType(Text).first);
    await tester.pumpAndSettle();
    expect(top.func, "editTime 2");
  });

  testWidgets('editColor', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TimerListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.tap(find.byType(Container).first);
    await tester.pumpAndSettle();
    expect(top.func, "editColor 2");
  });
  testWidgets('editDuration', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TimerListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.tap(find.byType(Text).last);
    await tester.pumpAndSettle();
    expect(top.func, "editDuration 2");
  });

  testWidgets('delete', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TimerListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.drag(find.byType(ListTile), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump(const Duration(seconds: 1));
    expect(top.func, "deleteTime 2");
  });
}
