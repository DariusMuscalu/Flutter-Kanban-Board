import 'package:boardview/board_item.dart';
import 'package:boardview/board_list.dart';
import 'package:boardview/boardview_controller.dart';
import 'package:flutter/material.dart';
import 'package:boardview/boardview.dart';

import 'BoardItemObject.dart';
import 'BoardListObject.dart';

//ignore: must_be_immutable
class BoardViewExample extends StatelessWidget {
  List<BoardListObject> _listData = [
    BoardListObject(title: "List title 1"),
    BoardListObject(title: "List title 2"),
    BoardListObject(title: "List title 3")
  ];

  // Can be used to animate to different sections of the BoardView
  BoardViewController boardViewController = new BoardViewController();

  @override
  Widget build(BuildContext context) {
    List<BoardList> _lists = [];

    for (int i = 0; i < _listData.length; i++) {
      _lists.add(_createBoardList(_listData[i]) as BoardList);
    }
    return BoardView(
      lists: _lists,
      boardViewController: boardViewController,
    );
  }

  Widget buildBoardItem(BoardItemObject itemObject) {
    return BoardItem(
      onStartDragItem: (
        int? listIndex,
        int? itemIndex,
        BoardItemState? state,
      ) {},
      onDropItem: (
        int? listIndex,
        int? itemIndex,
        int? oldListIndex,
        int? oldItemIndex,
        BoardItemState? state,
      ) {
        //Used to update our local item data
        var item = _listData[oldListIndex!].items![oldItemIndex!];
        _listData[oldListIndex].items!.removeAt(oldItemIndex);
        _listData[listIndex!].items!.insert(itemIndex!, item);
      },
      onTapItem: (
        int? listIndex,
        int? itemIndex,
        BoardItemState? state,
      ) async {},
      item: Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(itemObject.title!),
        ),
      ),
    );
  }

  Widget _createBoardList(BoardListObject list) {
    /// Each column list contains this list of items
    List<BoardItem> items = [
      BoardItem(
        item: Container(
          child: Text('Test'),
          height: 100,
          width: 100,
          color: Colors.red,
        ),
      ),
    ];

    return BoardList(
      onStartDragList: (int? listIndex) {},
      onTapList: (int? listIndex) async {},
      onDropList: (
        int? listIndex,
        int? oldListIndex,
      ) {
        //Update our local list data
        var list = _listData[oldListIndex!];
        _listData.removeAt(oldListIndex);
        _listData.insert(listIndex!, list);
      },
      headerBackgroundColor: Color.fromARGB(255, 235, 236, 240),
      backgroundColor: Color.fromARGB(255, 235, 236, 240),
      header: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              list.title!,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
      items: items,
    );
  }
}
