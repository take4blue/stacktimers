import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          "title": "StackTimers",
          "commonLabelErrorRead": "Failed to read.",
          "commonLabelNowLoading": "Now loading.",
          "t1TextTitle": "Title name.",
          "t2TextTotal": "Total",
          "t2TextLap": "Lap",
        },
        'ja_JP': {
          "title": "StackTimers",
          "commonLabelErrorRead": "読み込みに失敗しました。",
          "commonLabelNowLoading": "読み込み中。",
          "t1TextTitle": "タイトル名",
          "t2TextTotal": "Total",
          "t2TextLap": "Lap",
        }
      };
}
