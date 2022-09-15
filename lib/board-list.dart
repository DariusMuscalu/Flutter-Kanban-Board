import 'package:boardview/board-item.dart';
import 'package:boardview/boardview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef void OnDropList(
  int? listIndex,
  int? oldListIndex,
);

typedef void OnTapList(
  int? listIndex,
);

typedef void OnStartDragList(
  int? listIndex,
);

class BoardList extends StatefulWidget {
  final List<Widget> header;
  final List<BoardItem> items;
  final Widget? footer;

  // === STYLE ===

  final Color? backgroundColor;
  final Color? headerBackgroundColor;

  final BoardViewState? boardView;

  // Callbacks
  final OnDropList? onDropList;
  final OnTapList? onTapList;
  final OnStartDragList? onStartDragList;

  // Makes the list draggable or not.
  // The list can be dragged by the header.
  final bool isDraggable;

  final int? index;

  const BoardList({
    required this.header,
    required this.items,
    this.footer,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.boardView,
    this.isDraggable = true,
    this.index,
    this.onDropList,
    this.onTapList,
    this.onStartDragList,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardListState();
  }
}

class BoardListState extends State<BoardList> {
  List<BoardItemState> boardItemStates = [];

  ScrollController boardListScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    List<Widget> listContent = [
      _header(
        context,
      ),
      _item(),
    ];

    if (widget.footer != null) {
      listContent.add(widget.footer!);
    }

    if (widget.boardView!.listStates.length > widget.index!) {
      widget.boardView!.listStates.removeAt(widget.index!);
    }

    widget.boardView!.listStates.insert(
      widget.index!,
      this,
    );

    /// Layout details.
    /// (!)  Not sure about it yet:
    /// This is the container that holds the items inside a list
    return Container(
      // Change this to understand what it is while watching the live example modifying
      height: 300,
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Color.fromARGB(255, 255, 255, 255),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: listContent,
      ),
    );
  }

  Widget _item() => Container(
        child: Flexible(
          fit: FlexFit.loose,
          child: ListView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            controller: boardListScrollController,
            itemCount: widget.items.length,
            itemBuilder: (ctx, index) {
              if (widget.items[index].boardList == null ||
                  widget.items[index].index != index ||
                  widget.items[index].boardList!.widget.index != widget.index ||
                  widget.items[index].boardList != this) {
                widget.items[index] = BoardItem(
                  boardList: this,
                  item: widget.items[index].item,
                  draggable: widget.items[index].draggable,
                  index: index,
                  onDropItem: widget.items[index].onDropItem,
                  onTapItem: widget.items[index].onTapItem,
                  onDragItem: widget.items[index].onDragItem,
                  onStartDragItem: widget.items[index].onStartDragItem,
                );
              }

              if (widget.boardView!.draggedItemIndex == index &&
                  widget.boardView!.draggedListIndex == widget.index) {
                return Opacity(
                  opacity: 0.0,
                  child: widget.items[index],
                );
              } else {
                return widget.items[index];
              }
            },
          ),
        ),
      );

  // Adds the header to a list, only by the header the list can be dragged.
  Widget _header(BuildContext context) => GestureDetector(
        child: Container(
          color: widget.headerBackgroundColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.header,
          ),
        ),

        onTap: () {
          if (widget.onTapList != null) {
            widget.onTapList!(widget.index);
          }
        },

        onTapDown: (otd) {
          if (widget.isDraggable) {
            RenderBox object = context.findRenderObject() as RenderBox;
            Offset pos = object.localToGlobal(Offset.zero);
            widget.boardView!.initialX = pos.dx;
            widget.boardView!.initialY = pos.dy;

            widget.boardView!.rightListX = pos.dx + object.size.width;
            widget.boardView!.leftListX = pos.dx;
          }
        },

        // TODO Remove after testing the example and seeing that there are no errors
        onTapCancel: () {},

        onLongPress: () {
          if (!widget.boardView!.widget.isSelecting && widget.isDraggable) {
            _startDrag(widget, context);
          }
        },
      );

  void _onDropList(int? listIndex) {
    if (widget.onDropList != null) {
      widget.onDropList!(
        listIndex,
        widget.boardView!.startListIndex,
      );
    }

    widget.boardView!.draggedListIndex = null;

    if (widget.boardView!.mounted) {
      widget.boardView!.setState(() {});
    }
  }

  void _startDrag(Widget item, BuildContext context) {
    if (widget.boardView != null && widget.isDraggable) {
      if (widget.onStartDragList != null) {
        widget.onStartDragList!(widget.index);
      }

      widget.boardView!.startListIndex = widget.index;
      widget.boardView!.height = context.size!.height;
      widget.boardView!.draggedListIndex = widget.index!;
      widget.boardView!.draggedItemIndex = null;
      widget.boardView!.draggedItem = item;
      widget.boardView!.onDropList = _onDropList;
      widget.boardView!.run();

      if (widget.boardView!.mounted) {
        widget.boardView!.setState(() {});
      }
    }
  }
}
