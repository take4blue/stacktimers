import 'package:flutter_test/flutter_test.dart';
import 'package:stacktimers/model/titletable.dart';

void main() {
  test("construct1", () {
    final result = TitleTable();
    expect(result.id, -1);
    expect(result.sTitle.isEmpty, true);
  });
  test("construct2", () {
    final result = TitleTable(id: 10, sTitle: "hoge");
    expect(result.id, 10);
    expect(result.sTitle, "hoge");
  });

  test("toMap", () {
    final target = TitleTable(id: 10, sTitle: "hoge");
    final result = target.toMap();
    expect(result.length, 2);
    expect(result["id"], 10);
    expect(result["sTitle"], "hoge");
  });

  test("toSqlMap", () {
    final target = TitleTable(id: 10, sTitle: "hoge");
    final result = target.toSqlMap();
    expect(result.length, 1);
    expect(result["sTitle"], "hoge");
  });

  test("fromMap", () {
    Map<String, dynamic> target = {"id": 10, "sTitle": "hoge"};

    final result = TitleTable.fromMap(target);
    expect(result.id, 10);
    expect(result.sTitle, "hoge");
  });
}
