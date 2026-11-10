import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/models/order.dart';
import 'package:ecom_app/providers/auth_provider.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/screens/support/support_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      setState(() {
        _ordersFuture = ApiService.getOrders(auth.currentUser!.id);
      });
    } else {
      setState(() {
        _ordersFuture = Future.value([]);
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'livrée':
        return Colors.green;
      case 'shipped':
      case 'expédiée':
        return Colors.blue;
      case 'processing':
      case 'en préparation':
        return Colors.orange;
      case 'confirmed':
      case 'confirmée':
        return Colors.teal;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'LIVRÉE';
      case 'shipped':
        return 'EXPÉDIÉE';
      case 'processing':
        return 'EN PRÉPARATION';
      case 'confirmed':
        return 'CONFIRMÉE';
      default:
        return 'EN ATTENTE';
    }
  }

  void _showInvoiceModal(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ELECTRO STORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
                        Text('Facture & Reçu d\'Achat', style: TextStyle(color: kTextLightColor, fontSize: 12)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Order Meta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Facture N° : INV-${order.id.toString().padLeft(5, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(order.status),
                        style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Date : ${order.createdAt}', style: const TextStyle(color: kTextLightColor, fontSize: 12)),
                const SizedBox(height: 12),

                // Customer Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destinataire :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextColor)),
                      const SizedBox(height: 4),
                      Text('${order.shippingName} • ${order.shippingPhone}', style: const TextStyle(fontSize: 13)),
                      Text(order.shippingAddress, style: const TextStyle(fontSize: 12, color: kTextLightColor)),
                      const SizedBox(height: 4),
                      Text(
                        'Paiement : ${order.paymentMethod.toUpperCase() == 'CARD' ? 'Carte Bancaire CMI' : 'Espèces à la livraison'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tracking Steps Progress
                const Text('Suivi de Livraison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStep(icon: Icons.check, label: 'Reçue', active: true),
                    _buildStepLine(active: order.status != 'pending'),
                    _buildStep(icon: Icons.done_all, label: 'Confirmée', active: order.status != 'pending'),
                    _buildStepLine(active: order.status == 'shipped' || order.status == 'delivered'),
                    _buildStep(icon: Icons.local_shipping, label: 'Expédiée', active: order.status == 'shipped' || order.status == 'delivered'),
                    _buildStepLine(active: order.status == 'delivered'),
                    _buildStep(icon: Icons.home, label: 'Livrée', active: order.status == 'delivered'),
                  ],
                ),
                const SizedBox(height: 16),

                // Items Table
                const Text('Articles Commandés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: order.items.map((item) {
                      final title = item is Map ? (item['title'] ?? 'Article') : 'Article';
                      final qty = item is Map ? (int.tryParse(item['quantity'].toString()) ?? 1) : 1;
                      final price = item is Map ? (double.tryParse((item['unit_price'] ?? item['price'] ?? '0').toString()) ?? 0.0) : 0.0;
                      final color = item is Map ? (item['selected_color']?.toString() ?? '') : '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${qty}x $title${color.isNotEmpty ? ' ($color)' : ''}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(price * qty).toStringAsFixed(2)} DH',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Financial Summary
                if (order.couponCode != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coupon (${order.couponCode}) :', style: const TextStyle(color: Colors.green, fontSize: 13)),
                      Text('-${order.discountAmount.toStringAsFixed(2)} DH', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Frais de livraison :', style: TextStyle(color: kTextLightColor, fontSize: 13)),
                    Text('Gratuits (0 DH)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Net Payé :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                    Text(
                      '${order.totalAmount.toStringAsFixed(2)} DH',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action buttons
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18, color: Colors.white),
                    label: const Text('Télécharger / Imprimer la facture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('Facture INV-${order.id} téléchargée avec succès !'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required IconData icon, required String label, required bool active}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: active ? kPrimaryColor : Colors.grey.shade300,
          child: Icon(icon, size: 13, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? kTextColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool active}) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? kPrimaryColor : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Historique & Suivi des Commandes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadOrders(),
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Aucune commande passée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
                    const SizedBox(height: 6),
                    const Text('Vos commandes apparaîtront ici après validation.', style: TextStyle(color: kTextLightColor)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(kDefaultPadding),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final o = orders[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Commande #${o.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(o.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(o.status).withOpacity(0.5)),
                            ),
                            child: Text(
                              _getStatusLabel(o.status),
                              style: TextStyle(color: _getStatusColor(o.status), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Date : ${o.createdAt}', style: const TextStyle(color: kTextLightColor, fontSize: 13)),
                      Text('Livraison à : ${o.shippingName} (${o.shippingPhone})', style: const TextStyle(fontSize: 13)),
                      Text('Adresse : ${o.shippingAddress}', style: const TextStyle(fontSize: 13, color: kTextLightColor)),
                      if (o.couponCode != null) ...[
                        const SizedBox(height: 4),
                        Text('Coupon appliqué : ${o.couponCode} (-${o.discountAmount.toStringAsFixed(2)} DH)',
                            style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${o.items.length} article(s)', style: const TextStyle(color: kTextLightColor)),
                          Text(
                            'Total : ${o.totalAmount.toStringAsFixed(2)} DH',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimaryColor,
                                  side: const BorderSide(color: kPrimaryColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.receipt_long_outlined, size: 17),
                                label: const Text('Facture & Suivi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                onPressed: () => _showInvoiceModal(o),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade800,
                                  side: BorderSide(color: Colors.orange.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.support_agent_rounded, size: 17),
                                label: const Text('Modifier / SAV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SupportScreen(
                                        initialOrderId: o.id,
                                        initialSubject: 'Demande sur Commande #${o.id}',
                                        initialCategory: 'Modification commande',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
