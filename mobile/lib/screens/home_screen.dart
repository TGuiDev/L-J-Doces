import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../widgets/favorite_icon.dart';
import '../widgets/profile_image_widget.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'orders_screen.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (_controller.value - 0.35).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.35).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> globalKey =
      GlobalKey<_HomeScreenState>();

  final List<Product> initialTopOrderedProducts;

  const HomeScreen({
    super.key,
    this.initialTopOrderedProducts = const [],
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _homeScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;
  String? _selectedCategoryId;
  String? _previousCategoryId;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  int _suggestionSeed = DateTime.now().millisecondsSinceEpoch;
  List<Product> _topOrderedProducts = [];

  bool _isSvgUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('.svg') || lower.contains('/svg?');
  }

  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();

    _homeScrollController.addListener(_onScroll);
    _topOrderedProducts = List<Product>.of(widget.initialTopOrderedProducts);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adminProvider = context.read<AdminProvider>();
      final authProvider = context.read<AuthProvider>();
      final initialLoadTasks = <Future<void>>[];

      if (adminProvider.categories.isEmpty) {
        initialLoadTasks.add(adminProvider.fetchCategories());
      }

      if (adminProvider.allProducts.isEmpty || adminProvider.products.isEmpty) {
        initialLoadTasks.add(
          adminProvider.fetchProductsPage(
            refresh: true,
            forceApiRefresh: adminProvider.allProducts.isEmpty,
            categoryId: _selectedCategoryId,
            subcategoryId: _selectedSubcategoryId,
          ),
        );
      }

      if (authProvider.isAuthenticated && authProvider.token != null) {
        final favoritesProvider = context.read<FavoritesProvider>();
        if (favoritesProvider.favoriteProductIds.isEmpty) {
          initialLoadTasks.add(
            favoritesProvider.fetchFavorites(authProvider.token!),
          );
        }
      }

      await Future.wait<void>(initialLoadTasks);

      if (_topOrderedProducts.isEmpty) {
        await _loadTopOrderedProducts();
      }
    });
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onScroll);
    _homeScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onScroll() {
    if (!_homeScrollController.hasClients) return;
    if (_showFavoritesOnly || _selectedCategoryId == null) return;

    final position = _homeScrollController.position;
    final adminProvider = context.read<AdminProvider>();

    if (position.pixels >= position.maxScrollExtent - 850 &&
        adminProvider.hasMoreProducts &&
        !adminProvider.isLoadingProducts) {
      adminProvider.fetchProductsPage(
            categoryId: _selectedCategoryId,
            subcategoryId: _selectedSubcategoryId,
          );
    }
  }

  void _reloadProducts({bool forceApiRefresh = false}) {
    context.read<AdminProvider>().fetchProductsPage(
          refresh: true,
          forceApiRefresh: forceApiRefresh,
          categoryId: _selectedCategoryId,
          subcategoryId: _selectedSubcategoryId,
        );
  }

  Future<void> _loadTopOrderedProducts() async {
    try {
      final topOrderedProducts = await _apiService.getTopOrderedProducts();

      if (!mounted) return;

      setState(() {
        _topOrderedProducts = topOrderedProducts;
        _suggestionSeed = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (e) {
      debugPrint('[HomeScreen] Erro ao carregar mais pedidos: $e');

      if (!mounted) return;

      setState(() {
        _topOrderedProducts = [];
        _suggestionSeed = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();

    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    final categories = adminProvider.categories;
    final products = adminProvider.products;

    Category? currentSelectedCategory;

    if (_selectedCategoryId != null && categories.isNotEmpty) {
      try {
        currentSelectedCategory = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
        );
      } catch (_) {
        currentSelectedCategory = null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: _buildAppBar(
        context: context,
        isAuthenticated: isAuthenticated,
        authProvider: authProvider,
        isAdmin: isAuthenticated && user != null && user.isAdmin,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(
            context: context,
            adminProvider: adminProvider,
            categories: categories,
            products: products,
            currentSelectedCategory: currentSelectedCategory,
          ),
          CartScreen(
            isRoot: true,
            onContinueShopping: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          const OrdersScreen(showBackButton: false),
          const Center(
            child: Text(
              'Configurações em breve',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required bool isAuthenticated,
    required bool isAdmin,
    required AuthProvider authProvider,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(78),
      child: Container(
        color: const Color(0xFFF8F7F5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(7),
                  child: const Image(
                    image: AssetImage('lib/assets/images/app_icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, seja bem-vindo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Escolha sua delícia',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1F1F1F),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFFF5A000),
                      ),
                      tooltip: 'Painel de Administração',
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin');
                      },
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF111827),
                      size: 28,
                    ),
                    onPressed: () {
                      if (isAuthenticated) {
                        _showProfileBottomSheet(context, authProvider);
                      } else {
                        Navigator.pushNamed(context, '/signin');
                      }
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

  Widget _buildHomeTab({
    required BuildContext context,
    required AdminProvider adminProvider,
    required List<Category> categories,
    required List<Product> products,
    required Category? currentSelectedCategory,
  }) {
    return RefreshIndicator(
      color: const Color(0xFFFF7A00),
      onRefresh: () async {
        await context.read<AdminProvider>().fetchProductsPage(
              refresh: true,
              forceApiRefresh: true,
              categoryId: _selectedCategoryId,
              subcategoryId: _selectedSubcategoryId,
            );
        await _loadTopOrderedProducts();
      },
      child: CustomScrollView(
        controller: _homeScrollController,
        cacheExtent: 1000,
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroBanner(),
          ),
          // SliverToBoxAdapter(
          //   child: _buildQuickActions(),
          // ),
          SliverToBoxAdapter(
            child: _buildSearchBox(),
          ),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'Categorias',
              subtitle: 'Filtre pelo que você está procurando',
            ),
          ),
          if (adminProvider.isLoading && categories.isEmpty)
            SliverToBoxAdapter(
              child: _buildCategorySkeleton(),
            )
          else if (categories.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildCategories(categories),
            ),
          if (currentSelectedCategory != null &&
              currentSelectedCategory.subcategories.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSubcategories(currentSelectedCategory),
            ),
          if (_selectedCategoryId == null && !_showFavoritesOnly)
            ...[
              _buildMostOrderedSection(adminProvider.allProducts),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'Sugestoes para voce',
                  subtitle: 'Todos os itens em ordem aleatoria',
                ),
              ),
              _buildRandomProductsGrid(adminProvider.allProducts),
            ]
          else ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: _showFavoritesOnly
                    ? 'Favoritos'
                    : currentSelectedCategory?.name ?? 'Produtos',
                subtitle: _showFavoritesOnly
                    ? 'Seus itens favoritos salvos'
                    : 'Carregando aos poucos para ficar mais rapido',
              ),
            ),
            ..._buildFilteredProductsSlivers(
              products: products,
              adminProvider: adminProvider,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMostOrderedSection(List<Product> allProducts) {
    final mostOrdered = _getMostOrderedProducts(allProducts);

    if (mostOrdered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Text(
            'Nenhum produto comprado para mostrar por enquanto.',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Mais pedidos',
            subtitle: 'Os 10 itens mais comprados',
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: mostOrdered.length,
              itemBuilder: (context, index) {
                final product = mostOrdered[index];

                return SizedBox(
                  width: 160,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == mostOrdered.length - 1 ? 0 : 12,
                    ),
                    child: _HorizontalProductCard(product: product),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  List<Product> _getMostOrderedProducts(List<Product> allProducts) {
    if (_topOrderedProducts.isNotEmpty) {
      return _topOrderedProducts.take(10).toList();
    }

    return allProducts.take(10).toList();
  }

  List<Product> _buildRandomProducts(List<Product> allProducts) {
    final randomProducts = List<Product>.of(allProducts);
    randomProducts.shuffle(Random(_suggestionSeed));
    return randomProducts;
  }

  Widget _buildRandomProductsGrid(List<Product> allProducts) {
    final randomProducts = _buildRandomProducts(allProducts);

    if (randomProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Text(
            'Nenhum item para mostrar por enquanto.',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    return _buildProductSliverGrid(randomProducts);
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 210,
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7A00),
            Color(0xFFFFA726),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A00).withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -35,
            bottom: -20,
            top: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(120),
              child: FadeInImage.assetNetwork(
                placeholder: 'lib/assets/images/Logo.png',
                image:
                    'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=900&q=80',
                width: 210,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                imageErrorBuilder: (_, __, ___) {
                  return Container(
                    width: 210,
                    color: Colors.white.withOpacity(0.15),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF7A00),
                    const Color(0xFFFF7A00).withOpacity(0.96),
                    const Color(0xFFFF7A00).withOpacity(0.25),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.46, 0.78, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Fresquinho hoje',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Doces, bolos e\nsabores especiais',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                // const SizedBox(height: 14),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     if (_homeScrollController.hasClients) {
                //       _homeScrollController.animateTo(
                //         360,
                //         duration: const Duration(milliseconds: 400),
                //         curve: Curves.easeOut,
                //       );
                //     }
                //   },
                //   style: ElevatedButton.styleFrom(
                //     elevation: 0,
                //     backgroundColor: Colors.white,
                //     foregroundColor: const Color(0xFF1F1F1F),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 14,
                //       vertical: 10,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(14),
                //     ),
                //   ),
                //   icon: const Icon(
                //     Icons.local_fire_department_rounded,
                //     color: Color(0xFFFF7A00),
                //     size: 20,
                //   ),
                //   label: const Text(
                //     'Ver produtos',
                //     style: TextStyle(
                //       fontWeight: FontWeight.w900,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildQuickActions() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: _QuickActionCard(
  //             icon: Icons.cake_outlined,
  //             title: 'Sob encomenda',
  //             subtitle: 'Planeje seu pedido',
  //             color: const Color(0xFFFF7A00),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: _QuickActionCard(
  //             icon: Icons.schedule_rounded,
  //             title: 'Para hoje',
  //             subtitle: 'Pronta entrega',
  //             color: Colors.green.shade600,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFE5CC),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1F1F),
          ),
          decoration: InputDecoration(
            hintText: 'Buscar doces, bolos...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFFF7A00),
                  size: 22,
                ),
              ),
            ),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _searchQuery.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : const SizedBox(width: 12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: 5,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ShimmerLoading(
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 58,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildCategories(List<Category> categories) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: categories.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected =
                _selectedCategoryId == null && !_showFavoritesOnly;

            return _CategoryCard(
              title: 'Todos',
              imageUrl: null,
              icon: Icons.grid_view_rounded,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _showFavoritesOnly = false;
                  _previousCategoryId = null;
                  _selectedCategoryId = null;
                  _selectedSubcategoryId = null;
                });

                _reloadProducts(forceApiRefresh: true);
              },
            );
          }

          if (index == 1) {
            return _CategoryCard(
              title: 'Favoritos',
              imageUrl: null,
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFFF4D6D),
              isSelected: _showFavoritesOnly,
              onTap: () {
                setState(() {
                  _previousCategoryId = _selectedCategoryId;
                  _showFavoritesOnly = true;
                  _selectedCategoryId = null;
                  _selectedSubcategoryId = null;
                });

                final adminProvider = context.read<AdminProvider>();
                if (adminProvider.allProducts.isEmpty) {
                  _reloadProducts(forceApiRefresh: true);
                }
              },
            );
          }

          final category = categories[index - 2];
          final isSelected =
              _selectedCategoryId == category.id && !_showFavoritesOnly;

          return _CategoryCard(
            title: category.name,
            imageUrl: category.imageUrl,
            icon: Icons.fastfood_rounded,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _showFavoritesOnly = false;
                _selectedCategoryId = category.id;
                _selectedSubcategoryId = null;
              });

              _reloadProducts();
            },
          );
        },
      ),
    );
  }

  Widget _buildSubcategories(Category category) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Row(
        children: [
          _SubcategoryChip(
            label: 'Todos',
            selected: _selectedSubcategoryId == null,
            onTap: () {
              setState(() {
                _selectedSubcategoryId = null;
              });
              _reloadProducts();
            },
          ),
          const SizedBox(width: 8),
          ...category.subcategories.map((sub) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SubcategoryChip(
                label: sub.name,
                selected: _selectedSubcategoryId == sub.id,
                imageUrl: sub.imageUrl,
                onTap: () {
                  setState(() {
                    _selectedSubcategoryId =
                        _selectedSubcategoryId == sub.id ? null : sub.id;
                  });
                  _reloadProducts();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredProductsSlivers({
    required List<Product> products,
    required AdminProvider adminProvider,
  }) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favoriteIds = favoritesProvider.favoriteProductIds.toSet();

    // Apply search filter and favorites filter
    final filteredProducts = products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery);

      final matchesFavorites =
          !_showFavoritesOnly || favoriteIds.contains(product.id);

      return matchesSearch && matchesFavorites;
    }).toList();

    final List<Widget> slivers = [];

    if (adminProvider.isLoadingProducts && products.isEmpty) {
      slivers.add(_buildProductSkeletonGrid());
    } else if (filteredProducts.isEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Nenhum produto encontrado',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      slivers.add(_buildProductSliverGrid(filteredProducts));

      if (adminProvider.isLoadingProducts && products.isNotEmpty) {
        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7A00),
                ),
              ),
            ),
          ),
        );
      }

      if (!adminProvider.hasMoreProducts && products.isNotEmpty) {
        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 34),
              child: Center(
                child: Text(
                  'Você chegou ao fim da lista',
                  style: TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  Widget _buildFilteredProductsSliver({
    required List<Product> products,
    required AdminProvider adminProvider,
  }) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favoriteIds = favoritesProvider.favoriteProductIds.toSet();

    // Apply search filter and favorites filter
    final filteredProducts = products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery);

      final matchesFavorites =
          !_showFavoritesOnly || favoriteIds.contains(product.id);

      return matchesSearch && matchesFavorites;
    }).toList();

    if (adminProvider.isLoadingProducts && products.isEmpty) {
      return _buildProductSkeletonGrid();
    } else if (filteredProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildProductSliverGrid(filteredProducts),
          if (adminProvider.isLoadingProducts && products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7A00),
                ),
              ),
            ),
          if (!adminProvider.hasMoreProducts && products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 34),
              child: Center(
                child: Text(
                  'Você chegou ao fim da lista',
                  style: TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ]),
      );
    }
  }

  Widget _buildProductSliverGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];

            return _ProductCard(product: product);
          },
          childCount: products.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
      ),
    );
  }

  Widget _buildProductSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, index) {
            return ShimmerLoading(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            );
          },
          childCount: 8,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFF7A00),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Catálogo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Sacola',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Compras',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.settings_outlined),
        //   label: 'Ajustes',
        // ),
      ],
    );
  }

  void _showProfileBottomSheet(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    if (authProvider.user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 1,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 5,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    children: [
                      Row(
                        children: [
                          ProfileImageWidget(
                            imageUrl: authProvider.user!.picture,
                            radius: 31,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.user!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  authProvider.user!.email,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const _MenuSectionTitle('MINHA CONTA'),
                      _MenuTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Informações da conta',
                        onTap: () {},
                      ),
                      _MenuTile(
                        icon: Icons.payment_rounded,
                        title: 'Pagamentos',
                        onTap: () {},
                      ),
                      _MenuTile(
                        icon: Icons.receipt_long_rounded,
                        title: 'Meus pedidos',
                        onTap: () {
                          Navigator.maybePop(context);
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                      ),
                      const Divider(height: 32),
                      const _MenuSectionTitle('USO E PRIVACIDADE'),
                      _MenuTile(
                        icon: Icons.tune_rounded,
                        title: 'Preferências',
                        onTap: () {},
                      ),
                      _MenuTile(
                        icon: Icons.shield_outlined,
                        title: 'Direitos e solicitações',
                        onTap: () {},
                      ),
                      const Divider(height: 32),
                      const _MenuSectionTitle('AJUDA'),
                      _MenuTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Dúvidas frequentes',
                        onTap: () {},
                      ),
                      _MenuTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Fale com a gente',
                        onTap: () {},
                      ),
                      const SizedBox(height: 30),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await authProvider.logout();

                          if (context.mounted) {
                            Navigator.maybePop(context);
                          }
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Sair da conta',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.45),
                          ),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CategoryCard({
    required this.title,
    required this.imageUrl,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7A00) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF7A00)
                      : Colors.grey.withOpacity(0.15),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFFFF7A00).withOpacity(0.25)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                          ),
                          errorWidget: (_, __, ___) {
                            return Icon(
                              icon,
                              color:
                                  isSelected ? Colors.white : Colors.grey[500],
                            );
                          },
                        ),
                        if (isSelected)
                          Container(
                            color: const Color(0xFFFF7A00).withOpacity(0.32),
                          ),
                      ],
                    )
                  : Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 30,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? const Color(0xFFFF7A00) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SubcategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  bool _isSvgUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('.svg') || lower.contains('/svg?');
  }

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFE3C7),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFFFF7A00) : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      avatar: imageUrl != null && imageUrl!.isNotEmpty
          ? CircleAvatar(
              backgroundImage:
                  !_isSvgUrl(imageUrl) ? NetworkImage(imageUrl!) : null,
              child: _isSvgUrl(imageUrl)
                  ? ClipOval(
                      child: SvgPicture.network(
                        imageUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
            )
          : null,
      label: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFFFF7A00) : Colors.black87,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HorizontalProductCard extends StatelessWidget {
  final Product product;

  const _HorizontalProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty
        ? product.images.first
        : 'assets/images/Logo.png';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) {
                  return const Image(
                    image: AssetImage('lib/assets/images/Logo.png'),
                    fit: BoxFit.contain,
                  );
                },
                errorWidget: (_, __, ___) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F1F1F),
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE86F00),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
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

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty
        ? product.images.first
        : 'assets/images/Logo.png';

    final authProvider = context.read<AuthProvider>();

    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFav = favoritesProvider.isFavorite(product.id);

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductScreen(product: product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) {
                          return const Image(
                            image: AssetImage('lib/assets/images/Logo.png'),
                            fit: BoxFit.contain,
                          );
                        },
                        fadeInDuration: const Duration(milliseconds: 250),
                        errorWidget: (_, __, ___) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: product.isAvailableToday
                                ? Colors.green.shade600
                                : Colors.redAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            product.isAvailableToday ? 'Hoje' : 'Agendar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            if (authProvider.isAuthenticated &&
                                authProvider.token != null) {
                              favoritesProvider.toggleFavorite(
                                authProvider.token!,
                                product.id,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Faça login para favoritar produtos.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: FavoriteIcon(
                                isFavorite: isFav,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F1F1F),
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!product.isAvailableToday)
                        Text(
                          product.availableDaysString,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const Text(
                          'Disponível hoje',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE86F00),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
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
        );
      },
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  final String title;

  const _MenuSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: const Color(0xFF111827),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
