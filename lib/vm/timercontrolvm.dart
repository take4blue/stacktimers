import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gui_box/gui_box.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/idbloader.dart';

enum WithinType {
  /// 範囲外
  outer,

  /// 範囲内
  inner,

  /// [endTime]に一致
  last
}

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

  /// 音を鳴らしたかどうか
  bool doBeep = false;

  /// [time]が[startTime]～[endTime]の間かどうか
  WithinType within(int time) {
    return startTime <= time && time < endTime
        ? WithinType.inner
        : time == endTime
            ? WithinType.last
            : WithinType.outer;
  }
}

class TimerControlVM extends IDbLoader with Loader {
  TimerControlVM(this._titleid);

  /// カウント対象の[TitleTable]の[id]
  final int _titleid;

  /// タイトル名
  String title = "";

  /// 時間情報
  final times = <ControlItem>[];

  /// 現在の時間情報の場所
  int _index = 0;

  /// 総時間
  int totalTime = 0;

  /// 現在の経過時間
  int get elapsed => _offsetTime + _timer.elapsed.inSeconds;

  /// prev/nextで移動した際のオフセット時間
  int _offsetTime = 0;

  /// ストップウォッチ情報
  final _timer = Stopwatch();

  /// 表示用の現在の経過時間。
  int _currentTime = 0;

  /// 現在時刻
  int get currentTime => _currentTime;

  /// 現在時刻更新
  set currentTime(int value) {
    _currentTime = value;
    lapRemain = TimeSelector.formatter(times[_index].endTime - _currentTime);
    totalRemain = TimeSelector.formatter(totalTime - _currentTime);
    update(["time"]);
    update();
  }

  /// 区間残時間
  String lapRemain = "";

  /// 総残時間
  String totalRemain = "";

  /// タイマー
  Timer? _timerInterrupt;

  /// 時間監視の[times]毎の処理
  ///
  /// for/switchの組み合わせでswitchからの大ブレイクをするため関数化してある
  void _check1(int now) {
    for (int i = _index; i < times.length; i++) {
      switch (times[i].within(now)) {
        case WithinType.outer:
          // 何もしない.
          break;
        case WithinType.inner:
          _index = i;
          return;
        case WithinType.last:
          // 音を鳴らす
          lapRemain = TimeSelector.formatter(0);
          ViewControl.a.playNotification(true, times[i].iDuration);
          times[i].doBeep = true;
          return;
      }
    }
  }

  /// 時間監視処理
  ///
  /// タイマーストップ中は何もしないようにする。（割り込み継続も）
  void _check() {
    if (isRunning) {
      final now = elapsed;
      if (currentTime < now) {
        _check1(now);
      }
      currentTime = now;
      if (now != totalTime) {
        // 最終時間に至ってなければタイマー割り込み継続
        _nextTimerSet();
      } else if (now >= totalTime) {
        pause();
      }
    }
  }

  /// トップ画面に戻る処理
  Future<bool> closePage() async {
    await pause();
    return true;
  }

  /// 動作中かどうか
  bool get isRunning => _timer.isRunning;

  /// start/stopの切り替え
  FutureOr<void> toggleRunnning() async {
    if (isRunning) {
      pause();
    } else {
      start();
    }
  }

  /// 次のタイマーの設定関数
  /// 秒の桁上がり時に処理ができるように、残りミリ秒+αで
  /// 割り込みが発生するように時間調整をする
  void _nextTimerSet() {
    final duration = 1050 - (_timer.elapsedMilliseconds % 1000);
    _timerInterrupt = Timer(Duration(milliseconds: duration), _check);
  }

  /// タイマー開始
  FutureOr<void> start() async {
    _timer.start();
    _nextTimerSet();
    update(["icons"]);
  }

  /// タイマー一時停止
  FutureOr<void> pause() async {
    _timer.stop();
    ViewControl.a.playNotification(false, 1); // 発音停止
    _timerInterrupt?.cancel();
    _timerInterrupt = null;
    update(["icons"]);
  }

  /// 次のタイマー位置に移動
  FutureOr<void> next() async {
    final now = elapsed;
    for (int i = _index; i < times.length - 1; i++) {
      times[i].doBeep = true;
      if (now < times[i].endTime) {
        _index = i + 1;
        _timer.reset();
        _offsetTime = currentTime = times[_index].startTime;
        break;
      }
    }
  }

  /// 前のタイマー位置に移動
  FutureOr<void> prev() async {
    final now = elapsed;
    for (; _index >= 0; _index--) {
      if (times[_index].startTime == now ||
          times[_index].startTime + 1 == now) {
        continue;
      }
      if (times[_index].startTime < now) {
        break;
      }
    }
    _timer.reset();
    _index = max(_index, 0);
    _offsetTime = currentTime = times[_index].startTime;
  }

  @override
  Future<void> loadDB() async {
    times.clear();
    _timer.reset();

    // データベースを読み込んだ後即計測開始
    final titleTbl = await DbAccess.a.getTitle(_titleid);
    title = titleTbl.sTitle;
    final wTimes = await DbAccess.a.getTimes(_titleid);
    int sum = 0;
    times.addAll(List.generate(wTimes.length, (i) {
      final result = ControlItem(wTimes[i], sum);
      sum += wTimes[i].iTime;
      return result;
    }));
    for (final time in times) {
      totalTime += time.iTime;
    }

    _index = 0;
    _offsetTime = 0;
    currentTime = 0;
    start();
  }
}
