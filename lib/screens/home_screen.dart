import 'package:ecom_app/widgets/home/Home_body.dart';
import 'package:ecom_app/constans.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: HomeAppBar(),
      body: HomeBody(),
    );
  }

  AppBar HomeAppBar() {
    return AppBar(
      backgroundColor: kPrimaryColor,
      title: Text("E commerce App"),
      elevation: 0,
      actions: [IconButton(onPressed: (() => {}), icon: Icon(Icons.menu))],
    );
  }
}
