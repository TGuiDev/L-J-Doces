import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../widgets/favorite_icon.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'orders_screen.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({
    Key? key,
    required this.child,
  }) : super(key: key);

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

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _homeScrollController = ScrollController();

  int _currentIndex = 0;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();

    _homeScrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();

      adminProvider.fetchCategories();

      adminProvider.fetchProductsPage(
        refresh: true,
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
      );

      final authProvider = context.read<AuthProvider>();

      if (authProvider.isAuthenticated && authProvider.token != null) {
        context.read<FavoritesProvider>().fetchFavorites(authProvider.token!);
      }
    });
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onScroll);
    _homeScrollController.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onScroll() {
    if (!_homeScrollController.hasClients) return;

    final position = _homeScrollController.position;

    if (position.pixels >= position.maxScrollExtent - 850) {
      context.read<AdminProvider>().fetchProductsPage(
            categoryId: _selectedCategoryId,
            subcategoryId: _selectedSubcategoryId,
          );
    }
  }

  void _reloadProducts() {
    context.read<AdminProvider>().fetchProductsPage(
          refresh: true,
          categoryId: _selectedCategoryId,
          subcategoryId: _selectedSubcategoryId,
        );
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
        _reloadProducts();
      },
      child: CustomScrollView(
        controller: _homeScrollController,
        cacheExtent: 1000,
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroBanner(),
          ),

          SliverToBoxAdapter(
            child: _buildQuickActions(),
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

          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: _selectedCategoryId == null
                  ? 'Mais pedidos'
                  : currentSelectedCategory?.name ?? 'Produtos',
              subtitle: 'Carregando aos poucos para ficar mais rápido',
            ),
          ),

          if (adminProvider.isLoadingProducts && products.isEmpty)
            _buildProductSkeletonGrid()
          else if (products.isEmpty)
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
            )
          else
            _buildProductSliverGrid(products),

          if (adminProvider.isLoadingProducts && products.isNotEmpty)
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

          if (!adminProvider.hasMoreProducts && products.isNotEmpty)
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
        ],
      ),
    );
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
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_homeScrollController.hasClients) {
                      _homeScrollController.animateTo(
                        360,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF7A00),
                    size: 20,
                  ),
                  label: const Text(
                    'Ver produtos',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.cake_outlined,
              title: 'Sob encomenda',
              subtitle: 'Planeje seu pedido',
              color: const Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.schedule_rounded,
              title: 'Para hoje',
              subtitle: 'Pronta entrega',
              color: Colors.green.shade600,
            ),
          ),
        ],
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
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;

            return _CategoryCard(
              title: 'Todos',
              imageUrl: null,
              icon: Icons.grid_view_rounded,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCategoryId = null;
                  _selectedSubcategoryId = null;
                });
                _reloadProducts();
              },
            );
          }

          final category = categories[index - 1];
          final isSelected = _selectedCategoryId == category.id;

          return _CategoryCard(
            title: category.name,
            imageUrl: category.imageUrl,
            icon: Icons.fastfood_rounded,
            isSelected: isSelected,
            onTap: () {
              setState(() {
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
          }).toList(),
        ],
      ),
    );
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
          addAutomaticKeepAlives: false,
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
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Ajustes',
        ),
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
                          CircleAvatar(
                            radius: 31,
                            backgroundColor:
                                const Color(0xFFFF7A00).withOpacity(0.16),
                            backgroundImage: authProvider.user!.picture != null
                                ? NetworkImage(authProvider.user!.picture!)
                                : null,
                            child: authProvider.user!.picture == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: Color(0xFFFF7A00),
                                  )
                                : null,
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

  const _CategoryCard({
    required this.title,
    required this.imageUrl,
    required this.icon,
    required this.isSelected,
    required this.onTap,
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
                        Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
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
                color:
                    isSelected ? const Color(0xFFFF7A00) : Colors.black87,
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
              backgroundImage: NetworkImage(imageUrl!),
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
                      FadeInImage.assetNetwork(
                        placeholder: 'lib/assets/images/Logo.png',
                        image: imageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 250),
                        imageErrorBuilder: (_, __, ___) {
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