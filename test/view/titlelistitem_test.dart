import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:stacktimers/l10n/message.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/toppage.dart';
import 'package:stacktimers/vm/topvm.dart';

class _Test1 extends TopVM {
  String func = "";
  @override
  FutureOr<void> startTimer(int index) async {
    func = "startTime $index";
  }

  @override
  FutureOr<void> editTimer(int index) async {
    func = "editTimer $index";
  }

  @override
  FutureOr<void> deleteTitle(int index) async {
    func = "deleteTitle $index";
  }
}

class _TT1 extends TitleList {
  _TT1(TitleTable table) : super(table);

  @override
  Future<String> time() {
    return Future.value("$id:$id");
  }
}

class _TT2 extends TitleList {
  _TT2(TitleTable table) : super(table);

  @override
  Future<String> time() {
    return Future.error("$id:$id");
  }
}

void main() {
  setUp(() {
    Get.addTranslations(Messages().keys);
  });
  tearDown(Get.reset);
  testGoldens('initial', (WidgetTester tester) async {
    final top = TopVM();
    Get.put<TopVM>(top);
    for (int i = 1; i < 3; i++) {
      top.titles.add(_TT1(TitleTable(id: i, sTitle: "Title $i")));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TitleListItem(0)));
    await tester.pumpWidgetBuilder(testWidget);
    await screenMatchesGolden(tester, 'TitleListItem_1');
  });
  testGoldens('update', (WidgetTester tester) async {
    // updateの呼び出しでListItemの内容が更新されているかどうかの確認
    final top = TopVM();
    Get.put<TopVM>(top);
    for (int i = 1; i < 3; i++) {
      top.titles.add(_TT1(TitleTable(id: i, sTitle: "Title $i")));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TitleListItem(0)));
    await tester.pumpWidgetBuilder(testWidget);
    top.titles[0].sTitle = "hoge";
    top.update(["0"]);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TitleListItem_2');
  });
  testGoldens('error', (WidgetTester tester) async {
    final top = TopVM();
    Get.put<TopVM>(top);
    for (int i = 1; i < 3; i++) {
      top.titles.add(_TT2(TitleTable(id: i, sTitle: "Title $i")));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TitleListItem(0)));
    await tester.pumpWidgetBuilder(testWidget);
    await screenMatchesGolden(tester, 'TitleListItem_error');
  });

  testGoldens('swipe', (WidgetTester tester) async {
    final top = TopVM();
    Get.put<TopVM>(top);
    for (int i = 1; i < 3; i++) {
      top.titles.add(_TT2(TitleTable(id: i, sTitle: "Title $i")));
    }
    await tester.pumpWidgetBuilder(
      SlidableAutoCloseBehavior(
        child: Column(
          children: const [
            TitleListItem(0),
            TitleListItem(1),
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
    await tester.drag(find.text("Title 1"), const Offset(-500, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TitleListItem_drag1');

    // 2行目をスワイプ・この時1行目のスワイプが解除される。
    // SlidableAutoCloseBehaviorが上にあるおかげで実施されるので
    // ここでは[DismissiblePane]と[key]がきちんと設定されているかどうかの確認になる
    await tester.drag(find.text("Title 2"), const Offset(-500, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TitleListItem_drag2');
  });

  testWidgets('start', (WidgetTester tester) async {
    final top = _Test1();
    Get.put<TopVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.titles.add(_TT1(TitleTable(id: i, sTitle: "Title $i")));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TitleListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.tap(find.byIcon(Icons.start));
    await tester.pumpAndSettle();
    expect(top.func, "startTime 2");
  });

  testWidgets('edit', (WidgetTester tester) async {
    final top = _Test1();
    Get.put<TopVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.titles.add(_TT1(TitleTable(id: i, sTitle: "Title $i")));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TitleListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(top.func, "editTimer 2");
  });

  testWidgets('delete', (WidgetTester tester) async {
    final top = _Test1();
    Get.put<TopVM>(top);
    for (int i = 1; i <= 3; i++) {
      top.titles.add(_TT1(TitleTable(id: i, sTitle: "Title $i")));
    }
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TitleListItem(2)));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.drag(find.text("Title 3"), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump(const Duration(seconds: 1));
    expect(top.func, "deleteTitle 2");
  });
}
