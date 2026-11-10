import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/providers/cart_provider.dart';
import 'package:ecom_app/screens/cart/checkout_dialog.dart';
import 'package:ecom_app/widgets/product_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (cart.cartList.isEmpty) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Mon Panier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.remove_shopping_cart_outlined, size: 90, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Votre panier est vide',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explorez notre catalogue et ajoutez vos coups de cœur !',
                style: TextStyle(color: kTextLightColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mon Panier (${cart.itemCount})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Vider le panier',
            onPressed: () {
              cart.clearCart();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Items list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(kDefaultPadding),
              itemCount: cart.cartList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cart.cartList[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ProductImageWidget(imagePath: item.displayImage, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (item.selectedColor.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Couleur : ${item.selectedColor}',
                                style: const TextStyle(fontSize: 11.5, color: kTextLightColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${item.product.price} DH',
                              style: const TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1, selectedColor: item.selectedColor),
                              constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1, selectedColor: item.selectedColor),
                              constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                        onPressed: () => cart.removeFromCart(item.product.id, selectedColor: item.selectedColor),
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // Coupon & Checkout Bottom Section
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -4))
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Promo code input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Code Coupon (ex: BIENVENUE10)',
                            prefixIcon: const Icon(Icons.confirmation_number_outlined, color: kPrimaryColor),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: cart.isCheckingCoupon
                            ? null
                            : () async {
                                final success = await cart.applyCoupon(_couponCtrl.text);
                                if (!mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.green,
                                      content: Text('Coupon appliqué !'),
                                    ),
                                  );
                                  _couponCtrl.clear();
                                } else if (cart.couponError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(cart.couponError!),
                                    ),
                                  );
                                }
                              },
                        child: cart.isCheckingCoupon
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Appliquer'),
                      )
                    ],
                  ),

                  // Applied coupon badge if any
                  if (cart.appliedCoupon != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Coupon appliqué : ${cart.appliedCoupon!.code} (-${cart.discountAmount.toStringAsFixed(2)} DH)',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.green, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => cart.removeCoupon(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Calculation rows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sous-total :', style: TextStyle(color: kTextLightColor)),
                      Text('${cart.subtotal.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (cart.appliedCoupon != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remise coupon :', style: TextStyle(color: Colors.green)),
                        Text('-${cart.discountAmount.toStringAsFixed(2)} DH', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Livraison :', style: TextStyle(color: kTextLightColor)),
                      Text('Gratuite', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total à payer :',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      Text(
                        '${cart.totalAmount.toStringAsFixed(2)} DH',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSecondaryColor,
                        foregroundColor: kTextColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CheckoutDialog(),
                        );
                      },
                      child: const Text(
                        'Valider la commande',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

