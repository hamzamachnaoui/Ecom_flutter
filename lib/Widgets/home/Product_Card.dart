import 'package:ecom_app/Screens/Product.dart';
import 'package:ecom_app/constans.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    Key? key,
    required this.ProductIndex,
    required this.produit,
  }) : super(key: key);

  final int ProductIndex;
  final Product produit;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      height: 190.0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 170.0,
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      blurRadius: 40,
                      color: Colors.black12,
                      offset: Offset(0, 15))
                ],
                borderRadius: BorderRadius.circular(40)),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
              height: 160.0,
              child: Image.asset(
                produit.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
              height: 136.0,
              right: 0.0,
              width: size.width - 200,
              child: SizedBox(
                child: Column(
                  children: [
                    Text(produit.title.toString(),
                        style: Theme.of(context).textTheme.bodyText1),
                    SizedBox(height: 10.0),
                    Text(produit.subTitle,
                        style: Theme.of(context).textTheme.caption),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        child: Text(produit.price.toString() + " DH"),
                        padding: EdgeInsets.symmetric(
                          horizontal: kDefaultPadding * 1.5,
                          vertical: kDefaultPadding / 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: kSecondaryColor,
                        ),
                      ),
                    )
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
