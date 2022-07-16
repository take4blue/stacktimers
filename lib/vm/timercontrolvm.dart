import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stacktimers/controller/backgroundtimer.dart';
import 'package:stacktimers/controller/timers.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/idbloader.dart';

/// 時間の項目
class ControlItem {
  ControlItem(this._timer, this._offset);
  final TimeTable _timer;

  /// 最終時間を求めるためのオフセット量
  final int _offset;

  /// このタイマーの開始時刻
  int get startTime => _offset;

  /// このタイマーの最終時間
  int get endTime => _offset + iTime;

  /// [TimeTable].[iTime]の取得
  int get iTime => _timer.iTime;

  /// [TimeTable].[iColor]の取得
  Color get iColor => _timer.iColor;

  /// [TimeTable].[iDuration]の取得
  int get iDuration => _timer.iDuration;
}

class TimerControlVM extends IDbLoader with Loader implements ITiemrsAction {
  TimerControlVM(this._titleid);

  /// バックグラウンド側の処理ルーチン
  final _back = Get.find<BackgroundTimer>();

  /// カウント対象の[TitleTable]の[id]
  final int _titleid;

  /// タイトル名(*)
  String title = "";

  /// 時間情報(テストのため公開)
  final times = <ControlItem>[];

  /// 現在の時間情報の場所
  int _index = 0;

  /// 総時間(テストのため公開)
  int totalTime = 0;

  /// 表示用の現在の経過時間。
  int _currentTime = 0;

  /// 現在時刻
  int get currentTime => _currentTime;

  /// 現在時刻更新
  set currentTime(int value) {
    _currentTime = value;
    lapRemain = TimeTable.formatter(times[_index].endTime - _currentTime);
    totalRemain = TimeTable.formatter(totalTime - _currentTime);
    if (totalTime == _currentTime) {
      // 時間到達したので
      isRunning = false;
    }
    update(["time"]);
    update();
  }

  /// 区間残時間(*)
  String lapRemain = "";

  /// 総残時間(*)
  String totalRemain = "";

  @override
  void reach(int index, TimeItem? item) {
    _index = index;
    lapRemain = TimeTable.formatter(0);
    ViewControl.a.playNotification(true, times[index].iDuration);
  }

  @override
  void updateTime(int time, int index, TimeItem? item) {
    currentTime = time;
    _index = index;
  }

  @override
  void status(bool isRunning) {
    _isRunning = isRunning;
  }

  /// トップ画面に戻る処理(*)
  Future<bool> closePage() async {
    _back.pause();
    _isRunning = false;
    _back.kill();
    return true;
  }

  bool _isRunning = false;

  /// 動作中かどうかの値の設定
  set isRunning(bool value) {
    _isRunning = value;
    update(["icons"]);
  }

  /// 動作中かどうか(*)
  bool get isRunning => _isRunning;

  /// start/stopの切り替え(*)
  FutureOr<void> toggleRunnning() {
    if (isRunning) {
      pause();
    } else {
      start();
    }
  }

  /// タイマー開始(*)
  FutureOr<void> start() {
    _back.start();
    isRunning = true;
  }

  /// タイマー一時停止(*)
  FutureOr<void> pause() {
    _back.pause();
    ViewControl.a.playNotification(false, 1); // 発音停止
    isRunning = false;
  }

  /// 次のタイマー位置に移動(*)
  FutureOr<void> next() {
    _back.next();
  }

  /// 前のタイマー位置に移動(*)
  FutureOr<void> prev() {
    _back.prev();
  }

  @override
  Future<void> loadDB() async {
    _back.action = this;
    times.clear();

    final data = await _back.execute(_titleid);
    title = data[0];
    final wTimes = data[1] as List<TimeTable>;
    int sum = 0;
    times.addAll(List.generate(wTimes.length, (i) {
      final result = ControlItem(wTimes[i], sum);
      sum += wTimes[i].iTime;
      return result;
    }));
    for (final time in times) {
      totalTime += time.iTime;
    }

    // すでにバックグラウンドで動いている可能性もあるのでここで初期化しておく
    _isRunning = await _back.isRunning();

    _index = 0;
    currentTime = 0;
    start();
  }

  @override
  void onClose() {
    _back.action = null;
    _isRunning = true;
    _back.kill();
    super.onClose();
  }
}
