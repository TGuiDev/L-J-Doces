import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/stock_sync_provider.dart';
import '../widgets/favorite_icon.dart';
import 'cart_screen.dart';
import 'home_screen.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  int _quantity = 1;
  final TextEditingController _obsController = TextEditingController();
  StockSyncProvider? _stockSyncProvider;
  int _currentStockQuantity = 0;
  void Function(int)? _stockListener;

  @override
  void initState() {
    super.initState();
    // Inscrever-se nas atualizações de estoque em tempo real
    _stockSyncProvider = context.read<StockSyncProvider>();

    // Verificar se existe valor em cache; senão, usar do produto e cachear
    final cachedStock = _stockSyncProvider?.getProductStock(widget.product.id);
    if (cachedStock != null) {
      _currentStockQuantity = cachedStock;
    } else {
      _currentStockQuantity = widget.product.stockQuantity;
      _stockSyncProvider?.setProductStock(widget.product.id, widget.product.stockQuantity);
    }

    _stockListener = (newQuantity) {
      // Atualizar o produto localmente
      if (!mounted) return;
      setState(() {
        _currentStockQuantity = newQuantity;
        if (_quantity > _currentStockQuantity) {
          _quantity = _currentStockQuantity > 0 ? _currentStockQuantity : 1;
        }
      });
    };
    _stockSyncProvider?.subscribeToProductStock(widget.product.id, _stockListener!);
  }

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCartAndShowDialog() {
    final cart = context.read<CartProvider>();
    final added = cart.addItem(
      widget.product,
      quantity: _quantity,
      observation: _obsController.text.trim(),
    );

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há estoque suficiente para adicionar mais itens.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Produto adicionado!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'O item foi adicionado à sua sacola com sucesso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed('/checkout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ir para Pagamento', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.maybePop(ctx); // Close dialog
                  Navigator.maybePop(context); // Go back from Product Screen
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.orange[600]!, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Continuar Comprando', style: TextStyle(color: Colors.orange[600], fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    final stockSyncProvider = _stockSyncProvider;
    final stockListener = _stockListener;
    if (stockSyncProvider != null && stockListener != null) {
      stockSyncProvider.unsubscribeFromProductStock(widget.product.id, stockListener);
    }
    _pageController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.product;
    final cart = context.watch<CartProvider>();
    final currentInCart = cart.items[prod.id]?.quantity ?? 0;
    final availableToAdd = _currentStockQuantity - currentInCart;
    final canIncrease = availableToAdd > _quantity;
    final canAddSelectedQuantity = availableToAdd > 0 && availableToAdd >= _quantity;
    final images = prod.images.isNotEmpty
      ? prod.images
      : [
        'assets/images/app_icon.png',
        ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
                actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFav = favoritesProvider.isFavorite(widget.product.id);
              return IconButton(
                icon: FavoriteIcon(
                  isFavorite: isFav,
                  color: Colors.black87,
                  size: 24,
                ),
                onPressed: () {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.isAuthenticated && authProvider.token != null) {
                    favoritesProvider.toggleFavorite(authProvider.token!, widget.product.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Faça login para favoritar produtos.')),
                    );
                  }
                },
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel com setas laterais e miniaturas
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 60)),
                      );
                    },
                  ),
                  // Setas laterais
                  if (images.length > 1)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: Icon(Icons.chevron_left, size: 36, color: Colors.black.withOpacity(_currentImageIndex > 0 ? 0.7 : 0.2)),
                        onPressed: _currentImageIndex > 0
                            ? () {
                                _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            : null,
                      ),
                    ),
                  if (images.length > 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: Icon(Icons.chevron_right, size: 36, color: Colors.black.withOpacity(_currentImageIndex < images.length - 1 ? 0.7 : 0.2)),
                        onPressed: _currentImageIndex < images.length - 1
                            ? () {
                                _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            : null,
                      ),
                    ),
                  // Indicador de página
                  if (images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? Colors.orange
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            // Miniaturas
            if (images.length > 1)
              Column(
                children: [
                  Container(
                    height: 64,
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: EdgeInsets.all(_currentImageIndex == index ? 2 : 0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _currentImageIndex == index ? Colors.orange : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                images[index],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  width: 56,
                                  height: 56,
                                  child: Icon(Icons.broken_image, size: 24),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Details
            Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          prod.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${prod.price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange[800],
                            ),
                          ),
                          if (!prod.isAvailableToday)
                            Text(
                              prod.availableDaysString,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (prod.isAvailableToday)
                    if (_currentStockQuantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Em Estoque ($_currentStockQuantity)',
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Esgotado',
                          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Indisponível Hoje',
                        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prod.description.isNotEmpty
                        ? prod.description
                        : 'Sem descrição.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingredientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prod.ingredients.isNotEmpty
                        ? prod.ingredients
                        : 'Ingredientes não informados.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Disponibilidade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (prod.isAvailableToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Hoje!',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _dayBadge(0, 'Dom', prod.availableDays[0] == true),
                      _dayBadge(1, 'Seg', prod.availableDays[1] == true),
                      _dayBadge(2, 'Ter', prod.availableDays[2] == true),
                      _dayBadge(3, 'Qua', prod.availableDays[3] == true),
                      _dayBadge(4, 'Qui', prod.availableDays[4] == true),
                      _dayBadge(5, 'Sex', prod.availableDays[5] == true),
                      _dayBadge(6, 'Sáb', prod.availableDays[6] == true),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Alguma observação?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _obsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ex: Tirar cebola, ponto da carne...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.orange[400]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _decrementQuantity,
                      color: Colors.orange[800],
                    ),
                    Text('$_quantity',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: canIncrease ? _incrementQuantity : null,
                      color: Colors.orange[800],
                      disabledColor: Colors.grey[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (canAddSelectedQuantity && prod.isAvailableToday) ? _addToCartAndShowDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: (_currentStockQuantity > 0 && prod.isAvailableToday) ? Colors.white : Colors.grey[600]
                      ),
                      const SizedBox(width: 8),
                      Text(
                        !prod.isAvailableToday
                            ? 'Fora de rodízio'
                          : (availableToAdd > 0 ? 'Adicionar à sacola' : 'Estoque indisponível'),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (_currentStockQuantity > 0 && prod.isAvailableToday) ? Colors.white : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayBadge(int day, String name, bool active) {
    if (!active) return const SizedBox.shrink();

    final bool isToday = (DateTime.now().weekday % 7) == day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? Colors.green[50] : Colors.orange[50],
        border: Border.all(
            color: isToday ? Colors.green[400]! : Colors.orange[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            Icon(Icons.calendar_today, size: 14, color: Colors.green[700]),
            const SizedBox(width: 4),
          ],
          Text(
            isToday ? '$name (Hoje)' : name,
            style: TextStyle(
              color: isToday ? Colors.green[800] : Colors.orange[800],
              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
