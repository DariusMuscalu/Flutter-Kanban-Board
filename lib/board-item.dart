import 'package:boardview/board-list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef void OnDropItem(
  int? listIndex,
  int? itemIndex,
  int? oldListIndex,
  int? oldItemIndex,
  BoardItemState state,
);

typedef void OnTapItem(
  int? listIndex,
  int? itemIndex,
  BoardItemState state,
);

typedef void OnStartDragItem(
  int? listIndex,
  int? itemIndex,
  BoardItemState state,
);

typedef void OnDragItem(
  int oldListIndex,
  int oldItemIndex,
  int newListIndex,
  int newItemIndex,
  BoardItemState state,
);

class BoardItem extends StatefulWidget {
  final BoardListState? boardList;
  final Widget? item;
  final int? index;
  final bool draggable;

  // Callbacks
  final OnDropItem? onDropItem;
  final OnTapItem? onTapItem;
  final OnStartDragItem? onStartDragItem;
  final OnDragItem? onDragItem;

  const BoardItem({
    this.boardList,
    this.item,
    this.index,
    this.onDropItem,
    this.onTapItem,
    this.onStartDragItem,
    this.draggable = true,
    this.onDragItem,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => BoardItemState();
}

class BoardItemState extends State<BoardItem> {
  late double height;
  double? width;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _afterFirstLayout(context));

    if (widget.boardList!.boardItemStates.length > widget.index!) {
      widget.boardList!.boardItemStates.removeAt(widget.index!);
    }

    widget.boardList!.boardItemStates.insert(
      widget.index!,
      this,
    );

    return GestureDetector(
      child: widget.item,

      onTapDown: (otd) {
        if (widget.draggable) {
          RenderBox object = context.findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);

          RenderBox box =
              widget.boardList!.context.findRenderObject() as RenderBox;
          Offset listPos = box.localToGlobal(Offset.zero);

          widget.boardList!.widget.boardView!.leftListX = listPos.dx;
          widget.boardList!.widget.boardView!.topListY = listPos.dy;
          widget.boardList!.widget.boardView!.topItemY = pos.dy;
          widget.boardList!.widget.boardView!.bottomItemY =
              pos.dy + object.size.height;
          widget.boardList!.widget.boardView!.bottomListY =
              listPos.dy + box.size.height;
          widget.boardList!.widget.boardView!.rightListX =
              listPos.dx + box.size.width;

          widget.boardList!.widget.boardView!.initialX = pos.dx;
          widget.boardList!.widget.boardView!.initialY = pos.dy;
        }
      },

      // TODO Remove after testing the example and seeing that there are no errors
      onTapCancel: () {},

      onTap: () {
        if (widget.onTapItem != null) {
          widget.onTapItem!(
            widget.boardList!.widget.index,
            widget.index,
            this,
          );
        }
      },

      onLongPress: () {
        if (!widget.boardList!.widget.boardView!.widget.isSelecting &&
            widget.draggable) {
          _startDrag(
            widget,
            context,
          );
        }
      },
    );
  }

  void _onDropItem(int? listIndex, int? itemIndex) {
    if (widget.onDropItem != null) {
      widget.onDropItem!(
        listIndex,
        itemIndex,
        widget.boardList!.widget.boardView!.startListIndex,
        widget.boardList!.widget.boardView!.startItemIndex,
        this,
      );
    }

    widget.boardList!.widget.boardView!.draggedItemIndex = null;
    widget.boardList!.widget.boardView!.draggedListIndex = null;

    if (widget.boardList!.widget.boardView!.listStates[listIndex!].mounted) {
      widget.boardList!.widget.boardView!.listStates[listIndex].setState(() {});
    }
  }

  void _startDrag(Widget item, BuildContext context) {
    if (widget.boardList!.widget.boardView != null) {
      widget.boardList!.widget.boardView!.onDropItem = _onDropItem;

      if (widget.boardList!.mounted) {
        widget.boardList!.setState(() {});
      }

      widget.boardList!.widget.boardView!.draggedItemIndex = widget.index;

      widget.boardList!.widget.boardView!.height = context.size!.height;

      widget.boardList!.widget.boardView!.draggedListIndex =
          widget.boardList!.widget.index;

      widget.boardList!.widget.boardView!.startListIndex =
          widget.boardList!.widget.index;

      widget.boardList!.widget.boardView!.startItemIndex = widget.index;

      widget.boardList!.widget.boardView!.draggedItem = item;

      if (widget.onStartDragItem != null) {
        widget.onStartDragItem!(
          widget.boardList!.widget.index,
          widget.index,
          this,
        );
      }

      widget.boardList!.widget.boardView!.run();

      if (widget.boardList!.widget.boardView!.mounted) {
        widget.boardList!.widget.boardView!.setState(() {});
      }
    }
  }

  /// (!) DON'T DELETE
  /// IT FIXES AN RED SCREEN ERROR WHILE DRAGGING AN ITEM, DO FURTHER RESEARCH
  void _afterFirstLayout(BuildContext context) {
    try {
      height = context.size!.height;
      width = context.size!.width;
    } catch (e) {}
  }
}
