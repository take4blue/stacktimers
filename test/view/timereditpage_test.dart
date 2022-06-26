import 'dart:async';

import 'package:flutter/material.dart';
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
  Future<bool> updateDb() async {
    func = "updateDb";
    return true;
  }

  @override
  FutureOr<void> addTimer() async {
    func = "addTimer";
  }

  /// 時間の削除
  @override
  FutureOr<void> deleteTime(int index) async {
    func = "deleteTime $index";
  }

  @override
  Future<void> loadDB() async {
    for (int i = 1; i <= 20; i++) {
      times.add(
          EditItem(TimeTable(id: i, titleid: 1, iTime: 10 * i + i, iNo: i)));
    }
  }
}

class _Test2 extends TimerEditVM {
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
      Get.put<TimerEditVM>(top);
      final testWidget =
          GetMaterialApp(locale: locale, theme: theme, home: const Text("X"));
      await tester.pumpWidgetBuilder(testWidget);
      Get.to(
        () => const TimerEditPage(),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'TimerEditPage_${lang}_1');
    });
    testGoldens('title_$lang', (WidgetTester tester) async {
      final top = _Test1(1);
      top.title = "hoge";
      Get.put<TimerEditVM>(top);
      final testWidget =
          GetMaterialApp(locale: locale, theme: theme, home: const Text("X"));
      await tester.pumpWidgetBuilder(testWidget);
      Get.to(
        () => const TimerEditPage(),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'TimerEditPage_${lang}_2');
    });

    testGoldens('error_$lang', (WidgetTester tester) async {
      final top = _Test2(1);
      Get.put<TimerEditVM>(top);
      final testWidget =
          GetMaterialApp(locale: locale, theme: theme, home: const Text("X"));
      await tester.pumpWidgetBuilder(testWidget);
      Get.to(
        () => const TimerEditPage(),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'TimerEditPage_${lang}_error');
    });
  }

  testWidgets('updateDb', (WidgetTester tester) async {
    // updateの呼び出しでListItemの内容が更新されているかどうかの確認
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(top.func, "updateDb");
  });

  testWidgets('changeTitle', (WidgetTester tester) async {
    // タイトル文字の変更
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), "Hoge");
    await tester.pumpAndSettle();
    expect(top.title, "Hoge");
  });
  testWidgets('addTimer', (WidgetTester tester) async {
    // タイマー追加
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.more_time));
    await tester.pumpAndSettle();
    expect(top.func, "addTimer");
  });
  testGoldens('swipe', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final item = find.byType(TimerListItem);
    final size = tester.getSize(item.at(0));
    // 1行目をスワイプ
    await tester.drag(item.at(0), Offset(-size.width, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerEditPage_drag1');

    // 2行目をスワイプ・この時1行目のスワイプが解除される。
    // SlidableAutoCloseBehaviorが上にあるおかげで実施されるので
    // ここでは[DismissiblePane]と[key]がきちんと設定されているかどうかの確認になる
    await tester.drag(item.at(1), Offset(-size.width, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TimerEditPage_drag2');
  });

  testWidgets('delete', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final item = find.byType(TimerListItem);
    final size = tester.getSize(item.at(0));
    // 1行目をスワイプ
    await tester.drag(item.at(1), Offset(-size.width / 3, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump(const Duration(seconds: 1));
    expect(top.func, "deleteTime 1");
  });
  testGoldens('reorderdown', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final size = tester.getSize(find.byType(TimerListItem).at(0));

    final item = find.byIcon(Icons.drag_handle);
    await tester.drag(item.at(0), Offset(0, size.height * 5.0),
        warnIfMissed: false);
    await screenMatchesGolden(tester, 'TimerEditPage_reorder1');
  });
  testGoldens('reorderup', (WidgetTester tester) async {
    final top = _Test1(1);
    Get.put<TimerEditVM>(top);
    const testWidget =
        GetMaterialApp(locale: Locale('en', 'US'), home: Text('X'));
    await tester.pumpWidgetBuilder(testWidget);
    Get.to(
      () => const TimerEditPage(),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final size = tester.getSize(find.byType(TimerListItem).at(0));

    final item = find.byIcon(Icons.drag_handle);
    await tester.drag(item.at(5), Offset(0, -size.height * 3.0),
        warnIfMissed: false);
    await screenMatchesGolden(tester, 'TimerEditPage_reorder2');
  });
}
