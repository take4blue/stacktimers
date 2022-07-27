import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:stacktimers/vm/timereditvm.dart';

/// 時間を設定するページ
class TimerEditPage extends StatelessWidget {
  const TimerEditPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerEditVM>(
      id: "all", // TopPageを更新鍵
      builder: (vm) {
        vm.loader();
        vm.controller.text = vm.title;
        return WillPopScope(
          onWillPop: vm.updateDb,
          child: Scaffold(
            appBar: AppBar(
              title: Text(vm.title),
              actions: [
                IconButton(
                    onPressed: vm.addTimer, icon: const Icon(Icons.more_time))
              ],
            ),
            body: Column(children: [
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: vm.controller,
                decoration: InputDecoration(
                  labelText: "t1TextTitle".tr,
                  border: const OutlineInputBorder(),
                ),
                onChanged: vm.changeTitle,
              ),
              const Divider(),
              GetBuilder<TimerEditVM>(
                  id: "total", // トータル更新鍵
                  builder: (vm) {
                    return ListTile(
                      title: Text(vm.total),
                    );
                  }),
              const Divider(),
              const Expanded(
                child: TimerList(),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// List部分
class TimerList extends StatelessWidget {
  const TimerList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => GetBuilder<TimerEditVM>(
      id: "list",
      builder: (vm) {
        return SlidableAutoCloseBehavior(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: vm.times.length,
            itemBuilder: (context, index) => TimerListItem(
              index,
              key: Key("$index"),
            ),
            onReorder: vm.reorder,
          ),
        );
      });
}

/// タイマーの1レコード設定用のウィジェット
class TimerListItem extends StatelessWidget {
  const TimerListItem(this.index, {Key? key}) : super(key: key);

  /// 表示するアイテムの位置
  final int index;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerEditVM>(
      id: "$index", // アイテム更新鍵
      builder: (vm) {
        return Slidable(
          key: ValueKey(index),
          endActionPane: ActionPane(
              dismissible: DismissiblePane(onDismissed: () {}),
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                    icon: Icons.delete,
                    onPressed: (context) => vm.deleteTime(index))
              ]),
          child: ListTile(
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                    onTap: () => vm.editTime(index),
                    child: Text(vm.times[index].time)),
                const SizedBox(
                  width: 20,
                ),
                GestureDetector(
                  onTap: () => vm.editColor(index),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: vm.times[index].timer.iColor),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                GestureDetector(
                    onTap: () => vm.editDuration(index),
                    child: Text(vm.times[index].duration)),
              ],
            ),
          ),
        );
      },
    );
  }
}
