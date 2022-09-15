library boardview;

import 'dart:core';

import 'package:boardview/board-list.dart';
import 'package:boardview/boardview-controller.dart';
import 'package:boardview/scrollbar-style.dart';
import 'package:flutter/material.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

typedef void OnDropBottomWidget(
  int? listIndex,
  int? itemIndex,
  double percentX,
);

typedef void OnDropItem(
  int? listIndex,
  int? itemIndex,
);

typedef void OnDropList(
  int? listIndex,
);

// This is the area where we can drag an item / list around,
// if the dragged item is dragged outside this area it will not show.
//ignore: must_be_immutable
class BoardView extends StatefulWidget {
  final List<BoardList> lists;
  final double width;
  double? bottomPadding;
  bool isSelecting;

  // Adds scrollbar
  bool? hasScrollbar;

  // === Styling ===
  ScrollbarStyle? scrollbarStyle;

  BoardViewController? boardViewController;
  int dragDelay;

  OnDropBottomWidget? onDropItemInMiddleWidget;

  BoardView({
    required this.lists,
    this.hasScrollbar,
    this.scrollbarStyle,
    this.boardViewController,
    this.dragDelay = 300,
    this.onDropItemInMiddleWidget,
    this.isSelecting = false,
    this.width = 280,
    this.bottomPadding,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardViewState();
  }
}

class BoardViewState extends State<BoardView> {
  // List Coordinates
  double? rightListX;
  double? leftListX;
  double? topListY;
  double? bottomListY;

  // Item Coordinates
  double? topItemY;
  double? bottomItemY;

  // Dragged Item
  Widget? draggedItem;
  int? draggedItemIndex;
  int? draggedListIndex;

  double? dx;
  double? dxInit;
  double? dyInit;
  double? dy;
  double? offsetX;
  double? offsetY;
  double? initialX = 0;
  double? initialY = 0;

  double? height;

  int? startListIndex;
  int? startItemIndex;

  bool canDrag = true;

  ScrollController boardViewScrollController = ScrollController();

  List<BoardListState> listStates = [];

  // Callbacks
  OnDropItem? onDropItem;
  OnDropList? onDropList;

  bool isScrolling = false;

  // TODO: Try to identify the type of this variable
  var pointer;

  bool shown = true;

  bool _isInWidget = false;

  /// See if you need to dispose something
  @override
  void initState() {
    if (widget.boardViewController != null) {
      widget.boardViewController!.state = this;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (boardViewScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        try {
          boardViewScrollController.position.didUpdateScrollPositionBy(0);
        } catch (e) {}

        bool _shown = boardViewScrollController.position.maxScrollExtent != 0;

        if (_shown != shown) {
          setState(() {
            shown = _shown;
          });
        }
      });
    }

    Widget listWidget = ListView.builder(
      physics: ClampingScrollPhysics(),
      itemCount: widget.lists.length,
      scrollDirection: Axis.horizontal,
      controller: boardViewScrollController,
      itemBuilder: (BuildContext context, int index) {
        if (widget.lists[index].boardView == null) {
          widget.lists[index] = BoardList(
            items: widget.lists[index].items,
            headerBackgroundColor: widget.lists[index].headerBackgroundColor,
            backgroundColor: widget.lists[index].backgroundColor,
            footer: widget.lists[index].footer,
            header: widget.lists[index].header,
            boardView: this,
            isDraggable: widget.lists[index].isDraggable,
            onDropList: widget.lists[index].onDropList,
            onTapList: widget.lists[index].onTapList,
            onStartDragList: widget.lists[index].onStartDragList,
          );
        }

        if (widget.lists[index].index != index) {
          widget.lists[index] = BoardList(
            items: widget.lists[index].items,
            headerBackgroundColor: widget.lists[index].headerBackgroundColor,
            backgroundColor: widget.lists[index].backgroundColor,
            footer: widget.lists[index].footer,
            header: widget.lists[index].header,
            boardView: this,
            isDraggable: widget.lists[index].isDraggable,
            index: index,
            onDropList: widget.lists[index].onDropList,
            onTapList: widget.lists[index].onTapList,
            onStartDragList: widget.lists[index].onStartDragList,
          );
        }

        var temp = Container(
          width: widget.width,
          padding: EdgeInsets.fromLTRB(0, 0, 0, widget.bottomPadding ?? 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[Expanded(child: widget.lists[index])],
          ),
        );

        if (draggedListIndex == index && draggedItemIndex == null) {
          return Opacity(
            opacity: 0.0,
            child: temp,
          );
        } else {
          return temp;
        }
      },
    );
    listWidget = _listWithScrollbar(listWidget);

