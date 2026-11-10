import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/models/product.dart';
import 'package:ecom_app/models/review.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/providers/auth_provider.dart';
import 'package:ecom_app/providers/cart_provider.dart';
import 'package:ecom_app/providers/favorite_provider.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/widgets/product_image.dart';
import 'package:ecom_app/screens/support/support_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _imgPageCtrl = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  int _selectedColorIndex = 0;
  List<ReviewModel> _reviews = [];
  double _averageRating = 5.0;
  int _totalReviews = 0;
  bool _loadingReviews = true;

  List<ProductColor> get _activeColors {
    if (widget.product.colors.isNotEmpty) return widget.product.colors;
    return [
      ProductColor(name: 'Gris Titane', hex: '#80989A'),
      ProductColor(name: 'Rouge Édition', hex: '#FF5252'),
      ProductColor(name: 'Bleu Electro', hex: '#219EBC'),
    ];
  }

  @override
  void dispose() {
    _imgPageCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  void _fetchReviews() async {
    final res = await ApiService.getReviews(widget.product.id);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _reviews = res['reviews'] as List<ReviewModel>;
        _averageRating = res['average_rating'] as double;
        _totalReviews = res['total_reviews'] as int;
        _loadingReviews = false;
      });
    } else {
      setState(() => _loadingReviews = false);
    }
  }

  void _showAddReviewDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    int selectedRating = 5;
    final nameCtrl = TextEditingController(text: auth.currentUser?.name ?? 'Client VIP');
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Donner votre avis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Votre note :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        iconSize: 32,
                        icon: Icon(
                          star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() => selectedRating = star);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Votre Nom',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Votre commentaire / retour d\'expérience',
                      hintText: 'Qualité du produit, livraison, satisfaction...',
                      prefixIcon: const Icon(Icons.rate_review_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (commentCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Veuillez écrire un commentaire.')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final res = await ApiService.addReview(
                              productId: widget.product.id,
                              userId: auth.currentUser?.id ?? 1,
                              userName: nameCtrl.text.trim(),
                              rating: selectedRating,
                              comment: commentCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (res['success'] == true) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Text('Merci ! Votre avis a été publié avec succès.'),
                                  ),
                                );
                                _fetchReviews();
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Publier mon avis',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final fav = Provider.of<FavoriteProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final isFav = fav.isFavorite(widget.product.id);

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Détails du Produit',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kTextColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.redAccent : kPrimaryColor,
            ),
            onPressed: () {
              fav.toggleFavorite(widget.product, auth.currentUser?.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 1),
                  content: Text(
                    isFav ? 'Retiré des favoris' : 'Ajouté aux favoris !',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5),
              decoration: const BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Multi-Image Gallery Carousel
                  Container(
                    margin: const EdgeInsets.only(top: kDefaultPadding, bottom: 10),
                    height: size.width > 600 ? 300 : size.width * 0.62,
                    child: PageView.builder(
                      controller: _imgPageCtrl,
                      itemCount: widget.product.images.length,
                      onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                      itemBuilder: (ctx, idx) {
                        final img = widget.product.images[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: idx == 0
                              ? Hero(
                                  tag: 'prod_${widget.product.id}',
                                  child: ProductImageWidget(imagePath: img, fit: BoxFit.contain),
                                )
                              : ProductImageWidget(imagePath: img, fit: BoxFit.contain),
                        );
                      },
                    ),
                  ),
                  if (widget.product.images.length > 1) ...[
                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: widget.product.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final active = idx == _currentImageIndex;
                          return GestureDetector(
                            onTap: () {
                              _imgPageCtrl.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 54,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active ? kPrimaryColor : Colors.grey.shade300,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: ProductImageWidget(imagePath: widget.product.images[idx], fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Dynamic Color Variants Selector (auto-jumps to color-linked image!)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _activeColors.length,
                      (index) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedColorIndex = index);
                          final linkedImg = _activeColors[index].image;
                          if (linkedImg != null && linkedImg.isNotEmpty) {
                            final imgIdx = widget.product.images.indexOf(linkedImg);
                            if (imgIdx != -1 && _imgPageCtrl.hasClients) {
                              _imgPageCtrl.animateToPage(
                                imgIdx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColorIndex == index ? kTextColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: _activeColors[index].toFlutterColor(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Couleur : ${_activeColors[_selectedColorIndex].name}',
                    style: const TextStyle(color: kTextLightColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.product.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.product.subtitle,
                      style: const TextStyle(color: kTextLightColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Rating summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($_totalReviews avis)',
                        style: const TextStyle(color: kTextLightColor, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.product.isFlashSale)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD90429),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚡ VENTE FLASH -${widget.product.flashDiscountPercent}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.product.price} DH',
                        style: TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w800,
                          color: widget.product.isFlashSale ? const Color(0xFFD90429) : kSecondaryColor,
                        ),
                      ),
                      if (widget.product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${widget.product.originalPrice} DH',
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(kDefaultPadding * 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15.0,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding * 1.5),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSecondaryColor,
                        foregroundColor: kTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        final chosenColorObj = _activeColors[_selectedColorIndex];
                        cart.addToCart(
                          widget.product,
                          quantity: _quantity,
                          selectedColor: chosenColorObj.name,
                          selectedImage: chosenColorObj.image,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              '$_quantity x "${widget.product.title}" (${chosenColorObj.name}) ajouté(s) au panier !',
                            ),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'VOIR PANIER',
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(
                        'Ajouter au panier (${(widget.product.price * _quantity).toStringAsFixed(2)} DH)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      icon: const Icon(Icons.support_agent_rounded, size: 18, color: kSecondaryColor),
                      label: const Text(
                        'Question ou panne sur cet article ? Contactez Electro Store',
                        style: TextStyle(fontSize: 12.5, decoration: TextDecoration.underline),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportScreen(
                              initialSubject: 'Question : ${widget.product.title}',
                              initialCategory: 'Question produit',
                              initialProductId: widget.product.id,
                              initialProductTitle: widget.product.title,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding * 2),

                  // Reviews & Ratings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Avis Clients',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_totalReviews',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: kSecondaryColor,
                        ),
                        icon: const Icon(Icons.add_comment, size: 16),
                        label: const Text('Donner mon avis', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _showAddReviewDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingReviews)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ))
                  else if (_reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun avis pour le moment. Soyez le premier à donner votre avis !',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _reviews.map((rev) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: kPrimaryColor.withOpacity(0.15),
                                        child: Text(
                                          rev.userName.isNotEmpty ? rev.userName[0].toUpperCase() : 'C',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        rev.userName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (starIdx) => Icon(
                                        starIdx < rev.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (rev.comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  rev.comment,
                                  style: const TextStyle(color: kTextColor, fontSize: 13, height: 1.4),
                                ),
                              ],
                              if (rev.createdAt.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    rev.createdAt,
                                    style: const TextStyle(color: kTextLightColor, fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: kDefaultPadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
