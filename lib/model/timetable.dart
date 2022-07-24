import 'package:flutter/material.dart';
import 'package:stacktimers/model/titletable.dart';

/// TimeTableの1レコードの情報
class TimeTable {
  TimeTable(
      {int? id,
      required this.titleid,
      int? iNo,
      int? iTime,
      int? iDuration,
      Color? iColor})
      : id = id ?? -1,
        iNo = iNo ?? 0,
        iTime = iTime ?? 0,
        iDuration = iDuration ?? 3000,
        iColor = iColor ?? _defaultColor(iNo ?? 0);

  /// 一意な番号(自動採番)
  ///
  /// メンテナンスはdbhelper内で行う。
  int id;

  /// TitleTable-idを示す
  ///
  /// 必須項目
  final int titleid;

  /// 同一titleid内での順序(0オリジン)
  int iNo;

  /// タイマー時間(単位:秒)
  int iTime;

  /// 警告音の発音時間(単位:ミリ秒)
  int iDuration;

  /// 色
  Color iColor;

  /// 中身をmap形式に変換
  Map<String, dynamic> toMap() {
    // iColorはint形式に変換する
    return {
      "id": id,
      "titleid": titleid,
      "iNo": iNo,
      "iTime": iTime,
      "iDuration": iDuration,
      "iColor": iColor.value,
    };
  }

  /// 中身をSQLデータベース書き出し用map形式に変換
  Map<String, dynamic> toSqlMap() {
    // iColorはint形式に変換する
    return {
      "titleid": titleid,
      "iNo": iNo,
      "iTime": iTime,
      "iDuration": iDuration,
      "iColor": iColor.value,
    };
  }

  /// Mapからのデータ生成
  factory TimeTable.fromMap(Map<String, dynamic> map) => TimeTable(
      id: map["id"],
      titleid: map["titleid"],
      iNo: map["iNo"],
      iTime: map["iTime"],
      iDuration: map["iDuration"],
      iColor: Color(map["iColor"]));

  /// TitleTableをベースに生成
  factory TimeTable.fromTitleTable(
          {int? id,
          required TitleTable title,
          int? iNo,
          int? iTime,
          int? iDuration,
          Color? iColor}) =>
      TimeTable(
          id: id,
          titleid: title.id,
          iNo: iNo,
          iTime: iTime,
          iDuration: iDuration,
          iColor: iColor);

  /// デフォルトで利用可能な色
  static const _defaultColors = <Color>[
    Color(0xFF22B14C),
    Color(0xFFFFF200),
    Color(0xFFFF7F27),
    Color(0xFF99D9EA),
    Color(0xFF7092BE),
    Color(0xFFC8BFE7),
    Color(0xFFC3C3C3),
  ];

  /// iNoからデフォルト色を自動生成する
  static Color _defaultColor(int iNo) {
    return _defaultColors[iNo % _defaultColors.length];
  }

  /// 99:59という時間表記の情報を作成する。
  static String formatter(int value) {
    final time = value.clamp(0, 5999);
    return "${time ~/ 600 % 10}"
        "${time ~/ 60 % 10}:"
        "${time ~/ 10 % 6}"
        "${time % 10}";
  }
}