    List<Widget> stackWidgets = <Widget>[listWidget];

    bool isInBottomWidget = false;
    if (dy != null) {
      if (MediaQuery.of(context).size.height - dy! < 80) {
        isInBottomWidget = true;
      }
    }

    if (initialX != null &&
        initialY != null &&
        offsetX != null &&
        offsetY != null &&
        dx != null &&
        dy != null &&
        height != null) {
      if (canDrag && dxInit != null && dyInit != null && !isInBottomWidget) {
        if (draggedItemIndex != null &&
            draggedItem != null &&
            topItemY != null &&
            bottomItemY != null) {
          //dragging item
          if (0 <= draggedListIndex! - 1 && dx! < leftListX! + 45) {
            //scroll left
            if (boardViewScrollController.hasClients) {
              boardViewScrollController.animateTo(
                boardViewScrollController.position.pixels - 5,
                duration: Duration(milliseconds: 10),
                curve: Curves.ease,
              );
              if (listStates[draggedListIndex!].mounted) {
                RenderBox object = listStates[draggedListIndex!]
                    .context
                    .findRenderObject() as RenderBox;
                Offset pos = object.localToGlobal(Offset.zero);
                leftListX = pos.dx;
                rightListX = pos.dx + object.size.width;
              }
            }
          }
          if (widget.lists.length > draggedListIndex! + 1 &&
              dx! > rightListX! - 45) {
            //scroll right
            if (boardViewScrollController.hasClients) {
              boardViewScrollController.animateTo(
                boardViewScrollController.position.pixels + 5,
                duration: Duration(milliseconds: 10),
                curve: Curves.ease,
              );

              if (listStates[draggedListIndex!].mounted) {
                RenderBox object = listStates[draggedListIndex!]
                    .context
                    .findRenderObject() as RenderBox;
                Offset pos = object.localToGlobal(Offset.zero);

                leftListX = pos.dx;
                rightListX = pos.dx + object.size.width;
              }
            }
          }

          /// The comment inside says 'move left' but what to move to left?
          /// Apparently if you disable this, the items inside a list will not
          /// be able to be placed inside a column which is on the left of the column
          /// that it was placed initially. So I decided to rename it from moveLeft
          /// to moveItemToLeftList
          if (0 <= draggedListIndex! - 1 && dx! < leftListX!) {
            _moveItemToLeftList();
          }

          /// Same as the above comment but for moving to right
          if (widget.lists.length > draggedListIndex! + 1 &&
              dx! > rightListX!) {
            _moveItemToRightList();
          }

          if (dy! < topListY! + 70) {
            //scroll up
            if (listStates[draggedListIndex!]
                    .boardListScrollController
                    .hasClients &&
                !isScrolling) {
              isScrolling = true;
              double pos = listStates[draggedListIndex!]
                  .boardListScrollController
                  .position
                  .pixels;
              listStates[draggedListIndex!]
                  .boardListScrollController
                  .animateTo(
                    listStates[draggedListIndex!]
                            .boardListScrollController
                            .position
                            .pixels -
                        5,
                    duration: Duration(milliseconds: 10),
                    curve: Curves.ease,
                  )
                  .whenComplete(
                () {
                  pos -= listStates[draggedListIndex!]
                      .boardListScrollController
                      .position
                      .pixels;
                  if (initialY == null) initialY = 0;

                  /// See why this is commented
//                if(widget.boardViewController != null) {
//                  initialY -= pos;
//                }
                  isScrolling = false;

                  if (topItemY != null) {
                    topItemY = topItemY! + pos;
                  }

                  if (bottomItemY != null) {
                    bottomItemY = bottomItemY! + pos;
                  }

                  if (mounted) {
                    setState(() {});
                  }
                },
              );
            }
          }

          if (0 <= draggedItemIndex! - 1 &&
              dy! <
                  topItemY! -
                      listStates[draggedListIndex!]
                              .boardItemStates[draggedItemIndex! - 1]
                              .height /
                          2) {
            /// Looks like if you place 2 items in a column and trying to place the dragged
            /// item above the one in the column it wont work if you disable this method.
            /// So I decided to rename it from moveUp() to moveItemAboveAnotherOne().
            _moveDraggedItemAboveAnother();
          }

          double? tempBottom = bottomListY;

          /// Comment inside says SCROLL DOWN.
          /// TODO Do further research to understand what it does
          if (dy! > tempBottom! - 70) {
            //scroll down

            if (listStates[draggedListIndex!]
                .boardListScrollController
                .hasClients) {
              isScrolling = true;
              double pos = listStates[draggedListIndex!]
                  .boardListScrollController
                  .position
                  .pixels;
              listStates[draggedListIndex!]
                  .boardListScrollController
                  .animateTo(
                    listStates[draggedListIndex!]
                            .boardListScrollController
                            .position
                            .pixels +
                        5,
                    duration: Duration(milliseconds: 10),
                    curve: Curves.ease,
                  )
                  .whenComplete(
                () {
                  pos -= listStates[draggedListIndex!]
                      .boardListScrollController
                      .position
                      .pixels;

                  if (initialY == null) initialY = 0;

                  /// See why this was commented
//                if(widget.boardViewController != null) {
//                  initialY -= pos;
//                }

                  isScrolling = false;

                  if (topItemY != null) {
                    topItemY = topItemY! + pos;
                  }

                  if (bottomItemY != null) {
                    bottomItemY = bottomItemY! + pos;
                  }

                  if (mounted) {
                    setState(() {});
                  }
                },
              );
            }
          }

          /// The method and comment inside here said moveDown which is the
          /// method for moving the dragged item below another item in the list,
          /// so I decided to rename it to moveDraggedItemBelowAnother()
          if (widget.lists[draggedListIndex!].items.length >
                  draggedItemIndex! + 1 &&
              dy! >
                  bottomItemY! +
                      listStates[draggedListIndex!]
                              .boardItemStates[draggedItemIndex! + 1]
                              .height /
                          2) {
            _moveDraggedItemBelowAnother();
          }
        } else {
          //dragging list
          if (0 <= draggedListIndex! - 1 && dx! < leftListX! + 45) {
            //scroll left
            if (boardViewScrollController.hasClients) {
              boardViewScrollController.animateTo(
                boardViewScrollController.position.pixels - 5,
                duration: Duration(milliseconds: 10),
                curve: Curves.ease,
              );

              if (leftListX != null) {
                leftListX = leftListX! + 5;
              }

              if (rightListX != null) {
                rightListX = rightListX! + 5;
              }
            }
          }

          if (widget.lists.length > draggedListIndex! + 1 &&
              dx! > rightListX! - 45) {
            //scroll right
            if (boardViewScrollController.hasClients) {
              boardViewScrollController.animateTo(
                boardViewScrollController.position.pixels + 5,
                duration: Duration(milliseconds: 10),
                curve: Curves.ease,
              );

              if (leftListX != null) {
                leftListX = leftListX! - 5;
              }

              if (rightListX != null) {
                rightListX = rightListX! - 5;
              }
            }
          }

          if (widget.lists.length > draggedListIndex! + 1 &&
              dx! > rightListX!) {
            //move right
            _moveListRight();
          }

          if (0 <= draggedListIndex! - 1 && dx! < leftListX!) {
            //move left
            _moveListLeft();
          }
        }
      }

      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          if (mounted) {
            setState(() {});
          }
        },
      );

