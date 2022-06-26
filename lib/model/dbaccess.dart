import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/model/timetable.dart';
import 'package:stacktimers/model/titletable.dart';
import 'package:get/get.dart';

/// 同一ファイルにアクセスするためのデータベースヘルパークラス
class DbAccess {
  DbAccess(this._dbName);

  /// タイトルテーブル用DB名
  static const titleTable = "titletable";

  /// タイムテーブル用DB名
  static const timeTable = "timetable";

  /// 保存するDBファイルの名前。
  final String _dbName;

  /// 保存するDBファイルのフルパス
  late String fullPathName;

  // SQL DataBase
  // onInit内で生成する。
  late Database _database;

  /// データベースの初期化処理
  Future<DbAccess> init() async {
    fullPathName = join(await databaseFactoryFfi.getDatabasesPath(), _dbName);
    _database = await databaseFactoryFfi.openDatabase(fullPathName,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE $titleTable '
                  '(id INTEGER PRIMARY KEY AUTOINCREMENT,'
                  'sTitle TEXT)');
              await db.execute('CREATE TABLE $timeTable '
                  '(id INTEGER PRIMARY KEY AUTOINCREMENT,'
                  'titleid INTEGER,'
                  'iNo INTEGER,'
                  'iTime INTEGER,'
                  'iDuration INTEGER,'
                  'iColor INTEGER)');
            }));
    return this;
  }

  /// [TitleTable]の全データ取り出し。
  Future<List<TitleTable>> get getTitles async {
    final lists = await db.query(DbAccess.titleTable);
    return List.generate(
        lists.length, (index) => TitleTable.fromMap(lists[index]));
  }

  /// [TitleTable]の1データ取り出し
  Future<TitleTable> getTitle(int id) async {
    final lists =
        await db.query(DbAccess.titleTable, where: 'id = ?', whereArgs: [id]);
    if (lists.isEmpty) {
      return Future.error("Illegal id($id)");
    } else {
      return TitleTable.fromMap(lists[0]);
    }
  }

  /// [TitleTable]の追加更新
  ///
  /// 新規追加時[id]が更新される。
  Future<void> updateTitle(TitleTable title) async {
    if (title.id == -1) {
      // 新規追加
      final result = await db.insert(DbAccess.titleTable, title.toSqlMap());
      title.id = result;
    } else {
      await db.update(DbAccess.titleTable, title.toSqlMap(),
          where: 'id = ?', whereArgs: [title.id]);
    }
  }

  /// [TitleTable]の1レコード削除
  Future<void> deleteTitle(int id) async {
    await db.transaction((txn) async {
      await txn.delete(DbAccess.titleTable, where: 'id = ?', whereArgs: [id]);
      await txn
          .delete(DbAccess.timeTable, where: 'titleid = ?', whereArgs: [id]);
    });
  }

  /// [titleid]を持つ[TimeTable]を複数取り出す
  Future<List<TimeTable>> getTimes(int titleid) async {
    final lists = await db.query(DbAccess.timeTable,
        where: 'titleid = ?', whereArgs: [titleid], orderBy: 'iNo ASC');
    return List.generate(
        lists.length, (index) => TimeTable.fromMap(lists[index]));
  }

  /// [TimeTable]の一括更新
  ///
  /// [times]が追加更新用のデータ。[deleteid]が削除対象とするレコードのID
  Future<void> updateTimes(List<TimeTable> times, List<int> deleteid) async {
    await db.transaction((txn) async {
      for (final id in deleteid) {
        await txn.delete(DbAccess.timeTable, where: 'id = ?', whereArgs: [id]);
      }
      for (final time in times) {
        if (time.id == -1) {
          // 新規追加
          final result = await txn.insert(DbAccess.timeTable, time.toSqlMap());
          time.id = result;
        } else {
          await txn.update(DbAccess.timeTable, time.toSqlMap(),
              where: 'id = ?', whereArgs: [time.id]);
        }
      }
    });
  }

  /// [TimeTable]の更新
  ///
  /// 新規追加時[id]が更新される。
  Future<void> updateTime(TimeTable time) async {
    if (time.id == -1) {
      // 新規追加
      final result = await db.insert(DbAccess.timeTable, time.toSqlMap());
      time.id = result;
    } else {
      await db.update(DbAccess.timeTable, time.toSqlMap(),
          where: 'id = ?', whereArgs: [time.id]);
    }
  }

  /// データベースのアクセッサ
  Database get db => _database;

  /// データベースの全削除
  Future<void> deleteAll() async {
    await db.transaction((txn) async {
      await txn.delete(titleTable);
      await txn.delete(timeTable);
    });
  }

  /// クローズ処理
  Future<void> close() async {
    await db.close();
  }

  /// データベースの作成
  static Future<DbAccess> create(String dbName) async {
    return DbAccess(dbName).init();
  }

  /// データベースアクセスの取得
  static DbAccess get a => Get.find<DbAccess>();
}
