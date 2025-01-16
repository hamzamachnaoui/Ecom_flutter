import 'package:ecom_app/Screens/home_screen.dart';
import 'package:ecom_app/constans.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme:
          ThemeData(primaryColor: kPrimaryColor, accentColor: kSecondaryColor),
      home: HomeScreen(),
    );
  }
}
