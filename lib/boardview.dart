library boardview;

import 'package:boardview/boardview_controller.dart';
import 'package:boardview/scrollbar-style.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:boardview/board_list.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

//ignore: must_be_immutable
class BoardView extends StatefulWidget {
  final List<BoardList>? lists;
  final double width;
  Widget? middleWidget;
  double? bottomPadding;
  bool isSelecting;
  bool? scrollbar;
  ScrollbarStyle? scrollbarStyle;
  BoardViewController? boardViewController;
  int dragDelay;

  Function(bool)? itemInMiddleWidget;
  OnDropBottomWidget? onDropItemInMiddleWidget;
  BoardView({
    this.itemInMiddleWidget,
    this.scrollbar,
    this.scrollbarStyle,
    this.boardViewController,
    this.dragDelay = 300,
    this.onDropItemInMiddleWidget,
    this.isSelecting = false,
    this.lists,
    this.width = 280,
    this.middleWidget,
    this.bottomPadding,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardViewState();
  }
}

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

class BoardViewState extends State<BoardView>
    with AutomaticKeepAliveClientMixin {
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
  double? rightListX;
  double? leftListX;
  double? topListY;
  double? bottomListY;
  double? topItemY;
  double? bottomItemY;
  double? height;
  int? startListIndex;
  int? startItemIndex;

  bool canDrag = true;

  ScrollController scrollController = ScrollController();

  List<BoardListState> listStates = [];

  OnDropItem? onDropItem;
  OnDropList? onDropList;

  bool isScrolling = false;

  bool _isInWidget = false;

  GlobalKey _middleWidgetKey = GlobalKey();

  var pointer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.boardViewController != null) {
      widget.boardViewController!.state = this;
    }
  }

  void moveDraggedItemBelowAnother() {
    if (topItemY != null) {
      topItemY = topItemY! +
          listStates[draggedListIndex!]
              .itemStates[draggedItemIndex! + 1]
              .height;
    }

    if (bottomItemY != null) {
      bottomItemY = bottomItemY! +
          listStates[draggedListIndex!]
              .itemStates[draggedItemIndex! + 1]
              .height;
    }

    var item = widget.lists![draggedListIndex!].items![draggedItemIndex!];
    widget.lists![draggedListIndex!].items!.removeAt(draggedItemIndex!);
    var itemState = listStates[draggedListIndex!].itemStates[draggedItemIndex!];
    listStates[draggedListIndex!].itemStates.removeAt(draggedItemIndex!);
    if (draggedItemIndex != null) {
      draggedItemIndex = draggedItemIndex! + 1;
    }
    widget.lists![draggedListIndex!].items!.insert(draggedItemIndex!, item);
    listStates[draggedListIndex!]
        .itemStates
        .insert(draggedItemIndex!, itemState);
    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }
  }

  void moveItemAboveAnotherOne() {
    if (topItemY != null) {
      topItemY = topItemY! -
          listStates[draggedListIndex!]
              .itemStates[draggedItemIndex! - 1]
              .height;
    }

    if (bottomItemY != null) {
      bottomItemY = bottomItemY! -
          listStates[draggedListIndex!]
              .itemStates[draggedItemIndex! - 1]
              .height;
    }

    if (draggedItemIndex != null) {
      draggedItemIndex = draggedItemIndex! - 1;
    }

    var item = widget.lists![draggedListIndex!].items![draggedItemIndex!];
    widget.lists![draggedListIndex!].items!.removeAt(draggedItemIndex!);
    var itemState = listStates[draggedListIndex!].itemStates[draggedItemIndex!];
    listStates[draggedListIndex!].itemStates.removeAt(draggedItemIndex!);

    widget.lists![draggedListIndex!].items!.insert(draggedItemIndex!, item);
    listStates[draggedListIndex!]
        .itemStates
        .insert(draggedItemIndex!, itemState);

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(
        () {},
      );
    }
  }

  void moveListRight() {
    var list = widget.lists![draggedListIndex!];

    var listState = listStates[draggedListIndex!];

    widget.lists!.removeAt(draggedListIndex!);

    listStates.removeAt(draggedListIndex!);

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }

    widget.lists!.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;

    if (scrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      scrollController
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

  void moveItemToRightList() {
    var item = widget.lists![draggedListIndex!].items![draggedItemIndex!];
    var itemState = listStates[draggedListIndex!].itemStates[draggedItemIndex!];
    widget.lists![draggedListIndex!].items!.removeAt(draggedItemIndex!);
    listStates[draggedListIndex!].itemStates.removeAt(draggedItemIndex!);
    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }
    double closestValue = 10000;
    draggedItemIndex = 0;
    for (int i = 0; i < listStates[draggedListIndex!].itemStates.length; i++) {
      if (listStates[draggedListIndex!].itemStates[i].mounted &&
          listStates[draggedListIndex!].itemStates[i].context != null) {
        RenderBox box = listStates[draggedListIndex!]
            .itemStates[i]
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
    widget.lists![draggedListIndex!].items!.insert(draggedItemIndex!, item);
    listStates[draggedListIndex!]
        .itemStates
        .insert(draggedItemIndex!, itemState);
    canDrag = false;
    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }
    if (scrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      scrollController
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
            .itemStates[tempItemIndex!]
            .context
            .findRenderObject() as RenderBox;
        Offset itemPos = box.localToGlobal(Offset.zero);
        topItemY = itemPos.dy;
        bottomItemY = itemPos.dy + box.size.height;
        Future.delayed(new Duration(milliseconds: widget.dragDelay), () {
          canDrag = true;
        });
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void moveListLeft() {
    var list = widget.lists![draggedListIndex!];
    var listState = listStates[draggedListIndex!];
    widget.lists!.removeAt(draggedListIndex!);
    listStates.removeAt(draggedListIndex!);

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }

    widget.lists!.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;

    if (scrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      scrollController
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

  void moveItemToLeftList() {
    var item = widget.lists![draggedListIndex!].items![draggedItemIndex!];
    var itemState = listStates[draggedListIndex!].itemStates[draggedItemIndex!];
    widget.lists![draggedListIndex!].items!.removeAt(draggedItemIndex!);
    listStates[draggedListIndex!].itemStates.removeAt(draggedItemIndex!);

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }

    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }

    double closestValue = 10000;

    draggedItemIndex = 0;

    for (int i = 0; i < listStates[draggedListIndex!].itemStates.length; i++) {
      if (listStates[draggedListIndex!].itemStates[i].mounted &&
          listStates[draggedListIndex!].itemStates[i].context != null) {
        RenderBox box = listStates[draggedListIndex!]
            .itemStates[i]
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

    widget.lists![draggedListIndex!].items!.insert(
      draggedItemIndex!,
      item,
    );

    listStates[draggedListIndex!].itemStates.insert(
          draggedItemIndex!,
          itemState,
        );

    canDrag = false;

    if (listStates[draggedListIndex!].mounted) {
      listStates[draggedListIndex!].setState(() {});
    }

    if (scrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      scrollController
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
              .itemStates[tempItemIndex!]
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

  bool shown = true;

  @override
  Widget build(BuildContext context) {
    // DEBUGGING
    print("dy:$dy");
    print("topListY:$topListY");
    print("bottomListY:$bottomListY");

    if (scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        try {
          scrollController.position.didUpdateScrollPositionBy(0);
        } catch (e) {}
        bool _shown = scrollController.position.maxScrollExtent != 0;
        if (_shown != shown) {
          setState(() {
            shown = _shown;
          });
        }
      });
    }

    Widget listWidget = ListView.builder(
      physics: ClampingScrollPhysics(),
      itemCount: widget.lists!.length,
      scrollDirection: Axis.horizontal,
      controller: scrollController,
      itemBuilder: (BuildContext context, int index) {
        if (widget.lists![index].boardView == null) {
          widget.lists![index] = BoardList(
            items: widget.lists![index].items,
            headerBackgroundColor: widget.lists![index].headerBackgroundColor,
            backgroundColor: widget.lists![index].backgroundColor,
            footer: widget.lists![index].footer,
            header: widget.lists![index].header,
            boardView: this,
            isDraggable: widget.lists![index].isDraggable,
            onDropList: widget.lists![index].onDropList,
            onTapList: widget.lists![index].onTapList,
            onStartDragList: widget.lists![index].onStartDragList,
          );
        }

        if (widget.lists![index].index != index) {
          widget.lists![index] = BoardList(
            items: widget.lists![index].items,
            headerBackgroundColor: widget.lists![index].headerBackgroundColor,
            backgroundColor: widget.lists![index].backgroundColor,
            footer: widget.lists![index].footer,
            header: widget.lists![index].header,
            boardView: this,
            isDraggable: widget.lists![index].isDraggable,
            index: index,
            onDropList: widget.lists![index].onDropList,
            onTapList: widget.lists![index].onTapList,
            onStartDragList: widget.lists![index].onStartDragList,
          );
        }

        var temp = Container(
          width: widget.width,
          padding: EdgeInsets.fromLTRB(0, 0, 0, widget.bottomPadding ?? 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[Expanded(child: widget.lists![index])],
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

    if (widget.scrollbar == true) {
      listWidget = VsScrollbar(
          controller: scrollController,
          showTrackOnHover: true, // default false
          isAlwaysShown: shown && widget.lists!.length > 1, // default false
          scrollbarFadeDuration: Duration(
            milliseconds: 500,
          ), // default : Duration(milliseconds: 300)
          scrollbarTimeToFade: Duration(
            milliseconds: 800,
          ), // default : Duration(milliseconds: 600)
          style: widget.scrollbarStyle != null
              ? VsScrollbarStyle(
                  hoverThickness: widget.scrollbarStyle!.hoverThickness,
                  radius: widget.scrollbarStyle!.radius,
                  thickness: widget.scrollbarStyle!.thickness,
                  color: widget.scrollbarStyle!.color)
              : VsScrollbarStyle(),
          child: listWidget);
    }
    List<Widget> stackWidgets = <Widget>[listWidget];
    bool isInBottomWidget = false;
    if (dy != null) {
      if (MediaQuery.of(context).size.height - dy! < 80) {
        isInBottomWidget = true;
      }
    }
    if (widget.itemInMiddleWidget != null && _isInWidget != isInBottomWidget) {
      widget.itemInMiddleWidget!(isInBottomWidget);
      _isInWidget = isInBottomWidget;
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
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.pixels - 5,
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
          if (widget.lists!.length > draggedListIndex! + 1 &&
              dx! > rightListX! - 45) {
            //scroll right
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.pixels + 5,
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
            moveItemToLeftList();
          }

          /// Same as the above comment but for moving to right
          if (widget.lists!.length > draggedListIndex! + 1 &&
              dx! > rightListX!) {
            moveItemToRightList();
          }

          if (dy! < topListY! + 70) {
            //scroll up
            if (listStates[draggedListIndex!].boardListController != null &&
                listStates[draggedListIndex!].boardListController.hasClients &&
                !isScrolling) {
              isScrolling = true;
              double pos = listStates[draggedListIndex!]
                  .boardListController
                  .position
                  .pixels;
              listStates[draggedListIndex!]
                  .boardListController
                  .animateTo(
                    listStates[draggedListIndex!]
                            .boardListController
                            .position
                            .pixels -
                        5,
                    duration: Duration(milliseconds: 10),
                    curve: Curves.ease,
                  )
                  .whenComplete(
                () {
                  pos -= listStates[draggedListIndex!]
                      .boardListController
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
                              .itemStates[draggedItemIndex! - 1]
                              .height /
                          2) {
            /// Looks like if you place 2 items in a column and trying to place the dragged
            /// item above the one in the column it wont work if you disable this method.
            /// So I decided to rename it from moveUp() to moveItemAboveAnotherOne().
            moveItemAboveAnotherOne();
          }

          double? tempBottom = bottomListY;

          if (widget.middleWidget != null) {
            if (_middleWidgetKey.currentContext != null) {
              RenderBox _box = _middleWidgetKey.currentContext!
                  .findRenderObject() as RenderBox;
              tempBottom = _box.size.height;

              // DEBUGGING
              print("tempBottom:$tempBottom");
            }
          }

          /// Comment inside says SCROLL DOWN.
          /// TODO Do further research to understand what it does
          if (dy! > tempBottom! - 70) {
            //scroll down

            if (listStates[draggedListIndex!].boardListController != null &&
                listStates[draggedListIndex!].boardListController.hasClients) {
              isScrolling = true;
              double pos = listStates[draggedListIndex!]
                  .boardListController
                  .position
                  .pixels;
              listStates[draggedListIndex!]
                  .boardListController
                  .animateTo(
                    listStates[draggedListIndex!]
                            .boardListController
                            .position
                            .pixels +
                        5,
                    duration: Duration(milliseconds: 10),
                    curve: Curves.ease,
                  )
                  .whenComplete(
                () {
                  pos -= listStates[draggedListIndex!]
                      .boardListController
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
          if (widget.lists![draggedListIndex!].items!.length >
                  draggedItemIndex! + 1 &&
              dy! >
                  bottomItemY! +
                      listStates[draggedListIndex!]
                              .itemStates[draggedItemIndex! + 1]
                              .height /
                          2) {
            moveDraggedItemBelowAnother();
          }
        } else {
          //dragging list
          if (0 <= draggedListIndex! - 1 && dx! < leftListX! + 45) {
            //scroll left
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.pixels - 5,
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

          if (widget.lists!.length > draggedListIndex! + 1 &&
              dx! > rightListX! - 45) {
            //scroll right
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.pixels + 5,
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

          if (widget.lists!.length > draggedListIndex! + 1 &&
              dx! > rightListX!) {
            //move right
            moveListRight();
          }

          if (0 <= draggedListIndex! - 1 && dx! < leftListX!) {
            //move left
            moveListLeft();
          }
        }
      }

      if (widget.middleWidget != null) {
        stackWidgets.add(
          Container(
            key: _middleWidgetKey,
            child: widget.middleWidget,
          ),
        );
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
      height: 650,
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
