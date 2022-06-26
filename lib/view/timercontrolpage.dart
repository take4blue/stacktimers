import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stacktimers/view/timerpainter.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';

class TimerControlPage extends StatelessWidget {
  const TimerControlPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerControlVM>(
      id: "all", // TopPageを更新鍵
      builder: (vm) => FutureBuilder(
          future: vm.loader(),
          builder: (BuildContext context, AsyncSnapshot<void> snap) {
            final size = min(MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height / 2);
            return WillPopScope(
                onWillPop: vm.closePage,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(vm.title),
                  ),
                  body: Column(children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: GestureDetector(
                        key: const Key("tap"), // テスト用
                        onTap: vm.toggleRunnning,
                        child: CustomPaint(
                          painter: TimerOutPainter(),
                          foregroundPainter: TimerInPainter(repaint: vm),
                        ),
                      ),
                    ),
                    const Divider(),
                    const ControlIcon(),
                    const Divider(),
                    const DisplayTimer(),
                  ]),
                ));
          }),
    );
  }
}

/// タイマーの制御アイコン部分
class ControlIcon extends StatelessWidget {
  const ControlIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerControlVM>(
        id: "icons", // アイコン部分の更新鍵
        builder: (vm) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: vm.prev, icon: const Icon(Icons.skip_previous)),
              vm.isRunning
                  ? IconButton(
                      onPressed: vm.pause, icon: const Icon(Icons.pause))
                  : IconButton(
                      onPressed: vm.start, icon: const Icon(Icons.play_arrow)),
              IconButton(onPressed: vm.next, icon: const Icon(Icons.skip_next))
            ],
          );
        });
  }
}

/// タイマー経過表示部分
class DisplayTimer extends StatelessWidget {
  const DisplayTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerControlVM>(
        id: "time", // テキスト部分の更新鍵
        builder: (vm) {
          return DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.headline4,
            child: Table(
              columnWidths: const {1: FixedColumnWidth(15)},
              children: [
                TableRow(
                  children: [
                    Text(
                      "t2TextLap".tr,
                      textAlign: TextAlign.right,
                    ),
                    const Text(
                      ":",
                      textAlign: TextAlign.center,
                    ),
                    Text(vm.lapRemain)
                  ],
                ),
                TableRow(
                  children: [
                    Text(
                      "t2TextTotal".tr,
                      textAlign: TextAlign.right,
                    ),
                    const Text(
                      ":",
                      textAlign: TextAlign.center,
                    ),
                    Text(vm.totalRemain),
                  ],
                )
              ],
            ),
          );
        });
  }
}
