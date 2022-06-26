import 'package:get/get.dart';

/// Loaderを起動するためのインターフェースクラス
abstract class IDbLoader extends GetxController {
  /// データベースからのデータ取り出し処理
  Future<void> loadDB();
}

/// DBをロードさせるための仕組み。
/// withしてFutureBuilderでloaderを指定する。
mixin Loader on IDbLoader {
  /// [loadDB]が呼び出されていない場合true。
  bool _isNotLoadDb = true;

  /// 再読み込みの指示
  void reset() => _isNotLoadDb = true;

  /// LoadDBが未コールだ!!(デバッグ用)
  bool get isNotLoadDb => _isNotLoadDb;

  /// データベースのローダー
  Future<void> loader() async {
    if (_isNotLoadDb) {
      _isNotLoadDb = false;
      await loadDB();
    }
  }
}
