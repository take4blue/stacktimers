import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktimers/model/dbaccess.dart';
import 'package:stacktimers/view/toppage.dart';
import 'package:stacktimers/view/viewcontrol.dart';
import 'package:stacktimers/vm/topvm.dart';

import 'l10n/message.dart';

void main() async {
  sqfliteFfiInit();
  final db = await DbAccess.create("appdata.db");
  final view = ViewControl();
  runApp(GetMaterialApp(
    translations: Messages(),
    locale: Get.deviceLocale,
    fallbackLocale: const Locale('en', 'US'),
    initialRoute: AppModule.initialPage,
    initialBinding: BindingsBuilder(
      () {
        Get.put<DbAccess>(db);
        Get.put<ViewControl>(view);
      },
    ),
    getPages: AppModule.page(),
  ));
}

class AppModule {
  static get initialPage => "/Top";

  static List<GetPage> page() {
    return [
      GetPage(
          name: "/Top",
          page: () => const TopPage(),
          binding: BindingsBuilder(
            () => Get.lazyPut<TopVM>(() => TopVM()),
          )),
    ];
  }
}
