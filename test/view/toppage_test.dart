import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:stacktimers/l10n/message.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/toppage.dart';
import 'package:stacktimers/vm/topvm.dart';

class _Test1 extends TopVM {
  String header = "Title ";
  String func = "";
  @override
  FutureOr<void> addTitle() async {
    func = "addTitle";
  }

  @override
  Future<void> loadDB() async {
    titles.clear();
    for (int i = 0; i < 5; i++) {
      titles.add(_TT1(TitleTable(id: i, sTitle: "$header$i")));
    }
  }
}

class _Test2 extends TopVM {
  @override
  Future<void> loadDB() async {
    return Future.error("Illegal");
  }
}

class _TT1 extends TitleList {
  _TT1(TitleTable table) : super(table);

  @override
  Future<String> time() {
    return Future.value("$id:$id");
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
      final top = _Test1();
      Get.put<TopVM>(top);
      final testWidget = GetMaterialApp(
          locale: locale, theme: theme, home: const Material(child: TopPage()));
      await tester.pumpWidgetBuilder(testWidget);
      await screenMatchesGolden(tester, 'TopPage_${lang}_1');
    });
    testGoldens('error_$lang', (WidgetTester tester) async {
      final top = _Test2();
      Get.put<TopVM>(top);
      final testWidget = GetMaterialApp(
          locale: locale, theme: theme, home: const Material(child: TopPage()));
      await tester.pumpWidgetBuilder(testWidget);
      await screenMatchesGolden(tester, 'TopPage_${lang}_error');
    });
  }
  testGoldens('update', (WidgetTester tester) async {
    final top = _Test1();
    Get.put<TopVM>(top);
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TopPage()));
    await tester.pumpWidgetBuilder(testWidget);
    top.header = "Hoge ";
    top.reset();
    top.update(["all"]);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TopPage_2');
  });

  testGoldens('swipe', (WidgetTester tester) async {
    final top = _Test1();
    Get.put<TopVM>(top);
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TopPage()));
    await tester.pumpWidgetBuilder(testWidget);
    // 1行目をスワイプ
    await tester.drag(find.text("Title 1"), const Offset(-500, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TopPage_drag1');

    // 2行目をスワイプ・この時1行目のスワイプが解除される。
    // SlidableAutoCloseBehaviorが上にあるおかげで実施されるので
    // ここでは[DismissiblePane]と[key]がきちんと設定されているかどうかの確認になる
    await tester.drag(find.text("Title 2"), const Offset(-500, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'TopPage_drag2');
  });

  testWidgets('add', (WidgetTester tester) async {
    final top = _Test1();
    Get.put<TopVM>(top);
    final testWidget = GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: ThemeData(fontFamily: "IPAGothic"),
        home: const Material(child: TopPage()));
    await tester.pumpWidgetBuilder(testWidget);
    await tester.tap(find.byIcon(Icons.more_time));
    await tester.pumpAndSettle();
    expect(top.func, "addTitle");
  });
}
