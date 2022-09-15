import 'package:boardview/boardview.dart';
import 'package:flutter/animation.dart';

/// THIS IS USED FOR SOME KIND OF ANIMATION, THAT'S ALL I KNOW AT THIS MOMENT
class BoardViewController {
  late BoardViewState state;

  Future<void> animateTo(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    double offset = index * state.widget.width;

    if (state.boardViewScrollController.hasClients) {
      await state.boardViewScrollController.animateTo(
        offset,
        duration: duration!,
        curve: curve!,
      );
    }
  }
}
