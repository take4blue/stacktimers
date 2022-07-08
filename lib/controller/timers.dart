import 'dart:async';
import 'dart:math';

enum WithinType {
  /// 範囲外
  outer,

  /// 範囲内
  inner,

  /// [endTime]に一致
  last
}

/// 1タイム情報
///
/// ControlItemから作成する
class TimeItem {
  TimeItem(this.iTime, this.iDuration, this._offset);

  /// 最終時間を求めるためのオフセット量
  final int _offset;

  /// [TimeTable].[iTime]の取得
  final int iTime;

  /// [TimeTable].[iDuration]の取得
  final int iDuration;

  /// このタイマーの開始時刻
  int get startTime => _offset;

  /// このタイマーの最終時間
  int get endTime => _offset + iTime;

  /// [time]が[startTime]～[endTime]の間かどうか
  WithinType within(int time) {
    return startTime <= time && time < endTime
        ? WithinType.inner
        : time == endTime
            ? WithinType.last
            : WithinType.outer;
  }
}

/// [Timers]で発生するイベント処理用のインターフェース
abstract class ITiemrsAction {
  /// タイマーが指定時間になった
  ///
  /// [item]はバックから送信されたものはnullが入るのでフロント側はindexの元となる
  /// 情報を持っておく必要あり。Timersから呼び出される場合はnull以外。
  void reach(int index, TimeItem? item);

  /// 時間の更新
  ///
  /// [currentTime]:現在時刻。
  /// [index]:現在処理している[TimeTable]の位置。
  /// [item]はバックから送信されたものはnullが入るのでフロント側はindexの元となる
  /// 情報を持っておく必要あり。Timersから呼び出される場合はnull以外。
  void updateTime(int currentTime, int index, TimeItem? item);
}

/// タイマー制御本体部分
class Timers {
  /// TimeTableのtoMapのListからTimersを生成する。
  Timers.fromMap(
    List<Map<String, dynamic>> mapLists, {
    ITiemrsAction? action,
  }) : _action = action {
    totalTime = 0;
    _times.addAll(List.generate(mapLists.length, (i) {
      final item =
          TimeItem(mapLists[i]['iTime'], mapLists[i]['iDuration'], totalTime);
      totalTime += item.iTime;
      return item;
    }));
  }

  ITiemrsAction? _action;

  /// アクション設定
  set action(ITiemrsAction val) {
    _action = val;
  }

  /// 時間情報
  final _times = <TimeItem>[];

  /// 総時間
  late int totalTime;

  /// prev/nextで移動した際のオフセット時間
  int _offsetTime = 0;

  /// ストップウォッチ情報
  final _timer = Stopwatch();

  /// 現在の時間情報の場所
  int _index = 0;

  /// 表示用の現在の経過時間。
  int _currentTime = 0;

  /// 現在の時刻
  int get currentTime => _currentTime;

  /// 動作中かどうか
  bool get isRunning => _timer.isRunning;

  /// 現在時刻更新
  set currentTime(int value) {
    _currentTime = value;
    _action?.updateTime(_currentTime, _index, _times[_index]);
  }

  /// 現在の経過時間
  int get _elapsed => _offsetTime + _timer.elapsed.inSeconds;

  /// タイマー
  Timer? _timerInterrupt;

  /// 時間監視の[_times]毎の処理
  ///
  /// for/switchの組み合わせでswitchからの大ブレイクをするため関数化してある
  bool _check1(int now) {
    for (int i = _index; i < _times.length; i++) {
      switch (_times[i].within(now)) {
        case WithinType.outer:
          // 何もしない.
          break;
        case WithinType.inner:
          // 何もしない
          break;
        case WithinType.last:
          // 音を鳴らす
          _action?.reach(i, _times[i]);
          _index = i;
          return true;
      }
    }
    return false;
  }

  /// 次のタイマーの設定関数
  /// 秒の桁上がり時に処理ができるように、残りミリ秒+αで
  /// 割り込みが発生するように時間調整をする
  void _nextTimerSet() {
    final duration = 1050 - (_timer.elapsedMilliseconds % 1000);
    _timerInterrupt = Timer(Duration(milliseconds: duration), _check);
  }

  /// 時間監視処理
  ///
  /// タイマーストップ中は何もしないようにする。（割り込み継続も）
  void _check() {
    if (_timer.isRunning) {
      final now = _elapsed;
      if (_currentTime < now) {
        if (_check1(now)) {
          _index = min(_index + 1, _times.length - 1);
        }
        currentTime = now;
      }
      if (now != totalTime) {
        // 最終時間に至ってなければタイマー割り込み継続
        _nextTimerSet();
      } else if (now >= totalTime) {
        pause();
      }
    }
  }

  void start() {
    if (_currentTime == totalTime) {
      // すでに完了していた場合、再スタートする。
      _timer.reset();
      _index = 0;
      _offsetTime = 0;
      currentTime = 0;
    }
    _timer.start();
    _nextTimerSet();
  }

  void pause() {
    _timer.stop();
    _timerInterrupt?.cancel();
    _timerInterrupt = null;
  }

  void next() {
    final now = _elapsed;
    for (int i = _index; i < _times.length - 1; i++) {
      if (now < _times[i].endTime) {
        _index = i + 1;
        _timer.reset();
        _offsetTime = currentTime = _times[_index].startTime;
        break;
      }
    }
  }

  void prev() {
    final now = _elapsed;
    for (; _index >= 0; _index--) {
      if (_times[_index].startTime == now ||
          _times[_index].startTime + 1 == now) {
        continue;
      }
      if (_times[_index].startTime < now) {
        break;
      }
    }
    _timer.reset();
    _index = max(_index, 0);
    _offsetTime = currentTime = _times[_index].startTime;
  }
}
