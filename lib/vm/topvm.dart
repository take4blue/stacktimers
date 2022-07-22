import 'dart:async';

import 'package:optimize_battery/optimize_battery.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/idbloader.dart';

class TitleList extends TitleTable {
  /// コンストラクタ
  TitleList(TitleTable title) : super(id: title.id, sTitle: title.sTitle);

  int totalTime = 0;

  /// 合計時間
  Future<String> time() async {
    final table = await DbAccess.a.getTimes(id);
    totalTime = 0;
    for (final item in table) {
      totalTime += item.iTime;
    }
    return TimeTable.formatter(totalTime);
  }

  static const defaultTime = "--:--";
}

class TopVM extends IDbLoader with Loader {
  /// タイトルデータの追加
  FutureOr<void> addTitle() async {
    final db = DbAccess.a;
    final addTitle = TitleTable();
    await db.updateTitle(addTitle);
    titles.add(TitleList(addTitle));
    final addTime = TimeTable.fromTitleTable(title: addTitle);
    await db.updateTime(addTime);
    await ViewControl.a.toEdit(addTitle.id);
    reset();
    update(["all"]);
  }

  /// タイマー開始処理
  FutureOr<void> startTimer(int index) async {
    await ViewControl.a.toControl(titles[index].id);
  }

  /// タイマー編集処理
  FutureOr<void> editTimer(int index) async {
    await ViewControl.a.toEdit(titles[index].id);
    update(["$index"]); // 現在のタイルの再表示
  }

  /// タイトルデータの削除
  FutureOr<void> deleteTitle(int index) async {
    await DbAccess.a.deleteTitle(titles[index].id);
    reset();
    update(["all"]);
  }

  /// 表示するタイトル情報
  final List<TitleList> titles = <TitleList>[];

  /// データ構築
  @override
  Future<void> loadDB() async {
    final isIgnored = await OptimizeBattery.isIgnoringBatteryOptimizations();
    if (!isIgnored) {
      await OptimizeBattery.stopOptimizingBatteryUsage();
    }
    titles.clear();
    final table = await DbAccess.a.getTitles;
    for (final item in table) {
      titles.add(TitleList(item));
    }
  }
}
