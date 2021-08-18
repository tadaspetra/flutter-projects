import 'package:creatorstudio/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          canvasColor: Colors.grey[300],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              )),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 30),
              ),
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                return Colors.black;
              }),
            ),
          ),
        ),
        home: MyHomePage(),
      ),
    );
  }
}
