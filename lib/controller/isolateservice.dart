import 'dart:async';
import 'dart:isolate';

import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';

// 通信用のメッセージ類
const _kMethod = 'method';
const _kArgs = 'args';
const _kStopSelf = 'stopself';
const _kIsolateDone = 'isolatedone';
const _kSendPort = "sendport";

class IsolateObservable implements Observable {
  IsolateObservable(this._port, this._recv, this._send);

  final ReceivePort _port;
  final Stream _recv;
  final SendPort _send;

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    _send.send({_kMethod: method, _kArgs: args});
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    return _recv.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data[_kMethod] == method) {
            sink.add(data[_kArgs]);
          }
        },
      ),
    );
  }

  void close() {
    _port.close();
  }
}

/// 呼び出し側の処理
class IsolateBackgroundService extends FlutterBackgroundServicePlatform {
  /// Registers this class as the default instance of
  /// [FlutterBackgroundServicePlatform].
  static void registerWith() {
    FlutterBackgroundServicePlatform.instance = IsolateBackgroundService();
  }

  IsolateBackgroundService() {
    _recv = _recvPort.asBroadcastStream();
  }

  /// スレッドで動作させる処理
  Function(ServiceInstance service)? _onStart;

  /// 通信用のポート
  final ReceivePort _recvPort = ReceivePort();

  /// [on]で[listen]させるための[Stream]
  late Stream _recv;

  /// 情報送信用
  SendPort? _send;

  /// スレッドが動作中かどうかのフラグ
  bool _isRunning = false;

  @override
  Future<bool> configure(
      {required IosConfiguration iosConfiguration,
      required AndroidConfiguration androidConfiguration}) {
    _onStart = androidConfiguration.onStart;
    return Future.value(true);
  }

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    _send?.send({_kMethod: method, _kArgs: args});
  }

  @override
  Future<bool> isServiceRunning() {
    return Future.value(_isRunning);
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    return _recv.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data[_kMethod] == method) {
            sink.add(data[_kArgs]);
          }
        },
      ),
    );
  }

  @override
  Future<bool> start() async {
    if (_onStart != null) {
      _isRunning = true;
      // 以下第2引数を_recvPort.sendPortだけにすると
      // Illegal argument in isolate message: (object is a ReceivePort))
      // が発生するが、Listにすると出なかった。不思議。
      await Isolate.spawn(_isolateFunc, [_recvPort.sendPort, _onStart]);
      late StreamSubscription<Map<String, dynamic>?> sub1;
      sub1 = on(_kIsolateDone).listen((_) {
        _isRunning = false;
        _send = null;
        sub1.cancel();
      });
      late StreamSubscription<Map<String, dynamic>?> sub2;
      sub2 = on(_kSendPort).listen((data) {
        _send = data?["port"];
        sub2.cancel();
      });
      return true;
    } else {
      return false;
    }
  }

  /// 別スレッド側の処理。
  static Future<void> _isolateFunc(List<dynamic> args) async {
    final send = args[0];
    final recv = ReceivePort();
    send.send({
      _kMethod: _kSendPort,
      _kArgs: {"port": recv.sendPort}
    });
    final serivce = IsolateService(recv, send);
    serivce.on(_kStopSelf).listen(
          (event) => serivce.stopSelf(),
        );
    args[1](serivce);
  }

  /// 終了時のクローズ処理
  void close() {
    _recvPort.close();
  }
}

/// サービス側の処理
class IsolateService extends ServiceInstance {
  IsolateService(ReceivePort recv, SendPort send)
      : _observable = IsolateObservable(recv, recv.asBroadcastStream(), send);

  final IsolateObservable _observable;

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    _observable.invoke(method, args);
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    return _observable.on(method);
  }

  @override
  Future<void> stopSelf() async {
    invoke(_kIsolateDone);
    Isolate.exit();
  }
}
