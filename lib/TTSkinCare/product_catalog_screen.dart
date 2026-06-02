import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../cart_logic.dart';
import 'dark_logic.dart';
import 'product_detail_screen.dart';
import '../model/product_model.dart';
import '../service/skincare_service.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _scroller = ScrollController();
  bool _showFab = false;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  final _service = SkincareService();
  late Future<List<SkincareProduct>> _futureData = _service.readAll();

  @override
  void initState() {
    super.initState();
    _scroller.addListener(() {
      final show = _scroller.position.pixels > 500;
      if (show != _showFab) setState(() => _showFab = show);
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final all = await _service.readAll();
    final cats = all.map((p) => p.category.name).toSet().toList()..sort();
    setState(() => _categories = ['All', ...cats]);
  }

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
      _futureData = cat == 'All'
          ? _service.readAll()
          : _service.readByCategory(cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<LayoutConfigLogic>();
    final cart = context.watch<CartLogic>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skincare'),
        actions: [
          IconButton(
            icon: Icon(config.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => context.read<LayoutConfigLogic>().toggleDark(),
          ),
          IconButton(
            icon: Icon(config.isGridStyle ? Icons.list : Icons.grid_view),
            onPressed: () => context.read<LayoutConfigLogic>().toggleStyle(),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => _showCart(context),
              ),
              if (cart.totalCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '${cart.totalCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(child: _buildBody(config)),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () => _scroller.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => _onCategorySelected(cat),
          );
        },
      ),
    );
  }

  Widget _buildBody(LayoutConfigLogic config) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _futureData = _selectedCategory == 'All'
              ? _service.readAll()
              : _service.readByCategory(_selectedCategory);
        });
      },
      child: FutureBuilder<List<SkincareProduct>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return _buildGrid(snapshot.data!, config);
          }
          return _buildSkeleton(config);
        },
      ),
    );
  }

  Widget _buildSkeleton(LayoutConfigLogic config) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final w = MediaQuery.of(context).size.width;
    return Skeletonizer(
      child: GridView.builder(
        controller: _scroller,
        padding: EdgeInsets.symmetric(
            horizontal: w > 1200 ? (w - 1200) / 2 : 8, vertical: 8),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: config.isGridStyle ? (isLandscape ? 4 : 2) : 1,
          childAspectRatio: config.isGridStyle ? 2 / 3 : 5 / 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 10,
        itemBuilder: (_, __) => Card(
          child: Column(children: [
            Expanded(child: Container(color: Colors.grey.shade200)),
            const SizedBox(height: 8),
            Container(height: 14, width: 120, color: Colors.grey.shade300),
            const SizedBox(height: 6),
            Container(height: 12, width: 60, color: Colors.grey.shade300),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _buildGrid(List<SkincareProduct> items, LayoutConfigLogic config) {
    if (items.isEmpty) {
      return const Center(child: Text('No products found.'));
    }
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final w = MediaQuery.of(context).size.width;
    return GridView.builder(
      controller: _scroller,
      padding: EdgeInsets.symmetric(
          horizontal: w > 1200 ? (w - 1200) / 2 : 8, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config.isGridStyle ? (isLandscape ? 4 : 2) : 1,
        childAspectRatio: config.isGridStyle ? 2 / 3 : 5 / 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCard(items[i], config.isGridStyle),
    );
  }

  Widget _buildCard(SkincareProduct item, bool isGrid) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailScreen(item)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: isGrid ? _gridCard(item) : _listCard(item),
      ),
    );
  }

  Widget _gridCard(SkincareProduct item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: item.images[0],
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey.shade300),
              ),
              if (item.hasDiscount)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${item.discountPercent}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Text(
            item.brand,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              Text(
                '\$${item.discountPrice}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
              if (item.hasDiscount) ...[
                const SizedBox(width: 4),
                Text(
                  '\$${item.price}',
                  style: const TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey),
                ),
              ],
              const Spacer(),
              Icon(Icons.star, size: 13, color: Colors.amber.shade600),
              Text(' ${item.rating}', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _listCard(SkincareProduct item) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: item.images[0],
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey.shade300),
              ),
              if (item.hasDiscount)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text('-${item.discountPercent}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.brand,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(item.category.name,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('\$${item.discountPrice}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text('\$${item.price}',
                          style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey)),
                    ],
                    const Spacer(),
                    Icon(Icons.star, size: 13, color: Colors.amber.shade600),
                    Text(' ${item.rating}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error: $error'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  setState(() => _futureData = _service.readAll()),
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CartSheet(),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartLogic>();
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cart (${cart.totalCount})',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                    onPressed: cart.clear, child: const Text('Clear All')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final ci = cart.items[i];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: ci.product.images[0],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(ci.product.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('\$${ci.product.discountPrice}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              onPressed: () =>
                                  context.read<CartLogic>().decrementItem(
                                        ci.product.id,
                                      ),
                            ),
                            Text('${ci.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 20),
                              onPressed: () =>
                                  context.read<CartLogic>().addItem(ci.product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order placed!')),
                        );
                        cart.clear();
                      },
                child: Text(
                    'Checkout  •  \$${cart.totalPrice.toStringAsFixed(2)}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}