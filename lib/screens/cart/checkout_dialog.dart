import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/providers/auth_provider.dart';
import 'package:ecom_app/providers/cart_provider.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/screens/auth/login_screen.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({Key? key}) : super(key: key);

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Card fields
  final _cardNumberCtrl = TextEditingController(text: '4242 •••• •••• 4242');
  final _cardExpiryCtrl = TextEditingController(text: '12/28');
  final _cardCvvCtrl = TextEditingController(text: '888');

  String _paymentMethod = 'cod'; // 'cod' or 'card'
  bool _isSubmitting = false;
  int? _confirmedOrderId;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      _nameCtrl.text = auth.currentUser!.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  void _confirmOrder() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (auth.currentUser == null) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour valider la commande.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final items = cart.cartList
        .map((item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'selected_color': item.selectedColor,
            })
        .toList();

    final res = await ApiService.createOrder(
      userId: auth.currentUser!.id,
      items: items,
      shippingName: _nameCtrl.text.trim(),
      shippingPhone: _phoneCtrl.text.trim(),
      shippingAddress: _addressCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      couponCode: cart.appliedCoupon?.code,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final orderId = int.tryParse(res['data']?['order_id']?.toString() ?? '1') ?? 1;
      cart.clearCart();
      setState(() {
        _isSubmitting = false;
        _confirmedOrderId = orderId;
      });
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(res['message'] ?? 'Erreur lors de la validation.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // If order confirmed, show clean in-place confirmation
    if (_confirmedOrderId != null) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 20),
              Text(
                'Commande #$_confirmedOrderId Confirmée !',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _paymentMethod == 'card'
                    ? 'Paiement par Carte Bancaire validé avec succès (Chiffrement SSL 256 bits). Votre colis est en cours de préparation.'
                    : 'Paiement prévu à la livraison en espèces. Votre colis est en cours de préparation et vous sera livré rapidement.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextLightColor, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mode de paiement :', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _paymentMethod == 'card' ? '💳 Carte Bancaire (CMI)' : '💵 Paiement à la livraison',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour à la boutique', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(kDefaultPadding * 1.2),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Validation de la Commande',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total à payer :', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${cart.totalAmount.toStringAsFixed(2)} DH',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Informations de Livraison', style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom & Prénom',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Téléphone valide requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Adresse de livraison (Ville, Quartier, Rue)',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Adresse requise' : null,
                ),
                const SizedBox(height: 16),

                // Payment Mode Selection
                const Text('Mode de Paiement', style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _paymentMethod = 'cod'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'cod' ? Colors.green.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'cod' ? Colors.green : Colors.grey.shade300,
                              width: _paymentMethod == 'cod' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.local_shipping_outlined, color: _paymentMethod == 'cod' ? Colors.green : Colors.grey),
                              const SizedBox(height: 6),
                              Text(
                                'À la livraison',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _paymentMethod == 'cod' ? Colors.green.shade800 : Colors.grey.shade700,
                                ),
                              ),
                              const Text('Espèces', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _paymentMethod = 'card'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'card' ? Colors.blue.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'card' ? Colors.blue : Colors.grey.shade300,
                              width: _paymentMethod == 'card' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.credit_card_outlined, color: _paymentMethod == 'card' ? Colors.blue : Colors.grey),
                              const SizedBox(height: 6),
                              Text(
                                'Carte Bancaire',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _paymentMethod == 'card' ? Colors.blue.shade800 : Colors.grey.shade700,
                                ),
                              ),
                              const Text('CMI / Visa / MC', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Card details input fields if card selected
                if (_paymentMethod == 'card') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lock_outline, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Paiement sécurisé CMI (Cryptage 256 bits)',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _cardNumberCtrl,
                          decoration: InputDecoration(
                            labelText: 'Numéro de carte',
                            hintText: '4242 4242 4242 4242',
                            prefixIcon: const Icon(Icons.credit_card),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) => _paymentMethod == 'card' && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cardExpiryCtrl,
                                decoration: InputDecoration(
                                  labelText: 'MM/AA',
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                validator: (v) => _paymentMethod == 'card' && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _cardCvvCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'CVV',
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                validator: (v) => _paymentMethod == 'card' && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryColor,
                      foregroundColor: kTextColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _confirmOrder,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            _paymentMethod == 'card' ? 'Payer ${cart.totalAmount.toStringAsFixed(2)} DH' : 'Confirmer l\'Achat',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
