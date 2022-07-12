import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacktimers/model/timetable.dart';

import 'asyncservice.dart';
import 'timers.dart';

// 以下はコマンド等で使用するキーワード
const _kMCommand = "cmd"; // サーバーへのコマンド送付のメソッド名
const _kTFunction = "func"; // サーバーへの関数のタグ名
const _kTResult = "result"; // サーバーからのリターンのタグ名

// 以下はサーバーで実行する関数名(_kMCommandでタグ_kTFunctionに設定)
const _kFStopService = "stopService";
const _kFStart = "start";
const _kFPause = "pause";
const _kFNext = "next";
const _kFPrev = "prev";
const _kFIsRunning = "running"; // isRunning確認用及びそのリターンのmethod名

// 以下はクライアント側で実行する関数名
// (サーバーからは_kMCommandでタグ_kTFunctionに設定)
const _kFUpdateTime = "updateTime";
const _kFReach = "reach";

// SharedPreferencesのキーワード
const _kSValue = "data"; // TimeTableのデータ格納用

/// バックグラウンドで動く[Timers]からイベント受けてそれをフォアグラウンド側に
/// 送るための処理クラス
class BackTimerAction implements ITiemrsAction {
  BackTimerAction(this.val);
  final ServiceInstance val;

  @override
  void reach(int index, TimeItem? item) {
    val.invoke(_kMCommand, {_kTFunction: _kFReach, "index": index});
  }

  @override
  void updateTime(int currentTime, int index, TimeItem? item) {
    val.invoke(_kMCommand, {
      _kTFunction: _kFUpdateTime,
      "currentTime": currentTime,
      "index": index
    });
  }
}

/// 時間になったらNotificationを発生させる処理。
/// アプリがバックグラウンドもしくは存在しない場合こちらを使用する。
class BackTimerNotificationAction extends BackTimerAction {
  BackTimerNotificationAction(ServiceInstance val) : super(val);

  late FlutterLocalNotificationsPlugin _plugin;

  /// Notificationの初期処理
  Future<void> initialize() async {
    // 通知の初期処理
    _plugin = FlutterLocalNotificationsPlugin();
    const forAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const forIOS = IOSInitializationSettings();
    const forMacOS = MacOSInitializationSettings();
    const settings = InitializationSettings(
        android: forAndroid, iOS: forIOS, macOS: forMacOS);
    await _plugin.initialize(settings);
  }

  /// 通知処理
  Future<void> _showNotification() async {
    const androidSpec = AndroidNotificationDetails(
        'your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    const spec = NotificationDetails(android: androidSpec);
    await _plugin.show(0, 'plain title', 'plain body', spec, payload: 'item x');
  }

  @override
  void reach(int index, TimeItem? item) {
    super.reach(index, item);
    _showNotification();
  }
}

/// バックグラウンドで行うタイマーカウントダウン処理
class BackgroundTimer {
  /// 保存用のキーワード
  static const kTimes = "times";

  late FlutterBackgroundService _service;

  /// フロント側のタイマーアクション処理
  ITiemrsAction? action;

  /// 初期化(main側で呼び出すもの)
  FutureOr<void> initialize() async {
    if (Platform.isWindows) {
      // Windows用の初期設定
      AsyncBackgroundService.registerWith();
    }

    // サービス初期化
    _service = FlutterBackgroundService();
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundFunc,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        onForeground: backgroundFunc,
        autoStart: false,
        onBackground: (service) {
          WidgetsFlutterBinding.ensureInitialized();
          return true;
        },
      ),
    );

    /// サーバーからの受信処理
    _service.on(_kMCommand).listen((event) {
      switch (event![_kTFunction]) {
        case _kFReach:
          action?.reach(event["index"], null);
          break;
        case _kFUpdateTime:
          action?.updateTime(event["currentTime"], event["index"], null);
          break;
      }
    });
  }

  /// バックグラウンドの処理の開始
  Future<void> execute(List<TimeTable> times) async {
    // timerAction構築用のデータ送信
    final value =
        json.encode(List.generate(times.length, (i) => times[i].toMap()));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSValue, value);

    // Back側からの通信でFront側のアクション呼び出し
    await _service.startService();
  }

  /// バックグラウンドの処理を停止する。
  void kill() => _service.isRunning().then((value) {
        if (value) {
          _service.invoke(_kMCommand, {_kTFunction: _kFStopService});
        }
      });

  /// [Timers.start]を呼び出す。
  void start() => _service.isRunning().then((value) {
        if (value) {
          _service.invoke(_kMCommand, {_kTFunction: _kFStart});
        }
      });

  /// [Timers.pause]を呼び出す。
  void pause() => _service.isRunning().then((value) {
        if (value) {
          _service.invoke(_kMCommand, {_kTFunction: _kFPause});
        }
      });

  /// [Timers.next]を呼び出す。
  void next() => _service.isRunning().then((value) {
        if (value) {
          _service.invoke(_kMCommand, {_kTFunction: _kFNext});
        }
      });

  /// [Timers.prev]を呼び出す。
  void prev() => _service.isRunning().then((value) {
        if (value) {
          _service.invoke(_kMCommand, {_kTFunction: _kFPrev});
        }
      });

  /// [Timers.isRunning]を呼び出す
  Future<bool> isRunning() async {
    if (await _service.isRunning()) {
      final ret = _service.on(_kFIsRunning).timeout(const Duration(seconds: 1));
      _service.invoke(_kMCommand, {_kTFunction: _kFIsRunning});
      try {
        final result = await ret.first;
        if (result != null && result.isNotEmpty && result[_kTResult] != null) {
          return result[_kTResult];
        }
      } catch (e) {
        debugPrint("isRunning False");
        return false;
      }
    }
    return false;
  }

  /// バックグラウンドで動く関数
  ///
  /// これとのデータ受け渡しは[_service]経由で行う。
  static void backgroundFunc(ServiceInstance val) async {
    if (ServiceInstance is! AsyncService) {
      DartPluginRegistrant.ensureInitialized();
    }
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_kSValue);
    if (data == null) {
      val.stopSelf();
      prefs.clear();
    }

    // タイマーオブジェクトの作成
    final rMap = (json.decode(data!) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final action = BackTimerAction(val);
    final timerAction = Timers.fromMap(rMap, action: action);

    // タイマー操作関数(クライアント側からの通信受信処理)
    val.on(_kMCommand).listen((event) {
      switch (event![_kTFunction]) {
        case _kFStart:
          timerAction.start();
          break;
        case _kFPause:
          timerAction.pause();
          break;
        case _kFNext:
          timerAction.next();
          break;
        case _kFPrev:
          timerAction.prev();
          break;
        case _kFIsRunning:
          val.invoke(_kFIsRunning, {_kTResult: timerAction.isRunning});
          break;
        case _kFStopService:
          // バックグラウンド機能停止コマンド
          timerAction.pause();
          val.stopSelf();
          prefs.clear();
          break;
      }
    });

    timerAction.start();
  }
}
