import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:stacktimers/vm/topvm.dart';

class TopPage extends StatelessWidget {
  const TopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<TopVM>();
    vm.loader();
    return Scaffold(
      appBar: AppBar(
        title: Text("title".tr),
        actions: [
          IconButton(onPressed: vm.addTitle, icon: const Icon(Icons.more_time))
        ],
      ),
      body: const TitleLists(),
    );
  }
}

/// タイトルのリスト一覧
class TitleLists extends StatelessWidget {
  const TitleLists({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TopVM>(
        id: "all", // TopPageを更新するキー
        builder: (vm) => SlidableAutoCloseBehavior(
              child: ListView.builder(
                  itemCount: vm.titles.length,
                  itemBuilder: (context, index) => TitleListItem(index)),
            ));
  }
}

/// リストに表示する個々のアイテム
class TitleListItem extends StatelessWidget {
  const TitleListItem(this.index, {Key? key}) : super(key: key);

  /// 表示するアイテムの位置
  final int index;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TopVM>(
      id: "$index",
      builder: (vm) {
        return Slidable(
            key: ValueKey(index),
            endActionPane: ActionPane(
                dismissible: DismissiblePane(onDismissed: () {}),
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                      icon: Icons.delete,
                      onPressed: (context) => vm.deleteTitle(index))
                ]),
            child: FutureBuilder<String>(
              future: vm.titles[index].time(),
              builder: (context, snap) => ListTile(
                leading: IconButton(
                  onPressed: vm.titles[index].totalTime == 0
                      ? null
                      : () => vm.startTimer(index),
                  icon: const Icon(Icons.start),
                ),
                trailing: IconButton(
                  onPressed: () => vm.editTimer(index),
                  icon: const Icon(Icons.edit),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(vm.titles[index].sTitle),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(snap.hasData ? snap.data! : TitleList.defaultTime),
                  ],
                ),
              ),
            ));
      },
    );
  }
}
