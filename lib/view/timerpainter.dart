import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stacktimers/vm/timercontrolvm.dart';

/// タイマー表示の外周部分を行うためのペイントクラス
class TimerOutPainter extends CustomPainter {
  /// 円の外周外接のオフセット比率
  static const offset = 0.05;

  /// ドーナツ円の幅比率
  static const width = 0.15;

  /// 外周幅(絶対値)
  static const strokeWidth = 3.0;

  final vm = Get.find<TimerControlVM>();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset((size / 2).width, (size / 2).height);
    final base = min(size.width, size.height);
    final outerRect =
        Rect.fromCircle(center: center, radius: base * (0.5 - offset));
    final innterRect =
        Rect.fromCircle(center: center, radius: base * (0.5 - offset - width));

    if (vm.times.length > 1) {
      double angle = (pi * 2) / vm.totalTime;

      /// 開始角度
      double start = 0.0;
      for (final time in vm.times) {
        final delta = time.iTime * angle;

        final path = Path();
        path.addArc(outerRect, (start + delta / 2) - (pi / 2), (delta / 2));
        path.arcTo(innterRect, (start + delta) - (pi / 2), -delta, false);
        path.arcTo(outerRect, (start) - (pi / 2), (delta / 2), false);
        path.close();
        canvas.drawPath(
            path,
            Paint()
              ..color = time.iColor
              ..style = PaintingStyle.fill);
        canvas.drawPath(
            path,
            Paint()
              ..color = Colors.black
              ..strokeWidth = strokeWidth
              ..style = PaintingStyle.stroke);

        start += delta;
      }
    } else if (vm.times.length == 1) {
      canvas.drawArc(
          outerRect,
          0,
          pi * 2,
          false,
          Paint()
            ..color = vm.times[0].iColor
            ..style = PaintingStyle.fill);
      canvas.drawArc(
          outerRect,
          0,
          pi * 2,
          false,
          Paint()
            ..color = Colors.black
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke);
      canvas.drawLine(
          Offset(center.dx, base * offset),
          Offset(center.dx, base * (offset + width)),
          Paint()
            ..color = Colors.black
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke);
      canvas.drawArc(
          innterRect,
          0,
          pi * 2,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
      canvas.drawArc(
          innterRect,
          0,
          pi * 2,
          false,
          Paint()
            ..color = Colors.black
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// タイマー表示の内周部分を行うためのペイントクラス
class TimerInPainter extends CustomPainter {
  TimerInPainter({Listenable? repaint}) : super(repaint: repaint);

  /// 円の外周の半径比率
  static const radius = 0.21;

  /// 外周幅(絶対値)
  static const strokeWidth = 3.0;

  final vm = Get.find<TimerControlVM>();

  int prevTime = 0;

  @override
  void paint(Canvas canvas, Size size) {
    prevTime = vm.currentTime;
    if (prevTime == 0) {
      return;
    }
    final center = Offset((size / 2).width, (size / 2).height);
    final base = min(size.width, size.height);
    final rect = Rect.fromCircle(center: center, radius: base * (0.5 - radius));

    double angle = (pi * 2) / vm.totalTime;

    /// 開始角度
    double start = 0.0;
    int remainTime = min(prevTime, vm.totalTime);
    for (final time in vm.times) {
      final delta = min(time.iTime, remainTime) * angle;

      // 扇形を描画する。
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(rect, start - (pi / 2), delta, false);
      path.lineTo(center.dx, center.dy);
      path.close();
      canvas.drawPath(
          path,
          Paint()
            ..color = time.iColor
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke);

      start += delta;
      remainTime -= time.iTime;
      if (remainTime <= 0) {
        // 残り時間が無くなったらこれ以上描画しない
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return prevTime != vm.currentTime;
  }
}
