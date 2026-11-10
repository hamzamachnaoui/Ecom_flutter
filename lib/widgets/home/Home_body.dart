import 'package:ecom_app/screens/Product.dart';
import 'package:ecom_app/widgets/home/Product_Card.dart';
import 'package:ecom_app/constans.dart';
import 'package:flutter/material.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: kDefaultPadding / 2),
          Expanded(
              child: Stack(
            children: [
              Container(
                margin: EdgeInsets.only(top: 70.0),
                decoration: const BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40))),
              ),
              ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    ProductCard(ProductIndex: index, produit: products[index]),
              )
            ],
          ))
        ],
      ),
    );
  }
}
