import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/idbloader.dart';

/// 時間の編集項目
class EditItem {
  EditItem(this.timer);
  final TimeTable timer;

  /// 時間を文字列化したもの
  String get time => TimeTable.formatter(timer.iTime);

  /// 発音時間(秒で表示する)
  String get duration {
    final f = NumberFormat("0.0");
    return f.format(timer.iDuration / 1000);
  }
}

class TimerEditVM extends IDbLoader with Loader {
  TimerEditVM(this._titleid);

  final controller = TextEditingController();

  /// 編集対象の[TitleTable]の[id]
  final int _titleid;

  /// タイトル名
  String title = "";

  /// 削除対象のレコードID保存場所
  final removeRecord = <int>[];

  /// 編集中の時間情報
  final times = <EditItem>[];

  /// データベースの内容を更新する
  ///
  /// ページから抜ける際に呼び出しを行うもので、基本常にtrueでリターンする
  Future<bool> updateDb() async {
    final titleTbl = TitleTable(id: _titleid, sTitle: title);
    await DbAccess.a.updateTitle(titleTbl);
    int iNo = 0;
    for (final item in times) {
      item.timer.iNo = iNo++;
    }
    final timesTbl = List.generate(times.length, (index) => times[index].timer);
    await DbAccess.a.updateTimes(timesTbl, removeRecord);
    return true;
  }

  /// タイマーを1レコード追加する
  FutureOr<void> addTimer() async {
    times.add(EditItem(TimeTable(titleid: _titleid, iNo: times.length)));
    update(["list"]);
  }

  /// タイトル名を変更する
  FutureOr<void> changeTitle(String? value) async {
    title = value ?? "";
  }

  /// 時間の削除
  FutureOr<void> deleteTime(int index) async {
    if (times[index].timer.id != -1) {
      removeRecord.add(times[index].timer.id);
    }
    times.removeAt(index);
    update(["list", "total"]);
  }

  /// 時間の編集
  FutureOr<void> editTime(int index) async {
    times[index].timer.iTime =
        await ViewControl.a.getTime(times[index].timer.iTime);
    update(["$index", "total"]);
  }

  /// 色の編集
  FutureOr<void> editColor(int index) async {
    times[index].timer.iColor =
        await ViewControl.a.getColor(times[index].timer.iColor);
    update(["$index"]);
  }

  /// 音色の継続時間の編集
  FutureOr<void> editDuration(int index) async {
    times[index].timer.iDuration =
        await ViewControl.a.getDuration(times[index].timer.iDuration);
    update(["$index"]);
  }

  /// リスト位置の入れ替え
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = times.removeAt(oldIndex);
    times.insert(newIndex, item);
    final length = (oldIndex - newIndex).abs();
    final start = min(oldIndex, newIndex);
    update([List.generate(length, (index) => (index + start).toString())]);
  }

  /// トータル時間の算出
  String get total {
    int sum = 0;
    for (final time in times) {
      sum += time.timer.iTime;
    }

    return "Total : ${TimeTable.formatter(sum)}";
  }

  @override
  Future<void> loadDB() async {
    final titleTbl = await DbAccess.a.getTitle(_titleid);
    title = titleTbl.sTitle;
    final timesTbl = await DbAccess.a.getTimes(_titleid);
    for (final item in timesTbl) {
      times.add(EditItem(item));
    }
    update(["all"]);
    update(["list"]);
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}
