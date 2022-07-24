import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';

void main() {
  test("construct1", () {
    final result = TimeTable(titleid: 1);
    expect(result.id, -1);
    expect(result.titleid, 1);
    expect(result.iNo, 0);
    expect(result.iTime, 0);
    expect(result.iDuration, 3000);
    expect(result.iColor, const Color(0xFF22B14C));
  });
  test("construct2", () {
    final result = TimeTable(
        id: 10,
        titleid: 1,
        iNo: 1,
        iTime: 2,
        iDuration: 3,
        iColor: Colors.white);
    expect(result.id, 10);
    expect(result.titleid, 1);
    expect(result.iNo, 1);
    expect(result.iTime, 2);
    expect(result.iDuration, 3);
    expect(result.iColor, Colors.white);
  });
  test("fromTitleTable", () {
    final table = TitleTable(id: 20);
    final result = TimeTable.fromTitleTable(
        id: 10,
        title: table,
        iNo: 1,
        iTime: 2,
        iDuration: 3,
        iColor: Colors.white);
    expect(result.id, 10);
    expect(result.titleid, 20);
    expect(result.iNo, 1);
    expect(result.iTime, 2);
    expect(result.iDuration, 3);
    expect(result.iColor, Colors.white);
  });

  test("color_decision", () {
    var result = TimeTable(
      titleid: 1,
      iNo: 1,
    );
    expect(result.iColor, const Color(0xFFFFF200));
    result = TimeTable(
      titleid: 1,
      iNo: 2,
    );
    expect(result.iColor, const Color(0xFFFF7F27));
    result = TimeTable(
      titleid: 1,
      iNo: 3,
    );
    expect(result.iColor, const Color(0xFF99D9EA));
    result = TimeTable(
      titleid: 1,
      iNo: 4,
    );
    expect(result.iColor, const Color(0xFF7092BE));
    result = TimeTable(
      titleid: 1,
      iNo: 5,
    );
    expect(result.iColor, const Color(0xFFC8BFE7));
    result = TimeTable(
      titleid: 1,
      iNo: 6,
    );
    expect(result.iColor, const Color(0xFFC3C3C3));
    result = TimeTable(
      titleid: 1,
      iNo: 7,
    );
    expect(result.iColor, const Color(0xFF22B14C));
  });

  test("toMap", () {
    final target = TimeTable(
        id: 10,
        titleid: 1,
        iNo: 1,
        iTime: 2,
        iDuration: 3,
        iColor: Colors.white);
    final result = target.toMap();
    expect(result.length, 6);
    expect(result["id"], 10);
    expect(result["titleid"], 1);
    expect(result["iNo"], 1);
    expect(result["iTime"], 2);
    expect(result["iDuration"], 3);
    expect(result["iColor"], Colors.white.value);
  });

  test("toSqlMap", () {
    final target = TimeTable(
        id: 10,
        titleid: 1,
        iNo: 1,
        iTime: 2,
        iDuration: 3,
        iColor: Colors.white);
    final result = target.toSqlMap();
    expect(result.length, 5);
    expect(result["titleid"], 1);
    expect(result["iNo"], 1);
    expect(result["iTime"], 2);
    expect(result["iDuration"], 3);
    expect(result["iColor"], Colors.white.value);
  });

  test("fromMap", () {
    Map<String, dynamic> target = {
      "id": 10,
      "titleid": 1,
      "iNo": 1,
      "iTime": 2,
      "iDuration": 3,
      "iColor": Colors.white.value
    };

    final result = TimeTable.fromMap(target);
    expect(result.id, 10);
    expect(result.titleid, 1);
    expect(result.iNo, 1);
    expect(result.iTime, 2);
    expect(result.iDuration, 3);
    expect(result.iColor, Colors.white);
  });
  test("formatter", () {
    expect(TimeTable.formatter(0), "00:00");
    expect(TimeTable.formatter(754), "12:34");
    expect(TimeTable.formatter(-1), "00:00");
    expect(TimeTable.formatter(5999), "99:59");
    expect(TimeTable.formatter(6000), "99:59");
  });
}
