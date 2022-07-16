import 'package:get/get.dart';

abstract class _IDbLoader {
  /// データベースからのデータ取り出し処理
  Future<void> loadDB();
}

/// Loaderを起動するためのインターフェースクラス
abstract class IDbLoader extends GetxController implements _IDbLoader {}

/// Loaderを起動するためのインターフェースクラス
abstract class IDbLoaderLife extends FullLifeCycleController
    implements _IDbLoader {}

/// DBをロードさせるための仕組み。
/// withしてFutureBuilderでloaderを指定する。
mixin Loader on _IDbLoader {
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
