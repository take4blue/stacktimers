import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:gui_box/gui_box.dart';
import 'package:intl/intl.dart';
import 'package:stacktimers/view/timercontrolpage.dart';
import 'package:stacktimers/view/timereditpage.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';
import 'package:stacktimers/vm/timereditvm.dart';

/// 展開させるためのビューを管理するためのクラス。
///
/// ViewModeのテスト時にモック生成のために用意
class ViewControl {
  ViewControl({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey;

  static ViewControl get a => Get.find();

  final GlobalKey<NavigatorState>? _navigatorKey;

  /// 計測画面の表示
  Future<void> toControl(int titleid) async {
    await Get.to(() => const TimerControlPage(),
        binding: BindingsBuilder((() =>
            Get.lazyPut<TimerControlVM>(() => TimerControlVM(titleid)))));
  }

  /// 編集画面の表示
  Future<void> toEdit(int titleid) async {
    await Get.to(() => const TimerEditPage(),
        binding: BindingsBuilder(
            (() => Get.lazyPut<TimerEditVM>(() => TimerEditVM(titleid)))));
  }

  /// 色選択ダイアログの表示
  Future<Color> getColor(Color initial) async {
    Color changed = initial;
    await Get.dialog<bool>(
        AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initial,
              onColorChanged: (value) {
                changed = value;
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
        navigatorKey: _navigatorKey);
    return Future.value(changed);
  }

  /// 時間設定ダイアログの表示
  ///
  /// [initial]は初期値
  Future<int> getTime(int initial) async {
    int changed = initial;
    await _showDialog(TimeSelector(
      initial,
      (time) => changed = time,
    ));
    return Future.value(changed);
  }

  /// 発生時間設定ダイアログの表示
  ///
  /// [initial]は初期値で単位はミリ秒で、このダイアログで取得するのは0.1～9.9秒。
  /// そのため、1/100の値にする。
  Future<int> getDuration(int initial) async {
    final f = NumberFormat("0.0");
    int changed = initial ~/ 100;
    await _showDialog(NumberSelector(
      1,
      99,
      initValue: changed,
      onValueItemChanged: (time) => changed = time,
      formatter: (value) => f.format(value / 10),
    ));
    return Future.value(changed * 100);
  }

  /// Cupertinoなモーダルダイアログの表示用共通関数
  Future<void> _showDialog(Widget child) {
    return showCupertinoModalPopup<void>(
        context: Get.context!,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: child,
              ),
            ));
  }

  Timer? _timerInterrupt;

  /// 発音
  Future<void> playNotification(bool isStart, int iDuration) async {
    if (kIsWeb) {
      return;
    }
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    if (isStart) {
      _timerInterrupt?.cancel();
      _timerInterrupt = Timer(
          Duration(milliseconds: iDuration), () => playNotification(false, 0));
      return FlutterRingtonePlayer.playNotification(looping: true);
    } else {
      if (iDuration != 0) {
        _timerInterrupt?.cancel();
        _timerInterrupt = null;
      }
      return FlutterRingtonePlayer.stop();
    }
  }
}
