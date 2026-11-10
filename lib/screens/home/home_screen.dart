import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/models/product.dart';
import 'package:ecom_app/providers/auth_provider.dart';
import 'package:ecom_app/providers/cart_provider.dart';
import 'package:ecom_app/providers/favorite_provider.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/screens/details/details_screen.dart';
import 'package:ecom_app/screens/auth/login_screen.dart';
import 'package:ecom_app/screens/cart/cart_screen.dart';
import 'package:ecom_app/screens/support/support_screen.dart';
import 'package:ecom_app/widgets/product_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _bannerCtrl = PageController(viewportFraction: 0.92);

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _flashSales = [];
  final List<ProductModel> _recentlyViewed = [];
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];

  int _selectedCategoryId = 1;
  String _searchQuery = '';
  String _sortBy = 'popular'; // 'popular', 'flash', 'rating', 'price_asc', 'price_desc', 'newest'
  bool _isGridView = true;

  // Advanced Filter States
  double _maxCatalogPrice = 2000.0;
  RangeValues _priceRange = const RangeValues(0.0, 2000.0);
  double _minRating = 0.0;
  bool _onlyFlashSale = false;
  bool _onlyInStock = false;

  int _currentBannerPage = 0;
  bool _isLoading = true;
  final Map<int, int> _selectedCardColorIndex = {};

  // Flash Sale Timer
  Duration _flashDuration = const Duration(hours: 11, minutes: 45, seconds: 20);
  Timer? _timer;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerTimer?.cancel();
    _searchCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_flashDuration.inSeconds > 0 && mounted) {
        setState(() {
          _flashDuration = _flashDuration - const Duration(seconds: 1);
        });
      }
    });

    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_banners.length > 1 && _bannerCtrl.hasClients && mounted) {
        final next = (_currentBannerPage + 1) % _banners.length;
        _bannerCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getProducts();
    if (!mounted) return;

    if (res['success'] == true && (res['products'] as List).isNotEmpty) {
      final prods = res['products'] as List<ProductModel>;
      final flash = prods.where((p) => p.isFlashSale).toList();
      final maxP = prods.fold<double>(500.0, (prev, p) => p.price > prev ? p.price : prev);
      final roundedMax = ((maxP / 100).ceil() * 100).toDouble();

      setState(() {
        _allProducts = prods;
        _categories = res['categories'] as List<dynamic>;
        _banners = res['banners'] as List<dynamic>;
        _flashSales = flash.isNotEmpty ? flash : prods.take(2).toList();
        _maxCatalogPrice = roundedMax < 500 ? 500 : roundedMax;
        _priceRange = RangeValues(0, _maxCatalogPrice);
        _isLoading = false;
      });
      _applyFilter();
    } else {
      final fallbackProds = [
        ProductModel(
          id: 1,
          categoryId: 2,
          title: 'سماعات لاسلكية AirPod Pro',
          subtitle: 'جودة صوت فائقة ومقاومة للماء',
          price: 59.0,
          originalPrice: 99.0,
          isFlashSale: true,
          flashDiscountPercent: 40,
          itemsSold: 24,
          avgRating: 4.8,
          reviewCount: 3,
          stock: 30,
          description: 'سماعات أذن لاسلكية متطورة توفر إلغاء نشط للضوضاء، مع ميكروفون مدمج وبطارية تدوم حتى 24 ساعة.',
          image: 'assets/images/airpod.png',
        ),
        ProductModel(
          id: 2,
          categoryId: 3,
          title: 'جهاز موبايل الذكي Ultra',
          subtitle: 'شاشة AMOLED 120Hz وقوة معالجة عالية',
          price: 1099.0,
          originalPrice: 1499.0,
          isFlashSale: true,
          flashDiscountPercent: 27,
          itemsSold: 18,
          avgRating: 4.9,
          reviewCount: 2,
          stock: 12,
          description: 'هاتف ذكي بتصميم عصري وكاميرا احترافية بدقة 108 ميجابكسل.',
          image: 'assets/images/mobile.png',
        ),
        ProductModel(
          id: 6,
          categoryId: 4,
          title: 'كاميرا كمبيوتر WebCam HD',
          subtitle: 'بجودة ودقة صورة عالية 1080P',
          price: 27.30,
          originalPrice: 39.0,
          isFlashSale: true,
          flashDiscountPercent: 30,
          itemsSold: 12,
          avgRating: 4.6,
          reviewCount: 1,
          stock: 35,
          description: 'كاميرا ويب عالية الدقة للمؤتمرات والبث المباشر.',
          image: 'assets/images/camera.png',
        ),
        ProductModel(
          id: 4,
          categoryId: 2,
          title: 'سماعات رأس لاسلكية Headset',
          subtitle: 'راحة تامة لساعات استماع متواصلة',
          price: 56.0,
          itemsSold: 15,
          avgRating: 4.7,
          reviewCount: 4,
          stock: 25,
          description: 'سماعات رأس احترافية مع صوت ستيريو عميق Bass.',
          image: 'assets/images/headset.png',
        ),
        ProductModel(
          id: 5,
          categoryId: 2,
          title: 'مكبر صوت بلوتوث Speaker',
          subtitle: 'سجل اللحظات واستمتع بالموسيقى',
          price: 68.0,
          itemsSold: 10,
          avgRating: 4.5,
          reviewCount: 2,
          stock: 40,
          description: 'مكبر صوت بلوتوث محمول مقاوم للصدمات.',
          image: 'assets/images/speaker.png',
        ),
        ProductModel(
          id: 3,
          categoryId: 4,
          title: 'نظارات ثلاثية الأبعاد VR 3D',
          subtitle: 'لنقلك إلى العالم الافتراضي الغامر',
          price: 39.0,
          itemsSold: 8,
          avgRating: 4.3,
          reviewCount: 1,
          stock: 45,
          description: 'نظارة واقع افتراضي متوافقة مع جميع الهواتف.',
          image: 'assets/images/class.png',
        ),
      ];

      setState(() {
        _allProducts = fallbackProds;
        _flashSales = fallbackProds.where((p) => p.isFlashSale).toList();
        _maxCatalogPrice = 1600.0;
        _priceRange = RangeValues(0, _maxCatalogPrice);
        _categories = [
          {'id': 1, 'name': 'Tous', 'icon': 'grid_view'},
          {'id': 2, 'name': 'Audio & Son', 'icon': 'headphones'},
          {'id': 3, 'name': 'Smartphones', 'icon': 'smartphone'},
          {'id': 4, 'name': 'Photo & Vidéo', 'icon': 'camera_alt'},
        ];
        _banners = [
          {
            'title': 'VENTES FLASH JUMIA STYLE',
            'subtitle': 'Jusqu\'à -40% sur les accessoires tech ! Stocks limités',
            'badge': '⚡ VENTE FLASH',
            'bg_color_start': '#D90429',
            'bg_color_end': '#EF233C',
          },
          {
            'title': 'CODE PROMO : BIENVENUE10',
            'subtitle': '10% de réduction immédiate dès 50 DH (touchez pour copier)',
            'badge': '🎁 CADEAU',
            'bg_color_start': '#023047',
            'bg_color_end': '#219EBC',
          },
        ];
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  int get _activeAdvancedFiltersCount {
    int count = 0;
    if (_priceRange.start > 0 || _priceRange.end < _maxCatalogPrice) count++;
    if (_minRating > 0) count++;
    if (_onlyFlashSale) count++;
    if (_onlyInStock) count++;
    return count;
  }

  void _resetAllFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedCategoryId = 1;
      _searchQuery = '';
      _sortBy = 'popular';
      _priceRange = RangeValues(0, _maxCatalogPrice);
      _minRating = 0.0;
      _onlyFlashSale = false;
      _onlyInStock = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      var list = _allProducts.where((p) {
        final matchesCat = _selectedCategoryId == 1 || p.categoryId == _selectedCategoryId;
        final matchesSearch = _searchQuery.isEmpty ||
            p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.categoryName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesPrice = p.price >= _priceRange.start && p.price <= _priceRange.end;
        final matchesRating = p.avgRating >= _minRating;
        final matchesFlash = !_onlyFlashSale || p.isFlashSale;
        final matchesStock = !_onlyInStock || p.stock > 0;

        return matchesCat && matchesSearch && matchesPrice && matchesRating && matchesFlash && matchesStock;
      }).toList();

      switch (_sortBy) {
        case 'flash':
          list = list.where((p) => p.isFlashSale).toList();
          break;
        case 'price_asc':
          list.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          list.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          break;
        case 'newest':
          list.sort((a, b) => b.id.compareTo(a.id));
          break;
        case 'popular':
        default:
          list.sort((a, b) => b.itemsSold.compareTo(a.itemsSold));
          break;
      }

      _filteredProducts = list;
    });
  }

  void _openProductDetails(ProductModel product) {
    setState(() {
      _recentlyViewed.removeWhere((p) => p.id == product.id);
      _recentlyViewed.insert(0, product);
      if (_recentlyViewed.length > 6) {
        _recentlyViewed.removeLast();
      }
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }

  void _openFiltersSheet() {
    RangeValues tempRange = _priceRange;
    double tempRating = _minRating;
    bool tempFlash = _onlyFlashSale;
    bool tempStock = _onlyInStock;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filtres Avancés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempRange = RangeValues(0, _maxCatalogPrice);
                          tempRating = 0.0;
                          tempFlash = false;
                          tempStock = false;
                        });
                      },
                      child: const Text('Réinitialiser', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Price Range Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Budget (DH)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '${tempRange.start.round()} DH  —  ${tempRange.end.round()} DH',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  ],
                ),
                RangeSlider(
                  values: tempRange,
                  min: 0,
                  max: _maxCatalogPrice,
                  divisions: 20,
                  activeColor: kPrimaryColor,
                  labels: RangeLabels('${tempRange.start.round()} DH', '${tempRange.end.round()} DH'),
                  onChanged: (values) => setModalState(() => tempRange = values),
                ),
                const SizedBox(height: 12),

                // Minimum Rating
                const Text('Note client minimale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _filterRatingChip('Toutes', 0.0, tempRating, (v) => setModalState(() => tempRating = v)),
                    _filterRatingChip('⭐ 4.0 et +', 4.0, tempRating, (v) => setModalState(() => tempRating = v)),
                    _filterRatingChip('⭐ 4.5 et +', 4.5, tempRating, (v) => setModalState(() => tempRating = v)),
                  ],
                ),
                const SizedBox(height: 14),

                // Flash Sale & Stock Switches
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('⚡ Uniquement Ventes Flash', style: TextStyle(fontWeight: FontWeight.w600)),
                  activeColor: const Color(0xFFD90429),
                  value: tempFlash,
                  onChanged: (val) => setModalState(() => tempFlash = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('✅ Uniquement en stock', style: TextStyle(fontWeight: FontWeight.w600)),
                  activeColor: Colors.green,
                  value: tempStock,
                  onChanged: (val) => setModalState(() => tempStock = val),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF023047),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setState(() {
                        _priceRange = tempRange;
                        _minRating = tempRating;
                        _onlyFlashSale = tempFlash;
                        _onlyInStock = tempStock;
                      });
                      _applyFilter();
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Appliquer les filtres',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterRatingChip(String label, double val, double current, ValueChanged<double> onSelect) {
    final selected = current == val;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.amber.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.amber.shade900 : kTextColor,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelect(val),
    );
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _categoryIcon(String? iconName) {
    switch (iconName) {
      case 'headphones':
        return Icons.headphones_rounded;
      case 'smartphone':
        return Icons.smartphone_rounded;
      case 'camera_alt':
        return Icons.photo_camera_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget _buildSortChip({required String label, required String value}) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF023047) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF023047) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF023047).withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final fav = Provider.of<FavoriteProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: CustomScrollView(
                slivers: [
                  // 1. MODERN GRADIENT HEADER + SEARCH BAR + FILTER BUTTON
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        kDefaultPadding,
                        MediaQuery.of(context).padding.top + 12,
                        kDefaultPadding,
                        18,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF023047), Color(0xFF219EBC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
                      ),
                      child: Column(
                        children: [
                          // Top Bar Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: kSecondaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF023047), size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ELECTRO STORE',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.8),
                                      ),
                                      Text(
                                        auth.isAuthenticated
                                            ? 'Bienvenue, ${auth.currentUser!.name.split(' ').first} 👋'
                                            : 'High-Tech & Promotions ⚡',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (!auth.isAuthenticated)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.15),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      icon: const Icon(Icons.login, size: 16),
                                      label: const Text('Connexion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                      },
                                    ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15)),
                                    icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
                                    tooltip: 'Support & SAV',
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15)),
                                        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                                        },
                                      ),
                                      if (cart.itemCount > 0)
                                        Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Color(0xFFD90429), shape: BoxShape.circle),
                                            child: Text(
                                              '${cart.itemCount}',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Search + Advanced Filter Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (val) {
                                      _searchQuery = val.trim();
                                      _applyFilter();
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Rechercher AirPod, smartphone, caméra...',
                                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                      prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 18),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                _searchQuery = '';
                                                _applyFilter();
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SizedBox(
                                    height: 46,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kSecondaryColor,
                                        foregroundColor: const Color(0xFF023047),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(Icons.tune_rounded, size: 20),
                                      label: const Text('Filtres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      onPressed: _openFiltersSheet,
                                    ),
                                  ),
                                  if (_activeAdvancedFiltersCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: const Color(0xFFD90429),
                                        child: Text(
                                          '$_activeAdvancedFiltersCount',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. TRUST BADGES STRIP
                  SliverToBoxAdapter(
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.only(top: 10),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                        children: [
                          _trustBadge(Icons.local_shipping_outlined, 'Livraison 24/48h', Colors.blue),
                          _trustBadge(Icons.payments_outlined, 'Paiement à la livraison', Colors.green),
                          _trustBadge(Icons.verified_user_outlined, 'Paiement CMI sécurisé', Colors.indigo),
                          _trustBadge(Icons.replay_rounded, 'Retours gratuits 7j', Colors.orange),
                        ],
                      ),
                    ),
                  ),

                  // 3. PROMOTIONAL BANNERS CAROUSEL WITH DOTS
                  if (_banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 130,
                            child: PageView.builder(
                              controller: _bannerCtrl,
                              itemCount: _banners.length,
                              onPageChanged: (idx) => setState(() => _currentBannerPage = idx),
                              itemBuilder: (context, index) {
                                final b = _banners[index];
                                final colStart = _parseColor(b['bg_color_start'], const Color(0xFF023047));
                                final colEnd = _parseColor(b['bg_color_end'], kPrimaryColor);
                                final title = (b['title'] ?? '').toString();

                                return GestureDetector(
                                  onTap: () {
                                    if (title.toUpperCase().contains('BIENVENUE10')) {
                                      Clipboard.setData(const ClipboardData(text: 'BIENVENUE10'));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(backgroundColor: Colors.green, content: Text('Code promo BIENVENUE10 copié !')),
                                      );
                                    } else if (title.toUpperCase().contains('FLASH')) {
                                      setState(() => _sortBy = 'flash');
                                      _applyFilter();
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [colStart, colEnd],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: colStart.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: kSecondaryColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  b['badge'] ?? 'PROMO',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextColor),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                b['subtitle'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.local_offer_rounded, color: kSecondaryColor, size: 28),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _banners.length,
                              (idx) => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                height: 6,
                                width: _currentBannerPage == idx ? 20 : 6,
                                decoration: BoxDecoration(
                                  color: _currentBannerPage == idx ? kPrimaryColor : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. JUMIA-STYLE VENTES FLASH SECTION
                  if (_flashSales.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(kDefaultPadding, 14, kDefaultPadding, 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD90429), Color(0xFFFF5400)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFD90429).withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.bolt_rounded, color: Colors.yellow, size: 26),
                                    SizedBox(width: 6),
                                    Text(
                                      'VENTES FLASH',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                                _buildDigitalCountdown(),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 235,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _flashSales.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final p = _flashSales[index];
                                  final isFav = fav.isFavorite(p.id);
                                  final progress = (p.itemsSold / (p.itemsSold + p.stock)).clamp(0.15, 0.96);

                                  return Container(
                                    width: 168,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => _openProductDetails(p),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Center(
                                                  child: SizedBox(
                                                    height: 82,
                                                    child: ProductImageWidget(imagePath: p.image, fit: BoxFit.contain),
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      p.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${p.avgRating.toStringAsFixed(1)} (${p.reviewCount})',
                                                          style: const TextStyle(fontSize: 10.5, color: kTextLightColor),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '${p.price} DH',
                                                          style: const TextStyle(color: Color(0xFFD90429), fontWeight: FontWeight.w900, fontSize: 15),
                                                        ),
                                                        if (p.originalPrice != null) ...[
                                                          const SizedBox(width: 5),
                                                          Text(
                                                            '${p.originalPrice}',
                                                            style: const TextStyle(color: Colors.grey, fontSize: 10.5, decoration: TextDecoration.lineThrough),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: LinearProgressIndicator(
                                                        value: progress,
                                                        minHeight: 5,
                                                        backgroundColor: Colors.grey.shade200,
                                                        color: const Color(0xFFFF5400),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          '${p.itemsSold} vendus',
                                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                                        ),
                                                        InkWell(
                                                          onTap: p.stock > 0
                                                              ? () {
                                                                  cart.addToCart(p);
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      duration: const Duration(seconds: 1),
                                                                      backgroundColor: Colors.green,
                                                                      content: Text('"${p.title}" ajouté au panier !'),
                                                                    ),
                                                                  );
                                                                }
                                                              : null,
                                                          child: Container(
                                                            padding: const EdgeInsets.all(4),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFD90429),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 14),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (p.flashDiscountPercent > 0)
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFD90429),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '-${p.flashDiscountPercent}%',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              icon: Icon(
                                                isFav ? Icons.favorite : Icons.favorite_border,
                                                color: isFav ? Colors.redAccent : Colors.grey.shade400,
                                                size: 18,
                                              ),
                                              onPressed: () => fav.toggleFavorite(p, auth.currentUser?.id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 5. CATEGORIES + SORT BAR + ACTIVE FILTER CHIPS
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categories
                        Padding(
                          padding: const EdgeInsets.fromLTRB(kDefaultPadding, 14, kDefaultPadding, 6),
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final catId = int.tryParse(cat['id'].toString()) ?? 1;
                                final isSelected = _selectedCategoryId == catId;

                                return ChoiceChip(
                                  avatar: Icon(
                                    _categoryIcon(cat['icon']?.toString()),
                                    size: 16,
                                    color: isSelected ? Colors.white : kPrimaryColor,
                                  ),
                                  label: Text(
                                    cat['name'] ?? '',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : kTextColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: kPrimaryColor,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey.shade200),
                                  ),
                                  onSelected: (_) {
                                    setState(() => _selectedCategoryId = catId);
                                    _applyFilter();
                                  },
                                );
                              },
                            ),
                          ),
                        ),

                        // Sort Chips
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 6),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildSortChip(label: '🔥 Populaires', value: 'popular'),
                                const SizedBox(width: 8),
                                _buildSortChip(label: '⚡ Ventes Flash', value: 'flash'),
                                const SizedBox(width: 8),
                                _buildSortChip(label: '⭐ Mieux notés', value: 'rating'),
                                const SizedBox(width: 8),
                                _buildSortChip(label: '💰 Prix croissant', value: 'price_asc'),
                                const SizedBox(width: 8),
                                _buildSortChip(label: '💎 Prix décroissant', value: 'price_desc'),
                                const SizedBox(width: 8),
                                _buildSortChip(label: '🆕 Nouveautés', value: 'newest'),
                              ],
                            ),
                          ),
                        ),

                        // Active Advanced Filter Pills
                        if (_activeAdvancedFiltersCount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 4),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_priceRange.start > 0 || _priceRange.end < _maxCatalogPrice)
                                  InputChip(
                                    label: Text('Prix: ${_priceRange.start.round()}-${_priceRange.end.round()} DH', style: const TextStyle(fontSize: 11)),
                                    onDeleted: () {
                                      setState(() => _priceRange = RangeValues(0, _maxCatalogPrice));
                                      _applyFilter();
                                    },
                                  ),
                                if (_minRating > 0)
                                  InputChip(
                                    label: Text('Note ≥ $_minRating ★', style: const TextStyle(fontSize: 11)),
                                    onDeleted: () {
                                      setState(() => _minRating = 0.0);
                                      _applyFilter();
                                    },
                                  ),
                                if (_onlyFlashSale)
                                  InputChip(
                                    label: const Text('Flash uniquement ⚡', style: TextStyle(fontSize: 11)),
                                    onDeleted: () {
                                      setState(() => _onlyFlashSale = false);
                                      _applyFilter();
                                    },
                                  ),
                                if (_onlyInStock)
                                  InputChip(
                                    label: const Text('En stock ✅', style: TextStyle(fontSize: 11)),
                                    onDeleted: () {
                                      setState(() => _onlyInStock = false);
                                      _applyFilter();
                                    },
                                  ),
                              ],
                            ),
                          ),

                        // Catalog Header + Grid/List Toggle
                        Padding(
                          padding: const EdgeInsets.fromLTRB(kDefaultPadding, 10, kDefaultPadding, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Catalogue (${_filteredProducts.length})',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(Icons.grid_view_rounded, size: 19, color: _isGridView ? kPrimaryColor : Colors.grey),
                                          onPressed: () => setState(() => _isGridView = true),
                                          tooltip: 'Vue Grille',
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(Icons.view_agenda_rounded, size: 19, color: !_isGridView ? kPrimaryColor : Colors.grey),
                                          onPressed: () => setState(() => _isGridView = false),
                                          tooltip: 'Vue Liste',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. PRODUCTS CATALOG (EMPTY STATE OR RESPONSIVE GRID / LIST)
                  if (_filteredProducts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(36),
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Aucun produit ne correspond à vos critères', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('Réinitialiser les filtres', style: TextStyle(color: Colors.white)),
                              onPressed: _resetAllFilters,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_isGridView)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.crossAxisExtent;
                          final cols = w >= 1100 ? 4 : (w >= 720 ? 3 : 2);
                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: w >= 720 ? 0.74 : 0.67,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildGridProductCard(_filteredProducts[index], fav, cart, auth),
                              childCount: _filteredProducts.length,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildListProductCard(_filteredProducts[index], fav, cart, auth),
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    ),

                  // 7. RECENTLY VIEWED PRODUCTS
                  if (_recentlyViewed.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(kDefaultPadding, 22, kDefaultPadding, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('👀 Consultés récemment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kTextColor)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 140,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentlyViewed.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (ctx, i) {
                                  final p = _recentlyViewed[i];
                                  return GestureDetector(
                                    onTap: () => _openProductDetails(p),
                                    child: Container(
                                      width: 120,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(height: 62, child: ProductImageWidget(imagePath: p.image, fit: BoxFit.contain)),
                                          Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          Text('${p.price} DH', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimaryColor)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
    );
  }

  Widget _trustBadge(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextColor)),
        ],
      ),
    );
  }

  Widget _buildDigitalCountdown() {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_flashDuration.inHours);
    final m = two(_flashDuration.inMinutes.remainder(60));
    final s = two(_flashDuration.inSeconds.remainder(60));

    Widget box(String txt) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(6)),
          child: Text(txt, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w900, fontSize: 13)),
        );

    return Row(
      children: [
        box(h),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        box(m),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        box(s),
      ],
    );
  }

  int _selectedColorIndexFor(ProductModel product) {
    if (product.colors.isEmpty) return 0;
    final raw = _selectedCardColorIndex[product.id] ?? 0;
    return raw.clamp(0, product.colors.length - 1);
  }

  String _displayImageFor(ProductModel product) {
    if (product.colors.isEmpty) return product.image;
    final chosen = product.colors[_selectedColorIndexFor(product)];
    if (chosen.image != null && chosen.image!.isNotEmpty) {
      return chosen.image!;
    }
    return product.image;
  }

  Widget _buildCardColorDots(ProductModel product, {double dotSize = 13}) {
    if (product.colors.isEmpty) return const SizedBox.shrink();
    final activeIdx = _selectedColorIndexFor(product);
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: product.colors.take(6).toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final col = entry.value;
        final isSelected = idx == activeIdx;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _selectedCardColorIndex[product.id] = idx;
            });
          },
          child: Tooltip(
            message: col.name,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: dotSize + (isSelected ? 4 : 0),
              height: dotSize + (isSelected ? 4 : 0),
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade400,
                  width: isSelected ? 1.8 : 0.8,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: col.toFlutterColor(),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleQuickAddToCart(ProductModel product, CartProvider cart) {
    ProductColor? chosenColor;
    if (product.colors.isNotEmpty) {
      chosenColor = product.colors[_selectedColorIndexFor(product)];
    }
    cart.addToCart(
      product,
      selectedColor: chosenColor?.name,
      selectedImage: chosenColor?.image,
    );
    final colorLabel = chosenColor != null ? ' (${chosenColor.name})' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
        content: Text('"${product.title}"$colorLabel ajouté au panier !'),
      ),
    );
  }

  Widget _buildGridProductCard(ProductModel product, FavoriteProvider fav, CartProvider cart, AuthProvider auth) {
    final isFav = fav.isFavorite(product.id);
    final outOfStock = product.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openProductDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Box + Badges
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Hero(
                      tag: 'prod_${product.id}',
                      child: ProductImageWidget(imagePath: _displayImageFor(product), fit: BoxFit.contain),
                    ),
                  ),
                  if (product.isFlashSale)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFD90429), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '⚡ -${product.flashDiscountPercent}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.grey, size: 17),
                        onPressed: () => fav.toggleFavorite(product, auth.currentUser?.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Box
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                const SizedBox(width: 2),
                                Text(
                                  '${product.avgRating.toStringAsFixed(1)} (${product.reviewCount})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextLightColor),
                                ),
                              ],
                            ),
                            if (outOfStock)
                              const Text('Rupture', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))
                            else if (product.stock <= 15)
                              Text('${product.stock} rest.', style: const TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kTextColor, height: 1.2),
                        ),
                        if (product.colors.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _buildCardColorDots(product, dotSize: 13),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.price} DH',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: product.isFlashSale ? const Color(0xFFD90429) : const Color(0xFF023047),
                              ),
                            ),
                            if (product.originalPrice != null)
                              Text(
                                '${product.originalPrice} DH',
                                style: const TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.lineThrough),
                              ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: outOfStock ? Colors.grey.shade300 : kSecondaryColor,
                            foregroundColor: kTextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 32),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: outOfStock ? null : () => _handleQuickAddToCart(product, cart),
                          child: const Icon(Icons.add_shopping_cart, size: 17),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListProductCard(ProductModel product, FavoriteProvider fav, CartProvider cart, AuthProvider auth) {
    final isFav = fav.isFavorite(product.id);
    final outOfStock = product.stock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _openProductDetails(product),
        child: Row(
          children: [
            Container(
              width: 110,
              height: 110,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
              child: ProductImageWidget(imagePath: _displayImageFor(product), fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (product.isFlashSale)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFD90429), borderRadius: BorderRadius.circular(6)),
                          child: Text('⚡ -${product.flashDiscountPercent}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                            Text(' ${product.avgRating.toStringAsFixed(1)} (${product.reviewCount})', style: const TextStyle(fontSize: 11, color: kTextLightColor)),
                          ],
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.grey, size: 20),
                        onPressed: () => fav.toggleFavorite(product, auth.currentUser?.id),
                      ),
                    ],
                  ),
                  Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor)),
                  Text(product.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextLightColor, fontSize: 12)),
                  if (product.colors.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildCardColorDots(product, dotSize: 13),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${product.price} DH',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: product.isFlashSale ? const Color(0xFFD90429) : const Color(0xFF023047)),
                          ),
                          if (product.originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Text('${product.originalPrice} DH', style: const TextStyle(color: Colors.grey, fontSize: 11.5, decoration: TextDecoration.lineThrough)),
                          ],
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: outOfStock ? Colors.grey.shade300 : kSecondaryColor,
                          foregroundColor: kTextColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: outOfStock ? null : () => _handleQuickAddToCart(product, cart),
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: Text(outOfStock ? 'Épuisé' : 'Ajouter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
