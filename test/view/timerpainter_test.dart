import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/view/timerpainter.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';

// 時間を取り扱うための係数
// timercontrolvm.dart内の同名の変数に合わせて評価する
const _kScale = 10;

class _Test1 extends TimerControlVM {
  _Test1(int titleid) : super(titleid);

  int _currentTime = 0;

  @override
  int get currentTime => _currentTime;

  set value(int value) {
    _currentTime = value * _kScale;
    refresh();
  }
}

void addData(TimerControlVM top) {
  top.times.add(ControlItem(TimeTable(titleid: 1, iNo: 0, iTime: 30), 0));
  top.times.add(ControlItem(TimeTable(titleid: 1, iNo: 1, iTime: 40), 30));
  top.times.add(ControlItem(TimeTable(titleid: 1, iNo: 2, iTime: 10), 70));
  top.totalTime = (30 + 40 + 10) * _kScale;
}

void main() {
  tearDown(Get.reset);

  testGoldens('outer_draw', (WidgetTester tester) async {
    final top = TimerControlVM(1);
    addData(top);
    Get.put<TimerControlVM>(top);
    final testWidget = GetMaterialApp(
        home: CustomPaint(
      painter: TimerOutPainter(),
    ));
    await tester.pumpWidgetBuilder(testWidget);
    await screenMatchesGolden(tester, 'TimerOutPainter_1');
  });
  testGoldens('inner_draw', (WidgetTester tester) async {
    final top = _Test1(1);
    addData(top);
    top.value = 0;
    Get.put<TimerControlVM>(top);
    final testWidget = GetMaterialApp(
        home: CustomPaint(
      painter: TimerInPainter(repaint: top),
    ));
    await tester.pumpWidgetBuilder(testWidget);
    int counter = 0;
    await screenMatchesGolden(tester, 'TimerInPainter_${++counter}');
    top.value = 40;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_${++counter}');
    top.value = 70;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_${++counter}');
    top.value = 79;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_${++counter}');
    top.value = 80;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_${++counter}');
    top.value = 90;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_${++counter}');
  });

  testGoldens('mix_draw', (WidgetTester tester) async {
    final top = _Test1(1);
    addData(top);
    top.value = 0;
    Get.put<TimerControlVM>(top);
    final testWidget = GetMaterialApp(
        home: CustomPaint(
      painter: TimerOutPainter(),
      foregroundPainter: TimerInPainter(repaint: top),
    ));
    await tester.pumpWidgetBuilder(testWidget);
    int counter = 0;
    await screenMatchesGolden(tester, 'TimerPainter_${++counter}');
    top.value = 40;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerPainter_${++counter}');
    top.value = 70;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerPainter_${++counter}');
    top.value = 79;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerPainter_${++counter}');
    top.value = 80;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerPainter_${++counter}');
    top.value = 90;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerPainter_${++counter}');
  });

  testGoldens('outer_draw_item1', (WidgetTester tester) async {
    final top = TimerControlVM(1);
    top.times.add(ControlItem(TimeTable(titleid: 1, iNo: 0, iTime: 30), 0));
    top.totalTime = 30 * _kScale;
    Get.put<TimerControlVM>(top);
    final testWidget = GetMaterialApp(
        home: CustomPaint(
      painter: TimerOutPainter(),
    ));
    await tester.pumpWidgetBuilder(testWidget);
    await screenMatchesGolden(tester, 'TimerOutPainter_2');
  });
  testGoldens('outer_draw_item2', (WidgetTester tester) async {
    final top = TimerControlVM(1);
    Get.put<TimerControlVM>(top);
    final testWidget = GetMaterialApp(
        home: CustomPaint(
      painter: TimerOutPainter(),
    ));
    await tester.pumpWidgetBuilder(testWidget);
    await screenMatchesGolden(tester, 'TimerOutPainter_3');
  });
  testGoldens('inner_draw_item1', (WidgetTester tester) async {
    final top = _Test1(1);
    top.times.add(ControlItem(TimeTable(titleid: 1, iNo: 0, iTime: 720), 0));
    top.totalTime = 720 * _kScale;
    top.value = 0;
    Get.put<TimerControlVM>(top);
    final testWidget = GetMaterialApp(
        home: CustomPaint(
      painter: TimerInPainter(repaint: top),
    ));
    await tester.pumpWidgetBuilder(testWidget);
    int counter = 0;
    await screenMatchesGolden(tester, 'TimerInPainter_1${++counter}');
    top.value = 360;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_1${++counter}');
    top.value = 719;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_1${++counter}');
    top.value = 720;
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerInPainter_1${++counter}');
  });
}
