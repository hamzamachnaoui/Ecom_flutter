import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/models/order.dart';
import 'package:ecom_app/models/product.dart';
import 'package:ecom_app/models/support_ticket.dart';
import 'package:ecom_app/providers/auth_provider.dart';
import 'package:ecom_app/services/api_service.dart';

class SupportScreen extends StatefulWidget {
  final String? initialSubject;
  final int? initialOrderId;
  final String? initialCategory;
  final int? initialProductId;
  final String? initialProductTitle;

  const SupportScreen({
    Key? key,
    this.initialSubject,
    this.initialOrderId,
    this.initialCategory,
    this.initialProductId,
    this.initialProductTitle,
  }) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _orderIdCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _selectedCategory = 'Question produit';
  String _priority = 'normale';
  int? _selectedProductId;
  String? _selectedProductTitle;
  int? _selectedOrderId;

  bool _isSubmitting = false;
  bool _loadingTickets = true;
  bool _loadingRefs = true;

  List<SupportTicketModel> _tickets = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  String _ticketFilter = 'all';

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Question produit', 'icon': Icons.help_outline_rounded},
    {'label': 'Panne / SAV', 'icon': Icons.build_circle_outlined},
    {'label': 'Livraison', 'icon': Icons.local_shipping_outlined},
    {'label': 'Modification commande', 'icon': Icons.edit_note_rounded},
    {'label': 'Autre', 'icon': Icons.chat_bubble_outline_rounded},
  ];

  static const List<Map<String, String>> _faqItems = [
    {
      'q': 'Comment déclarer une panne ou activer la garantie SAV ?',
      'a': 'Depuis l\'onglet "Signaler / Contacter", choisissez la catégorie "Panne / SAV", sélectionnez le produit ou la commande concernée et décrivez les symptômes (voyant, bruit, alimentation...). Notre atelier technique répond sous 24h ouvrées.',
    },
    {
      'q': 'Puis-je modifier ou annuler une commande déjà passée ?',
      'a': 'Oui, tant que votre commande n\'est pas encore expédiée ("confirmed" ou "processing"). Sélectionnez "Modification commande", indiquez la commande concernée et précisez les articles ou quantités à ajuster.',
    },
    {
      'q': 'Quelle est la durée de garantie sur Electro Store ?',
      'a': 'Tous nos appareils neufs bénéficient d\'une garantie constructeur et SAV Electro Store de 12 à 24 mois, ainsi que d\'un échange express sous 7 jours en cas de défaut constaté au déballage.',
    },
    {
      'q': 'Comment ajouter une précision sur un dossier déjà ouvert ?',
      'a': 'Dans l\'onglet "Mes Tickets", cliquez sur "Ajouter précision" sur votre demande. Vous pouvez également marquer un dossier comme résolu ou le réouvrir en envoyant un nouveau message.',
    },
    {
      'q': 'Quels sont les délais de livraison ?',
      'a': 'Les commandes confirmées sont expédiées sous 24h et livrées sous 24h à 72h partout au Maroc avec paiement à la livraison ou suivi en ligne.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      _nameCtrl.text = auth.currentUser!.name;
      _emailCtrl.text = auth.currentUser!.email;
    }
    if (widget.initialSubject != null) {
      _subjectCtrl.text = widget.initialSubject!;
    }
    if (widget.initialOrderId != null) {
      _selectedOrderId = widget.initialOrderId;
      _orderIdCtrl.text = widget.initialOrderId.toString();
    }
    if (widget.initialProductId != null) {
      _selectedProductId = widget.initialProductId;
      _selectedProductTitle = widget.initialProductTitle;
    }
    final validCats = _categories.map((c) => c['label'] as String).toList();
    if (widget.initialCategory != null && validCats.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _orderIdCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadReferenceLists(),
      _loadTickets(),
    ]);
  }

  Future<void> _loadReferenceLists() async {
    setState(() => _loadingRefs = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final prodFuture = ApiService.getProducts();
    final orderFuture = auth.currentUser != null
        ? ApiService.getOrders(auth.currentUser!.id)
        : Future.value(<OrderModel>[]);

    final prodRes = await prodFuture;
    final ordersRes = await orderFuture;

    if (!mounted) return;
    final loadedProducts = prodRes['success'] == true
        ? List<ProductModel>.from(prodRes['products'] ?? [])
        : <ProductModel>[];

    // Sync initial product title if only ID was passed
    if (_selectedProductId != null && (_selectedProductTitle == null || _selectedProductTitle!.isEmpty)) {
      final match = loadedProducts.where((p) => p.id == _selectedProductId).toList();
      if (match.isNotEmpty) {
        _selectedProductTitle = match.first.title;
      }
    }

    setState(() {
      _products = loadedProducts;
      _orders = ordersRes;
      _loadingRefs = false;
    });
  }

  Future<void> _loadTickets() async {
    if (mounted) setState(() => _loadingTickets = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailCtrl.text.trim();
    final list = await ApiService.getSupportTickets(
      userId: auth.currentUser?.id,
      email: email.isNotEmpty ? email : null,
    );
    if (!mounted) return;
    setState(() {
      _tickets = list;
      _loadingTickets = false;
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final parsedOrderId = _selectedOrderId ?? int.tryParse(_orderIdCtrl.text.trim());

    final res = await ApiService.createSupportTicket(
      userId: auth.currentUser?.id,
      userName: _nameCtrl.text.trim(),
      userEmail: _emailCtrl.text.trim(),
      category: _selectedCategory,
      priority: _priority,
      subject: _subjectCtrl.text.trim(),
      orderId: parsedOrderId,
      productId: _selectedProductId,
      productTitle: _selectedProductTitle,
      message: _messageCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _priority = 'normale';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(res['message'] ?? 'Votre ticket SAV a été enregistré !'),
        ),
      );
      await _loadTickets();
      if (mounted) {
        _tabController.animateTo(1);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(res['message'] ?? 'Impossible d\'envoyer le ticket.'),
        ),
      );
    }
  }

  Future<void> _openFollowupDialog(SupportTicketModel ticket) async {
    final msgCtrl = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.reply_rounded, color: kPrimaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Précision — Ticket #${ticket.id}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ticket.status == 'resolved')
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'Ce ticket est actuellement résolu. L\'envoi d\'un message le réouvrira automatiquement.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Votre message complémentaire',
                hintText: 'Ex: Numéro de série, précision sur la panne, disponibilité...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = msgCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
    msgCtrl.dispose();

    if (submitted == null || submitted.isEmpty) return;

    final res = await ApiService.sendSupportFollowup(
      ticketId: ticket.id,
      action: 'followup',
      message: submitted,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
        content: Text(res['message'] ?? 'Mise à jour effectuée'),
      ),
    );
    if (res['success'] == true) {
      _loadTickets();
    }
  }

  Future<void> _markTicketResolved(SupportTicketModel ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clôturer le ticket ?'),
        content: Text('Confirmez-vous que le dossier #${ticket.id} ("${ticket.subject}") est résolu ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, résolu'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.sendSupportFollowup(
      ticketId: ticket.id,
      action: 'resolve',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
        content: Text(res['message'] ?? 'Statut mis à jour'),
      ),
    );
    if (res['success'] == true) {
      _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _tickets.where((t) => t.status == 'open' || t.status == 'in_progress').length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kTextColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Centre Support & SAV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Electro Store — Assistance, Pannes & Commandes', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kSecondaryColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: [
            const Tab(icon: Icon(Icons.edit_document, size: 18), text: 'Signaler / Contacter'),
            Tab(
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              text: openCount > 0 ? 'Mes Tickets ($openCount)' : 'Mes Tickets',
            ),
            const Tab(icon: Icon(Icons.verified_user_outlined, size: 18), text: 'FAQ & Garantie'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormTab(),
              _buildTicketsTab(),
              _buildFaqTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTab() {
    final productDropdownItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('Aucun produit spécifique')),
      ..._products.map((p) => DropdownMenuItem<int?>(
            value: p.id,
            child: Text('${p.title} (${p.price} DH)', overflow: TextOverflow.ellipsis),
          )),
    ];
    // Preserve initialProductId even if catalog hasn't matched it yet
    if (_selectedProductId != null && !_products.any((p) => p.id == _selectedProductId)) {
      productDropdownItems.add(
        DropdownMenuItem<int?>(
          value: _selectedProductId,
          child: Text(_selectedProductTitle?.isNotEmpty == true ? _selectedProductTitle! : 'Produit #$_selectedProductId'),
        ),
      );
    }

    final orderDropdownItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('Aucune commande liée')),
      ..._orders.map((o) => DropdownMenuItem<int?>(
            value: o.id,
            child: Text('Commande #${o.id} — ${o.totalAmount.toStringAsFixed(0)} DH (${o.status})'),
          )),
    ];
    if (_selectedOrderId != null && _orders.isNotEmpty && !_orders.any((o) => o.id == _selectedOrderId)) {
      orderDropdownItems.add(
        DropdownMenuItem<int?>(
          value: _selectedOrderId,
          child: Text('Commande #$_selectedOrderId'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF023047), Color(0xFF219EBC)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.build_circle_outlined, color: Colors.white, size: 28),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Un souci technique ou une question ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5)),
                      SizedBox(height: 4),
                      Text(
                        'Liez directement votre produit ou commande pour accélérer la prise en charge SAV Electro Store.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Nature de la demande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final label = cat['label'] as String;
                      final icon = cat['icon'] as IconData;
                      final selected = _selectedCategory == label;
                      return ChoiceChip(
                        avatar: Icon(icon, size: 17, color: selected ? Colors.white : kPrimaryColor),
                        label: Text(label),
                        selected: selected,
                        selectedColor: kPrimaryColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : kTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = label;
                            if (label == 'Panne / SAV' && _subjectCtrl.text.isEmpty) {
                              _subjectCtrl.text = 'Signalement panne matériel';
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Niveau d\'urgence :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kTextColor)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Normale'),
                        selected: _priority == 'normale',
                        selectedColor: const Color(0xFF023047),
                        labelStyle: TextStyle(color: _priority == 'normale' ? Colors.white : kTextColor, fontSize: 12),
                        onSelected: (_) => setState(() => _priority = 'normale'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: Icon(Icons.priority_high_rounded, size: 16, color: _priority == 'urgente' ? Colors.white : Colors.red),
                        label: const Text('Urgente (Panne / Blocage)'),
                        selected: _priority == 'urgente',
                        selectedColor: const Color(0xFFD90429),
                        labelStyle: TextStyle(color: _priority == 'urgente' ? Colors.white : const Color(0xFFD90429), fontWeight: FontWeight.bold, fontSize: 12),
                        onSelected: (_) => setState(() => _priority = 'urgente'),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  const Text('2. Produit / Commande & Coordonnées', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _selectedProductId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Article concerné (optionnel)',
                      prefixIcon: const Icon(Icons.devices_other_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _loadingRefs
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                          : null,
                    ),
                    items: productDropdownItems,
                    onChanged: (val) {
                      setState(() {
                        _selectedProductId = val;
                        if (val == null) {
                          _selectedProductTitle = null;
                        } else {
                          final match = _products.where((p) => p.id == val).toList();
                          _selectedProductTitle = match.isNotEmpty ? match.first.title : _selectedProductTitle;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_orders.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: _selectedOrderId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Commande concernée (optionnel)',
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: orderDropdownItems,
                      onChanged: (val) {
                        setState(() {
                          _selectedOrderId = val;
                          _orderIdCtrl.text = val?.toString() ?? '';
                        });
                      },
                    )
                  else
                    TextFormField(
                      controller: _orderIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'N° de commande (optionnel)',
                        hintText: 'Ex: 12',
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Votre nom',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Votre email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Email valide requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectCtrl,
                    decoration: InputDecoration(
                      labelText: 'Objet de la demande',
                      hintText: 'Ex: Écran ne s\'allume plus / Modifier quantité',
                      prefixIcon: const Icon(Icons.subject),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Objet requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description détaillée',
                      hintText: 'Décrivez la panne constatée, les symptômes ou les articles à ajouter/retirer de votre commande...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().length < 5 ? 'Veuillez préciser votre message' : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _priority == 'urgente' ? const Color(0xFFD90429) : kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submitTicket,
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSubmitting ? 'Envoi en cours...' : 'Envoyer la demande SAV',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildTicketsTab() {
    if (_loadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }

    final counts = {
      'all': _tickets.length,
      'open': _tickets.where((t) => t.status == 'open').length,
      'in_progress': _tickets.where((t) => t.status == 'in_progress').length,
      'resolved': _tickets.where((t) => t.status == 'resolved').length,
    };

    final filtered = _ticketFilter == 'all'
        ? _tickets
        : _tickets.where((t) => t.status == _ticketFilter).toList();

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tous (${counts['all']})'),
                const SizedBox(width: 8),
                _buildFilterChip('open', 'Ouverts (${counts['open']})'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'En cours (${counts['in_progress']})'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Résolus (${counts['resolved']})'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 52, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    _tickets.isEmpty
                        ? 'Aucun ticket SAV pour cet email.'
                        : 'Aucun ticket dans ce filtre.',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Utilisez l\'onglet "Signaler / Contacter" pour ouvrir un dossier.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Créer un ticket'),
                  ),
                ],
              ),
            )
          else
            ...filtered.map(_buildTicketCard),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _ticketFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: kTextColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : kTextColor,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      onSelected: (_) => setState(() => _ticketFilter = value),
    );
  }

  Map<String, dynamic> _statusMeta(String status) {
    switch (status) {
      case 'resolved':
        return {'color': Colors.green, 'label': 'Résolu', 'step': 2};
      case 'in_progress':
        return {'color': Colors.blue, 'label': 'En cours', 'step': 1};
      default:
        return {'color': Colors.orange, 'label': 'Ouvert', 'step': 0};
    }
  }

  Widget _buildStatusProgress(String status) {
    final meta = _statusMeta(status);
    final currentStep = meta['step'] as int;
    const steps = ['Reçu', 'Diagnostic', 'Résolu'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final barIndex = index ~/ 2;
            final active = currentStep > barIndex;
            return Expanded(
              child: Container(
                height: 3,
                color: active ? kPrimaryColor : Colors.grey.shade200,
              ),
            );
          }
          final stepIdx = index ~/ 2;
          final active = currentStep >= stepIdx;
          final color = status == 'resolved' && stepIdx == 2 ? Colors.green : (active ? kPrimaryColor : Colors.grey.shade300);
          return Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  active ? Icons.check : Icons.circle,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[stepIdx],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? kTextColor : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel t) {
    final meta = _statusMeta(t.status);
    final Color statusColor = meta['color'] as Color;
    final String statusLabel = meta['label'] as String;
    final isUrgent = t.priority == 'urgente';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent && t.status != 'resolved' ? Colors.red.shade200 : Colors.grey.shade200,
          width: isUrgent ? 1.4 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('#${t.id} • ${t.category}', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
              if (isUrgent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFD90429), borderRadius: BorderRadius.circular(8)),
                  child: const Text('URGENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: kTextColor)),
          if (t.createdAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Ouvert le ${t.createdAt}', style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
            ),
          if (t.productTitle.isNotEmpty || t.orderId != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (t.productTitle.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.devices_other_rounded, size: 14, color: kTextColor),
                        const SizedBox(width: 5),
                        Text(t.productTitle, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextColor)),
                      ],
                    ),
                  ),
                if (t.orderId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 14, color: Color(0xFF92400E)),
                        const SizedBox(width: 5),
                        Text('Commande #${t.orderId}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          _buildStatusProgress(t.status),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
            child: Text(t.message, style: const TextStyle(color: Colors.black87, fontSize: 13.5, height: 1.35)),
          ),
          if (t.clientFollowup != null && t.clientFollowup!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vos précisions envoyées :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E40AF))),
                  const SizedBox(height: 3),
                  Text(t.clientFollowup!, style: const TextStyle(fontSize: 12.5, color: kTextColor)),
                ],
              ),
            ),
          ],
          if (t.adminReply != null && t.adminReply!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent_rounded, size: 15, color: Colors.green),
                      SizedBox(width: 5),
                      Text('Réponse Support Electro Store :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.adminReply!, style: const TextStyle(color: kTextColor, fontSize: 13.5, height: 1.35)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openFollowupDialog(t),
                icon: const Icon(Icons.add_comment_outlined, size: 16),
                label: Text(t.status == 'resolved' ? 'Réouvrir / Préciser' : 'Ajouter précision', style: const TextStyle(fontSize: 12.5)),
              ),
              if (t.status != 'resolved') ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _markTicketResolved(t),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Marquer résolu', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Expanded(child: _GuaranteeBadge(icon: Icons.verified_outlined, title: 'Garantie 24 Mois', subtitle: 'Pièces & main-d\'œuvre')),
                SizedBox(width: 10),
                Expanded(child: _GuaranteeBadge(icon: Icons.autorenew_rounded, title: 'Échange 7 Jours', subtitle: 'Si défaut au déballage')),
                SizedBox(width: 10),
                Expanded(child: _GuaranteeBadge(icon: Icons.headset_mic_outlined, title: 'SAV Réactif', subtitle: 'Réponse sous 24h')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Questions Fréquentes & Procédures SAV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextColor)),
          const SizedBox(height: 10),
          ..._faqItems.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  leading: const Icon(Icons.help_outline_rounded, color: kPrimaryColor),
                  title: Text(item['q']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: kTextColor)),
                  children: [
                    Text(item['a']!, style: const TextStyle(color: kTextLightColor, fontSize: 13, height: 1.45)),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
                foregroundColor: kTextColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.build_circle_outlined),
              label: const Text('Ouvrir un ticket SAV maintenant', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuaranteeBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuaranteeBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimaryColor, size: 26),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: kTextColor), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: kTextLightColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
