import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stacktimers/view/timercontrolpage.dart';
import 'package:stacktimers/view/timereditpage.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';
import 'package:stacktimers/vm/timereditvm.dart';
import 'package:flutter_picker/flutter_picker.dart';

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
  /// (99:59)という設定が可能なもので、[initial]は初期値でreturnで変更値が返る。
  Future<int> getTime(int initial) async {
    var values = <int>[
      initial.clamp(0, 5999) ~/ 600 % 10,
      initial.clamp(0, 5999) ~/ 60 % 10,
      initial.clamp(0, 5999) ~/ 10 % 6,
      initial.clamp(0, 5999) % 10
    ];
    final picker = Picker(
        adapter: NumberPickerAdapter(data: [
          NumberPickerColumn(
            initValue: values[0],
            begin: 0,
            end: 9,
          ),
          NumberPickerColumn(
            initValue: values[1],
            begin: 0,
            end: 9,
          ),
          NumberPickerColumn(
            initValue: values[2],
            begin: 0,
            end: 5,
          ),
          NumberPickerColumn(
            initValue: values[3],
            begin: 0,
            end: 9,
          ),
        ]),
        delimiter: [
          PickerDelimiter(
              column: 2,
              child: Container(
                width: 16.0,
                alignment: Alignment.center,
                child: const Text(':',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                color: Colors.white,
              ))
        ],
        onConfirm: (Picker picker, List value) {
          for (int i = 0; i < picker.getSelectedValues().length; i++) {
            values[i] = picker.getSelectedValues()[i];
          }
        });
    await picker.showModal(Get.context!);
    return Future.value(
        values[0] * 600 + values[1] * 60 + values[2] * 10 + values[3]);
  }

  /// 発生時間設定ダイアログの表示
  ///
  /// [initial]は初期値で単位はミリ秒で、このダイアログで取得するのは0.1～9.9秒。
  /// そのため、1/100の値にする。
  Future<int> getDuration(int initial) async {
    final f = NumberFormat("0.0");
    int changed = initial ~/ 100;
    final picker = Picker(
        adapter: NumberPickerAdapter(data: [
          NumberPickerColumn(
            initValue: changed,
            begin: 1,
            end: 99,
            onFormatValue: (value) => f.format(value / 10),
          ),
        ]),
        onConfirm: (Picker picker, List value) {
          changed = picker.getSelectedValues()[0];
        });
    await picker.showModal(Get.context!);
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
