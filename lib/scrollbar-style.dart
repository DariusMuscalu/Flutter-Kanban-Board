import 'package:flutter/material.dart';

class ScrollbarStyle {
  double hoverThickness;
  double thickness;
  Radius radius;
  Color color;
  ScrollbarStyle({
    this.radius = const Radius.circular(10),
    this.hoverThickness = 10,
    this.thickness = 10,
    this.color = Colors.black,
  });
}
