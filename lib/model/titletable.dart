/// TitleTableの1レコード情報
class TitleTable {
  TitleTable({int? id, String? sTitle})
      : id = id ?? -1,
        sTitle = sTitle ?? "";

  /// 一意な番号(自動採番)
  ///
  /// メンテナンスはdbhelper内で行う。
  int id;

  /// タイトル名
  String sTitle;

  /// 中身をmap形式に変換
  Map<String, dynamic> toMap() => {"id": id, "sTitle": sTitle};

  /// 中身をSQLデータベース書き出し用map形式に変換
  Map<String, dynamic> toSqlMap() => {"sTitle": sTitle};

  /// Mapからのデータ生成
  factory TitleTable.fromMap(Map<String, dynamic> map) =>
      TitleTable(id: map["id"], sTitle: map["sTitle"]);
}
