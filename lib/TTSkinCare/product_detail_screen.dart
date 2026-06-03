
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_logic.dart';
import '../model/product_model.dart';
import 'url_util.dart';

class ProductDetailScreen extends StatefulWidget {
  final SkincareProduct item;
  const ProductDetailScreen(this.item, {super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _urlUtil = UrlUtil();

  int _currentImage = 0;

  SkincareProduct get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartLogic>();
    final inCart = cart.contains(item.id);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.category.name),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cart.totalCount > 0,
              label: Text('${cart.totalCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // Slideshow
          _buildSlideshow(),
          // Image dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(item.images.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                width: _currentImage == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color:
                      _currentImage == i ? scheme.primary : Colors.grey.shade300,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Text(
                  item.brand,
                  style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                // Title
                Text(item.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Rating & Skin type
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.star_rounded, '${item.rating}',
                        Colors.amber.shade700),
                    _chip(Icons.face_retouching_natural, item.skinType,
                        scheme.tertiary),
                    _chip(Icons.inventory_2_outlined,
                        '${item.stock} in stock', Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                // Price row
                Row(
                  children: [
                   
                      
                    Text(
                      '\$${item.discountPrice}',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary),
                    ),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        '\$${item.price}',
                        style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Save ${item.discountPercent}%',
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
               
                    Row(
  children: [
    Expanded(
      child: Card(
        color: Theme.of(context).colorScheme.inversePrimary,
        child: ListTile(
          leading: const Icon(Icons.call),
          title: const Text("Call"),
          onTap: () {
            String number = "+1234567890";
            _urlUtil.open("tel:$number");
          },
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: Card(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          leading: const Icon(Icons.directions),
          title: const Text("Map"),
          onTap: () {
            const String map =
                "https://www.google.com/maps/place/National+University+of+Management/@11.5747699,104.8424093,13z/data=!4m10!1m2!2m1!1snum!3m6!1s0x310951431e152d17:0x9b79af8befbd4a18!8m2!3d11.5747699!4d104.918627!15sCgNudW2SAQp1bml2ZXJzaXR54AEA!16s%2Fm%2F0279my9?entry=ttu&g_ep=EgoyMDI2MDUyNy4wIKXMDSoASAFQAw%3D%3D";
            _urlUtil.open(map);
          },
        ),
      ),
    ),
  ],
),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('About this product',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.description,
                    style: const TextStyle(height: 1.6, fontSize: 14)),
                const SizedBox(height: 24),
                // Add to cart
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.read<CartLogic>().addItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.title} added to cart'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    
                    icon: Icon(inCart
                        ? Icons.shopping_bag
                        : Icons.shopping_bag_outlined),
                    label: Text(inCart ? 'Add More to Cart' : 'Add to Cart'),
                
                  ),
                
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideshow() {
    return CarouselSlider.builder(
      options: CarouselOptions(
        aspectRatio: 1 / 1,
        enlargeCenterPage: true,
        onPageChanged: (i, _) => setState(() => _currentImage = i),
      ),
      itemCount: item.images.length,
      itemBuilder: (_, i, __) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: item.images[i],
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (_, __) => Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}