      stackWidgets.add(
        Positioned(
          width: widget.width,
          height: height,
          child: Opacity(
            opacity: .7,
            child: draggedItem,
          ),
          left: (dx! - offsetX!) + initialX!,
          top: (dy! - offsetY!) + initialY!,
        ),
      );
    }

    return Container(
      /// After setting the bg here I can see that this container holds the space where
      /// board list and items are placed and can be dragged around
      color: Colors.yellow,

      /// (!) You can adjust it's height from here, the items will be visible while dragged only
      /// in this container. Later add a customizable parameter here to set the board view height and width.
      /// height: 650,

      child: Listener(
        onPointerMove: (opm) {
          if (draggedItem != null) {
            if (dxInit == null) {
              dxInit = opm.position.dx;
            }

            if (dyInit == null) {
              dyInit = opm.position.dy;
            }

            dx = opm.position.dx;
            dy = opm.position.dy;

            if (mounted) {
              setState(() {});
            }
          }
        },
        onPointerDown: (opd) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset pos = box.localToGlobal(opd.position);
          offsetX = pos.dx;
          offsetY = pos.dy;
          pointer = opd;
          if (mounted) {
            setState(() {});
          }
        },
        onPointerUp: (opu) {
          if (onDropItem != null) {
            int? tempDraggedItemIndex = draggedItemIndex;
            int? tempDraggedListIndex = draggedListIndex;
            int? startDraggedItemIndex = startItemIndex;
            int? startDraggedListIndex = startListIndex;

            if (_isInWidget && widget.onDropItemInMiddleWidget != null) {
              onDropItem!(startDraggedListIndex, startDraggedItemIndex);

              widget.onDropItemInMiddleWidget!(
                startDraggedListIndex,
                startDraggedItemIndex,
                opu.position.dx / MediaQuery.of(context).size.width,
              );
            } else {
              onDropItem!(
                tempDraggedListIndex,
                tempDraggedItemIndex,
              );
            }
          }

          if (onDropList != null) {
            int? tempDraggedListIndex = draggedListIndex;

            if (_isInWidget && widget.onDropItemInMiddleWidget != null) {
              onDropList!(tempDraggedListIndex);
              widget.onDropItemInMiddleWidget!(tempDraggedListIndex, null,
                  opu.position.dx / MediaQuery.of(context).size.width);
            } else {
              onDropList!(tempDraggedListIndex);
            }
          }

          draggedItem = null;
          offsetX = null;
          offsetY = null;
          initialX = null;
          initialY = null;
          dx = null;
          dy = null;
          draggedItemIndex = null;
          draggedListIndex = null;
          onDropItem = null;
          onDropList = null;
          dxInit = null;
          dyInit = null;
          leftListX = null;
          rightListX = null;
          topListY = null;
          bottomListY = null;
          topItemY = null;
          bottomItemY = null;
          startListIndex = null;
          startItemIndex = null;

          if (mounted) {
            setState(() {});
          }
        },
        child: Stack(
          children: stackWidgets,
        ),
      ),
    );
  }

  Widget _listWithScrollbar(Widget listWidget) {
    if (widget.hasScrollbar == true) {
      listWidget = VsScrollbar(
        controller: boardViewScrollController,
        // default false
        showTrackOnHover: true,
        // default false
        isAlwaysShown: shown && widget.lists.length > 1,
        // default : Duration(milliseconds: 300)
        scrollbarFadeDuration: Duration(
          milliseconds: 500,
        ),
        // default : Duration(milliseconds: 600)
        scrollbarTimeToFade: Duration(
          milliseconds: 800,
        ),
        style: widget.scrollbarStyle != null
            ? VsScrollbarStyle(
                hoverThickness: widget.scrollbarStyle!.hoverThickness,
                radius: widget.scrollbarStyle!.radius,
                thickness: widget.scrollbarStyle!.thickness,
                color: widget.scrollbarStyle!.color,
              )
            : VsScrollbarStyle(),
        child: listWidget,
      );
    }
    return listWidget;
  }

  void _moveDraggedItemBelowAnother() {
    if (topItemY != null) {
      topItemY = topItemY! +
          listStates[draggedListIndex!]
              .boardItemStates[draggedItemIndex! + 1]
              .height;
    }

    if (bottomItemY != null) {
      bottomItemY = bottomItemY! +
          listStates[draggedListIndex!]
              .boardItemStates[draggedItemIndex! + 1]
              .height;
    }

    var item = widget.lists[draggedListIndex!].items[draggedItemIndex!];

    widget.lists[draggedListIndex!].items.removeAt(draggedItemIndex!);

    var itemState =
        listStates[draggedListIndex!].boardItemStates[draggedItemIndex!];

    listStates[draggedListIndex!].boardItemStates.removeAt(draggedItemIndex!);

    if (draggedItemIndex != null) {
      draggedItemIndex = draggedItemIndex! + 1;
    }

    widget.lists[draggedListIndex!].items.insert(draggedItemIndex!, item);

    listStates[draggedListIndex!]
        .boardItemStates
        .insert(draggedItemIndex!, itemState);

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }
  }

  void _moveDraggedItemAboveAnother() {
    if (topItemY != null) {
      topItemY = topItemY! -
          listStates[draggedListIndex!]
              .boardItemStates[draggedItemIndex! - 1]
              .height;
    }

    if (bottomItemY != null) {
      bottomItemY = bottomItemY! -
          listStates[draggedListIndex!]
              .boardItemStates[draggedItemIndex! - 1]
              .height;
    }

    if (draggedItemIndex != null) {
      draggedItemIndex = draggedItemIndex! - 1;
    }

    var item = widget.lists[draggedListIndex!].items[draggedItemIndex!];

    widget.lists[draggedListIndex!].items.removeAt(draggedItemIndex!);

    var itemState =
        listStates[draggedListIndex!].boardItemStates[draggedItemIndex!];

    listStates[draggedListIndex!].boardItemStates.removeAt(draggedItemIndex!);

    widget.lists[draggedListIndex!].items.insert(draggedItemIndex!, item);

    listStates[draggedListIndex!]
        .boardItemStates
        .insert(draggedItemIndex!, itemState);

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(
        () {},
      );
    }
  }

  void _moveListRight() {
    var list = widget.lists[draggedListIndex!];

    var listState = listStates[draggedListIndex!];

    widget.lists.removeAt(draggedListIndex!);

    listStates.removeAt(draggedListIndex!);

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }

    widget.lists.insert(draggedListIndex!, list);

    listStates.insert(draggedListIndex!, listState);

    canDrag = false;

    if (boardViewScrollController.hasClients) {
      int? tempListIndex = draggedListIndex;

      boardViewScrollController
          .animateTo(
        draggedListIndex! * widget.width,
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      )
          .whenComplete(
        () {
          RenderBox object = listStates[tempListIndex!]
              .context
              .findRenderObject() as RenderBox;

          Offset pos = object.localToGlobal(Offset.zero);

          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;

          Future.delayed(
            Duration(
              milliseconds: widget.dragDelay,
            ),
            () {
              canDrag = true;
            },
          );
        },
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _moveItemToRightList() {
    var item = widget.lists[draggedListIndex!].items[draggedItemIndex!];

    var itemState =
        listStates[draggedListIndex!].boardItemStates[draggedItemIndex!];

    widget.lists[draggedListIndex!].items.removeAt(draggedItemIndex!);

    listStates[draggedListIndex!].boardItemStates.removeAt(draggedItemIndex!);

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }

    double closestValue = 10000;

    draggedItemIndex = 0;

    for (int i = 0;
        i < listStates[draggedListIndex!].boardItemStates.length;
        i++) {
      if (listStates[draggedListIndex!].boardItemStates[i].mounted) {
        RenderBox box = listStates[draggedListIndex!]
            .boardItemStates[i]
            .context
            .findRenderObject() as RenderBox;

        Offset pos = box.localToGlobal(Offset.zero);

        var temp = (pos.dy - dy! + (box.size.height / 2)).abs();

        if (temp < closestValue) {
          closestValue = temp;
          draggedItemIndex = i;
          dyInit = dy;
        }
      }
    }

    widget.lists[draggedListIndex!].items.insert(draggedItemIndex!, item);

    listStates[draggedListIndex!]
        .boardItemStates
        .insert(draggedItemIndex!, itemState);

    canDrag = false;

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }

    if (boardViewScrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;

      boardViewScrollController
          .animateTo(
        draggedListIndex! * widget.width,
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      )
          .whenComplete(() {
        RenderBox object =
            listStates[tempListIndex!].context.findRenderObject() as RenderBox;

        Offset pos = object.localToGlobal(Offset.zero);

        leftListX = pos.dx;

        rightListX = pos.dx + object.size.width;
        RenderBox box = listStates[tempListIndex]
            .boardItemStates[tempItemIndex!]
            .context
            .findRenderObject() as RenderBox;

        Offset itemPos = box.localToGlobal(Offset.zero);

        topItemY = itemPos.dy;

        bottomItemY = itemPos.dy + box.size.height;

        Future.delayed(
            Duration(
              milliseconds: widget.dragDelay,
            ), () {
          canDrag = true;
        });
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _moveListLeft() {
    var list = widget.lists[draggedListIndex!];
    var listState = listStates[draggedListIndex!];
    widget.lists.removeAt(draggedListIndex!);
    listStates.removeAt(draggedListIndex!);

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }

    widget.lists.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;

    if (boardViewScrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      boardViewScrollController
          .animateTo(
        draggedListIndex! * widget.width,
        duration: Duration(
          milliseconds: widget.dragDelay,
        ),
        curve: Curves.ease,
      )
          .whenComplete(
        () {
          RenderBox object = listStates[tempListIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);
          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;
          Future.delayed(
            Duration(
              milliseconds: widget.dragDelay,
            ),
            () {
              canDrag = true;
            },
          );
        },
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _moveItemToLeftList() {
    var item = widget.lists[draggedListIndex!].items[draggedItemIndex!];
    var itemState =
        listStates[draggedListIndex!].boardItemStates[draggedItemIndex!];
    widget.lists[draggedListIndex!].items.removeAt(draggedItemIndex!);
    listStates[draggedListIndex!].boardItemStates.removeAt(draggedItemIndex!);

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }

    double closestValue = 10000;

    draggedItemIndex = 0;

    for (int i = 0;
        i < listStates[draggedListIndex!].boardItemStates.length;
        i++) {
      if (listStates[draggedListIndex!].boardItemStates[i].mounted) {
        RenderBox box = listStates[draggedListIndex!]
            .boardItemStates[i]
            .context
            .findRenderObject() as RenderBox;
        Offset pos = box.localToGlobal(Offset.zero);

        var temp = (pos.dy - dy! + (box.size.height / 2)).abs();

        if (temp < closestValue) {
          closestValue = temp;
          draggedItemIndex = i;
          dyInit = dy;
        }
      }
    }

    widget.lists[draggedListIndex!].items.insert(
      draggedItemIndex!,
      item,
    );

    listStates[draggedListIndex!].boardItemStates.insert(
          draggedItemIndex!,
          itemState,
        );

    canDrag = false;

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }

    if (boardViewScrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      boardViewScrollController
          .animateTo(
        draggedListIndex! * widget.width,
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      )
          .whenComplete(
        () {
          RenderBox object = listStates[tempListIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);
          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;
          RenderBox box = listStates[tempListIndex]
              .boardItemStates[tempItemIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset itemPos = box.localToGlobal(Offset.zero);
          topItemY = itemPos.dy;
          bottomItemY = itemPos.dy + box.size.height;
          Future.delayed(
            Duration(
              milliseconds: widget.dragDelay,
            ),
            () {
              canDrag = true;
            },
          );
        },
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void run() {
    if (pointer != null) {
      dx = pointer.position.dx;
      dy = pointer.position.dy;
      if (mounted) {
        setState(() {});
      }
    }
  }
}
