import 'package:flutter/material.dart';
import 'package:stacktimers/view/viewcontrol.dart';

class MockViewControl implements ViewControl {
  String func = "";
  @override
  Future<Color> getColor(Color initial) {
    func = "getColor $initial";
    return Future.value(Colors.blue);
  }

  @override
  Future<int> getDuration(int initial) {
    func = "getDuration $initial";
    return Future.value(initial + 1);
  }

  @override
  Future<int> getTime(int initial) {
    func = "getTime $initial";
    return Future.value(initial + 1);
  }

  @override
  Future<void> toControl(int titleid) async {
    func = "toControl $titleid";
  }

  @override
  Future<void> toEdit(int titleid) async {
    func = "toEdit $titleid";
  }

  @override
  Future<void> playNotification(bool isStart, int iDuration) async {
    func = "playNotification $isStart $iDuration";
  }
}
