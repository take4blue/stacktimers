import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/controller/backgroundtimer.dart';
import 'package:stacktimers/l10n/message.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';
import 'package:stacktimers/vm/timereditvm.dart';

import '../testutil.dart';

class _Test1 extends TimerControlVM {
  _Test1(int titleid) : super(titleid);

  @override
  Future<void> loadDB() async {}
}

class _Test2 extends TimerEditVM {
  _Test2(int titleid) : super(titleid);

  @override
  Future<void> loadDB() async {}
}

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

void main() async {
  sqfliteFfiInit();
  int counter = 20;
  late DbAccess db;
  late int titleid;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final cTheme = ThemeData(
      fontFamily: "IPAGothic",
      cupertinoOverrideTheme: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
        pickerTextStyle:
            TextStyle(fontFamily: "IPAGothic", color: Colors.black),
      )));
  late ViewControl view;
  setUp(() async {
    Get.put<BackgroundTimer>(BackgroundTimer());
    view = ViewControl(navigatorKey: navigatorKey);
    Get.put<ViewControl>(view);
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    db = await DbAccess.create(fileName);
    Get.put<DbAccess>(db);
    titleid = await dbsetup(db);
    Get.addTranslations(Messages().keys);
  });
  tearDown(Get.reset);
  testGoldens('toControl', (WidgetTester tester) async {
    final vm = _Test1(titleid);
    Get.put<TimerControlVM>(vm);
    final testWidget = GetMaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en', 'US'),
        theme: cTheme,
        home: const Material(child: Text('X')));
    await tester.pumpWidgetBuilder(testWidget);
    view.toControl(titleid);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'viewcontrol_1');
  });
  testGoldens('toEdit', (WidgetTester tester) async {
    final vm = _Test2(titleid);
    Get.put<TimerEditVM>(vm);
    final testWidget = GetMaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en', 'US'),
        theme: cTheme,
        home: const Material(child: Text('X')));
    await tester.pumpWidgetBuilder(testWidget);
    view.toEdit(titleid);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await screenMatchesGolden(tester, 'viewcontrol_2');
  });
  testGoldens('getColor', (WidgetTester tester) async {
    final testWidget = GetMaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en', 'US'),
        theme: cTheme,
        home: const Material(child: Text('X')));
    await tester.pumpWidgetBuilder(testWidget);
    final result = view.getColor(Colors.pink);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'viewcontrol_3');
    await tester.tap(find.text("Close"));
    await tester.pumpAndSettle();
    expect(await result, Colors.pink);
  });
  testGoldens('getTime', (WidgetTester tester) async {
    final testWidget = GetMaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en', 'US'),
        theme: cTheme,
        home: const Material(child: Text('X')));
    await tester.pumpWidgetBuilder(testWidget);
    final result = view.getTime(123);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'viewcontrol_4');
    await tester.tap(find.text("X"), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(await result, 123);
  });

  testGoldens('getDuration', (WidgetTester tester) async {
    final testWidget = GetMaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en', 'US'),
        theme: cTheme,
        home: const Material(child: Text('X')));
    await tester.pumpWidgetBuilder(testWidget);
    final result = view.getDuration(500);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'viewcontrol_5');
    await tester.tap(find.text("X"), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(await result, 500);
  });
}
