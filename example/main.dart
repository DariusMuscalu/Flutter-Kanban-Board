import 'package:flutter/material.dart';

import 'example.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welceee',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcod Flutter'),
        ),
        body: BoardViewExample(),
      ),
    );
  }
}
