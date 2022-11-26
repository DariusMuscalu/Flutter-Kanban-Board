# Project is still in progress, not finished!

# BoardView
Board view is the content which contains the lists with their items inside them and is the place where you can see the
dragged item, if trying to drag the item outside the board view, it doesn't show, it is only visible inside the board view.

# BoardViewController
boardview-controller is used for the animation.

# App example
![Example](https://github.com/jakebonk/FlutterBoardView/blob/master/images/example.gif?raw=true)

### BoardList

The BoardList has several callback methods for when it is being dragged. The header item is a Row and expects a List<Widget> as its object. The header item on long press will begin the drag process for the BoardList.

``` dart

    BoardList(
      onStartDragList: (int listIndex) {
    
      },
      onTapList: (int listIndex) async {
    
      },
      onDropList: (int listIndex, int oldListIndex) {       
       
      },
      headerBackgroundColor: Color.fromARGB(255, 235, 236, 240),
      backgroundColor: Color.fromARGB(255, 235, 236, 240),
      header: [
        Expanded(
            child: Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  "List Item",
                  style: TextStyle(fontSize: 20),
                ))),
      ],
      items: items,
    );

```

### BoardItem

The BoardItem view has several callback methods that get called when dragging. A long press on the item field widget will begin the drag process.

``` dart

    BoardItem(
        onStartDragItem: (int listIndex, int itemIndex, BoardItemState state) {
        
        },
        onDropItem: (int listIndex, int itemIndex, int oldListIndex,
            int oldItemIndex, BoardItemState state) {
                      
        },
        onTapItem: (int listIndex, int itemIndex, BoardItemState state) async {
        
        },
        item: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Board Item"),
          ),
        )
    );

```
