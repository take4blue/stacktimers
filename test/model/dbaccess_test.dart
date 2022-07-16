import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';

import '../testutil.dart';

void main() {
  int counter = 0;

  test("file create", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);
    Get.put<DbAccess>(target);
    expect((await File(target.fullPathName).exists()), true);
    final result = DbAccess.a;
    expect(result, target);
    await target.close();
    Get.reset();
  });
  test("titleTable", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);
    await target.db.insert(DbAccess.titleTable, {"sTitle": "Title"});
    final result = await target.db.query(DbAccess.titleTable);
    expect(result.length, 1);
    expect(result[0]["sTitle"], "Title");
    expect(result[0]["id"], 1);
    await target.close();
  });

  test("timeTable", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);
    await target.db.insert(DbAccess.timeTable, {
      "titleid": 1,
      "iNo": 2,
      "iTime": 3,
      "iDuration": 4,
      "iColor": 5,
    });
    final result = await target.db.query(DbAccess.timeTable);
    expect(result.length, 1);
    expect(result[0]["titleid"], 1);
    expect(result[0]["iNo"], 2);
    expect(result[0]["iTime"], 3);
    expect(result[0]["iDuration"], 4);
    expect(result[0]["iColor"], 5);
    expect(result[0]["id"], 1);
    await target.close();
  });

  test("delete", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);
    await target.db.insert(DbAccess.titleTable, {"sTitle": "Title"});
    await target.db.insert(DbAccess.timeTable, {
      "titleid": 1,
      "iNo": 2,
      "iTime": 3,
      "iDuration": 4,
      "iColor": 5,
    });
    await target.deleteAll();
    var result = await target.db.query(DbAccess.titleTable);
    expect(result.isEmpty, true);
    result = await target.db.query(DbAccess.timeTable);
    expect(result.isEmpty, true);
    await target.close();
  });

  test("getTitles", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 20; i++) {
      await target.db.insert(DbAccess.titleTable, {"sTitle": "title $i"});
    }

    final result = await target.getTitles;
    expect(result.length, 20);
    expect(result[0].sTitle, "title 0");
    expect(result[19].sTitle, "title 19");
    await target.close();
  });

  test("getTitle1", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 20; i++) {
      await target.db.insert(DbAccess.titleTable, {"sTitle": "title $i"});
    }

    var result = await target.getTitle(1);
    expect(result.sTitle, "title 0");
    result = await target.getTitle(5);
    expect(result.sTitle, "title 4");
    await target.close();
  });
  test("getTitle2", () async {
    // エラー処理対応
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 20; i++) {
      await target.db.insert(DbAccess.titleTable, {"sTitle": "title $i"});
    }

    var result = target.getTitle(0);
    final ret = await result
        .then<int>((value) => fail("error"))
        .onError((error, stackTrace) {
      expect(error, "Illegal id(0)");
      return 1;
    });
    expect(ret, 1);
    await target.close();
  });

  test("updateTitle1", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 20; i++) {
      await target.db.insert(DbAccess.titleTable, {"sTitle": "title $i"});
    }

    var data = TitleTable(id: 3, sTitle: "hoge");
    await target.updateTitle(data);
    var rMap = await target.db.query(DbAccess.titleTable, where: 'id = 3');
    expect(rMap.length, 1);
    expect(rMap[0]["sTitle"], "hoge");

    data = TitleTable(sTitle: "hehe");
    await target.updateTitle(data);
    expect(data.id, 21);
    rMap = await target.db.query(DbAccess.titleTable);
    expect(rMap.length, 21);
    expect(rMap[20]["sTitle"], "hehe");
    await target.close();
  });

  test("updateTitle2", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 20; i++) {
      await target.db.insert(DbAccess.titleTable, {"sTitle": "title $i"});
      for (int j = 0; j < 3; j++) {
        await target.db.insert(DbAccess.timeTable, {
          "titleid": i + 1,
          "iNo": j,
          "iTime": 30 + j,
          "iDuration": 40 + j,
          "iColor": 50 + j,
        });
      }
    }
    {
      final title = await target.db
          .query(DbAccess.titleTable, where: 'id = ?', whereArgs: [2]);
      expect(title.isNotEmpty, true);
      final times = await target.db
          .query(DbAccess.timeTable, where: "titleid = ?", whereArgs: [2]);
      expect(times.isNotEmpty, true);
    }
    await target.deleteTitle(2);
    {
      final title = await target.db
          .query(DbAccess.titleTable, where: 'id = ?', whereArgs: [2]);
      expect(title.isEmpty, true);
      final times = await target.db
          .query(DbAccess.timeTable, where: "titleid = ?", whereArgs: [2]);
      expect(times.isEmpty, true);
    }

    await target.deleteTitle(20);
    await target.deleteTitle(17);

    var data = TitleTable(sTitle: "hehe");
    await target.updateTitle(data);
    expect(data.id, 21);
    var rMap = await target.db.query(DbAccess.titleTable);
    expect(rMap.length, 18);
    expect(rMap[17]["sTitle"], "hehe");
    await target.close();
  });

  test("deleteTitle", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 20; i++) {
      await target.db.insert(DbAccess.titleTable, {"sTitle": "title $i"});
    }

    await target.deleteTitle(3);
    final result = await target.getTitles;
    expect(result.length, 19);
    expect(result[2].id, 4);
    await target.close();
  });

  test("getTimes", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 10; i++) {
      await target.db.insert(DbAccess.timeTable, {
        "titleid": (i % 3) + 1,
        "iNo": 20 - i,
        "iTime": 30 + i,
        "iDuration": 40 + i,
        "iColor": 50 + i,
      });
    }

    var result = await target.getTimes(2);
    expect(result.length, 3);
    expect(result[0].id, 8);
    expect(result[0].iNo, 13);
    expect(result[1].id, 5);
    expect(result[1].iNo, 16);
    expect(result[2].id, 2);
    expect(result[2].iNo, 19);
    await target.close();
  });

  test("updateTime", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 10; i++) {
      await target.db.insert(DbAccess.timeTable, {
        "titleid": (i % 3) + 1,
        "iNo": 20 - i,
        "iTime": 30 + i,
        "iDuration": 40 + i,
        "iColor": 50 + i,
      });
    }

    var data = TimeTable(
        id: 2,
        titleid: 7,
        iNo: 1,
        iTime: 1,
        iDuration: 1,
        iColor: Colors.black);
    await target.updateTime(data);
    var rMap = await target.db.query(DbAccess.timeTable, where: 'id = 2');
    expect(rMap.isNotEmpty, true);
    expect(rMap[0]["titleid"], 7);
    expect(rMap[0]["iNo"], 1);
    expect(rMap[0]["iTime"], 1);
    expect(rMap[0]["iDuration"], 1);
    expect(rMap[0]["iColor"], Colors.black.value);
    expect(rMap[0]["id"], 2);
    data = TimeTable(
        titleid: 2, iNo: 2, iTime: 2, iDuration: 2, iColor: Colors.white);
    await target.updateTime(data);
    expect(data.id, 11);
    rMap = await target.db.query(DbAccess.timeTable, where: 'id = 11');
    expect(rMap.isNotEmpty, true);
    expect(rMap[0]["titleid"], 2);
    expect(rMap[0]["iNo"], 2);
    expect(rMap[0]["iTime"], 2);
    expect(rMap[0]["iDuration"], 2);
    expect(rMap[0]["iColor"], Colors.white.value);
    expect(rMap[0]["id"], 11);

    await target.close();
  });

  test("updateTimes", () async {
    final fileName = "test${counter++}.db";
    await removeDbFile(fileName);
    final target = await DbAccess.create(fileName);

    for (int i = 0; i < 10; i++) {
      await target.db.insert(DbAccess.timeTable, {
        "titleid": (i % 3) + 1,
        "iNo": 20 - i,
        "iTime": 30 + i,
        "iDuration": 40 + i,
        "iColor": 50 + i,
      });
    }

    /// データの削除
    await target.updateTimes(<TimeTable>[], <int>[2, 4]);
    var rMap = await target.db.query(DbAccess.timeTable);
    expect(rMap.length, 8);
    expect(rMap[1]["id"], 3);
    expect(rMap[2]["id"], 5);

    /// データの更新と追加
    var rTimes = await target.getTimes(3);
    rTimes[0].iNo = 4;
    rTimes[1].iNo = 3;
    rTimes[2].iNo = 2;
    rTimes.add(TimeTable(
      titleid: 3,
      iNo: 1,
      iTime: 1,
      iDuration: 1,
      iColor: Colors.amber,
    ));

    await target.updateTimes(rTimes, <int>[]);
    rTimes = await target.getTimes(3);
    expect(rTimes.length, 4);
    expect(rTimes[0].iTime, 1);
    expect(rTimes[1].id, 3);
    expect(rTimes[2].id, 6);
    expect(rTimes[3].id, 9);

    await target.close();
  });
}
