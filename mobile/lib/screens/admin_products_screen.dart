import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import "dart:typed_data";

import "package:image_picker/image_picker.dart";
import "package:http_parser/http_parser.dart";

import "package:dio/dio.dart";

import "package:flutter_dotenv/flutter_dotenv.dart";

const Color _brandOrange = Color(0xFFFFA726);
const Color _brandOrangeDark = Color(0xFFF97316);
const Color _brandOrangeSoft = Color(0xFFFFEDD5);
const Color _creamBg = Color(0xFFFFFBF4);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textDark = Color(0xFF111827);
const Color _mutedText = Color(0xFF6B7280);
const Color _softBorder = Color(0xFFFFE0B2);
const Color _successGreen = Color(0xFF16A34A);
const Color _dangerRed = Color(0xFFEF4444);
const LinearGradient _brandGradient = LinearGradient(
  colors: [_brandOrange, _brandOrangeDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxShadow _softShadow([double opacity = 0.08]) => BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: 28,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    );

bool _looksLikeSvg(Uint8List bytes) {
  final header = utf8.decode(bytes.take(200).toList(), allowMalformed: true).toLowerCase();
  return header.contains('<svg');
}

Widget _buildImagePreview(Uint8List bytes, {BoxFit fit = BoxFit.cover}) {
  if (_looksLikeSvg(bytes)) {
    return SvgPicture.memory(bytes, fit: fit);
  }
  return Image.memory(bytes, fit: fit);
}

InputDecoration _prettyInput({
  required String label,
  IconData? icon,
  String? hint,
  String? prefixText,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: icon == null ? null : Icon(icon, color: _brandOrangeDark),
    filled: true,
    fillColor: const Color(0xFFFFFCF7),
    labelStyle: const TextStyle(color: _mutedText, fontWeight: FontWeight.w500),
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _softBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _softBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _brandOrangeDark, width: 1.7),
    ),
  );
}

class _AiParticleButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double size;

  const _AiParticleButton({
    required this.tooltip,
    required this.onPressed,
    this.isLoading = false,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: radius,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              boxShadow: [_softShadow(0.10)],
            ),
            child: Stack(
              children: [
                // const Positioned(
                //   left: 9,
                //   top: 7,
                //   child: Text('✨', style: TextStyle(fontSize: 13)),
                // ),
                // const Positioned(
                //   right: 8,
                //   top: 10,
                //   child: Text('🍰', style: TextStyle(fontSize: 13)),
                // ),
                // const Positioned(
                //   left: 10,
                //   bottom: 8,
                //   child: Text('🤖', style: TextStyle(fontSize: 13)),
                // ),
                // const Positioned(
                //   right: 10,
                //   bottom: 9,
                //   child: Text('✨', style: TextStyle(fontSize: 12)),
                // ),
                Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 30,
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

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _productSearchCtrl = TextEditingController();

  String _searchQuery = '';
  String? _selectedFilterCategoryId;
  String? _selectedFilterSubcategoryId;
  final Set<int> _selectedFilterDays = <int>{};
  String _selectedStockFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Dispara a busca inicial de dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchCategories();
      context.read<AdminProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _brandGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Gerenciar Produtos',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Painel administrativo',
              style: TextStyle(
                color: Color(0xFFFFF7ED),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFFFFFF),
          unselectedLabelColor: Colors.grey[200],
          indicator: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Categorias'),
            Tab(text: 'Produtos'),
          ],
        ),
      ),
      body: adminProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(adminProvider.categories),
                _buildProductsTab(
                    adminProvider.products, adminProvider.categories),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCategoryDialog(context);
          } else {
            _showProductDialog(context, adminProvider.categories);
          }
        },
        backgroundColor: _brandOrangeDark,
        elevation: 14,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Novo' : 'Novo',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _softBorder),
          boxShadow: [_softShadow(0.04)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: _brandGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [_softShadow(0.10)],
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedText, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _brandOrangeSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _brandOrangeDark),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _brandOrangeDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(List<Category> categories) {
    if (categories.isEmpty) {
      return _emptyState(
        icon: Icons.category_outlined,
        title: 'Nenhuma categoria cadastrada',
        subtitle: 'Crie sua primeira categoria para organizar o cardápio.',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      header: _categoriesOverview(categories),
      itemCount: categories.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);
        context.read<AdminProvider>().updateCategoriesOrder(categories);
      },
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _categoryCard(cat, index, key: ValueKey(cat.id));
      },
    );
  }

  Widget _categoriesOverview(List<Category> categories) {
    final subcategoryCount = categories.fold<int>(
      0,
      (sum, category) => sum + category.subcategories.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE7C2)),
        boxShadow: [_softShadow(0.035)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniPill(
              icon: Icons.category_outlined,
              text: '${categories.length} categorias',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniPill(
              icon: Icons.account_tree_outlined,
              text: '$subcategoryCount subcategorias',
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(Category cat, int index, {Key? key}) {
    return Container(
      key: key,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE7C2)),
        boxShadow: [_softShadow(0.04)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: _brandOrangeDark,
        collapsedIconColor: _brandOrangeDark,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
            cat.name,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark),
          ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            cat.description.isEmpty
                ? '${cat.subcategories.length} subcategorias'
                : cat.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _mutedText, height: 1.25),
          ),
        ),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: _brandOrangeSoft,
            borderRadius: BorderRadius.circular(14),
            image: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(cat.imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: cat.imageUrl == null || cat.imageUrl!.isEmpty
              ? const Icon(Icons.fastfood_rounded, color: _brandOrangeDark)
              : null,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roundIconButton(
              icon: Icons.edit_rounded,
              color: Colors.blue,
              onPressed: () => _editCategory(cat),
            ),
            const SizedBox(width: 6),
            _roundIconButton(
              icon: Icons.delete_outline_rounded,
              color: _dangerRed,
              onPressed: () => _confirmDeleteCategory(cat),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_indicator_rounded, color: _mutedText),
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 18, color: Color(0xFFFFE7C2)),
          if (cat.subcategories.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cat.subcategories.length,
              buildDefaultDragHandles: false,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                return Material(
                  color: Colors.transparent,
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final subs = List<SubCategory>.from(cat.subcategories);
                final item = subs.removeAt(oldIndex);
                subs.insert(newIndex, item);
                context
                    .read<AdminProvider>()
                    .updateSubcategoriesOrder(cat.id, subs);
              },
              itemBuilder: (context, index) {
                final sub = cat.subcategories[index];
                return Container(
                  key: ValueKey(sub.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3E7D8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _creamBg,
                          borderRadius: BorderRadius.circular(12),
                          image: sub.imageUrl != null && sub.imageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(sub.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                      ),
                        child: sub.imageUrl == null || sub.imageUrl!.isEmpty
                            ? const Icon(Icons.account_tree_outlined,
                                color: _brandOrangeDark, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              sub.description.isEmpty
                                  ? 'Sem descricao'
                                  : sub.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _roundIconButton(
                        icon: Icons.edit_rounded,
                        color: Colors.blue,
                        onPressed: () => _editSubcategory(cat.id, sub),
                      ),
                      const SizedBox(width: 6),
                      _roundIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: _dangerRed,
                        onPressed: () => _confirmDeleteSubcategory(sub),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.drag_indicator_rounded,
                              color: _mutedText, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          InkWell(
            onTap: () => _showSubcategoryDialog(context, cat.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _brandOrangeSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD8A8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: _brandOrangeDark, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Adicionar subcategoria',
                    style: TextStyle(
                      color: _brandOrangeDark,
                      fontWeight: FontWeight.w900,
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

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.10),
        foregroundColor: color,
        minimumSize: const Size(34, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _safeString(Object? Function() read, [String fallback = '']) {
    try {
      final value = read();
      if (value == null) return fallback;
      return value.toString();
    } catch (_) {
      return fallback;
    }
  }

  String? _safeNullableString(Object? Function() read) {
    try {
      final value = read();
      return value?.toString();
    } catch (_) {
      return null;
    }
  }

  int _safeInt(Object? Function() read, [int fallback = 0]) {
    try {
      final value = read();
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  double _safeDouble(Object? Function() read, [double fallback = 0]) {
    try {
      final value = read();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
          fallback;
    } catch (_) {
      return fallback;
    }
  }

  List<String> _safeImages(Product product) {
    try {
      final images = product.images;
      if (images is List) {
        return images.map((image) => image.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  bool _safeIsAvailableToday(Product product) {
    try {
      return product.isAvailableToday;
    } catch (_) {
      return true;
    }
  }

  @override
  void dispose() {
    _productSearchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _matchesSelectedDays(Product product) {
    if (_selectedFilterDays.isEmpty) {
      return true;
    }

    try {
      final availableDays = product.availableDays;
      if (availableDays.isEmpty) return true;

      return _selectedFilterDays.every(
        (day) => availableDays[day] == true,
      );
    } catch (_) {
      return true;
    }
  }

  bool _matchesStockFilter(Product product) {
    final stockQuantity = _safeInt(() => product.stockQuantity);
    switch (_selectedStockFilter) {
      case 'low':
        return stockQuantity > 0 && stockQuantity <= 5;
      case 'out':
        return stockQuantity <= 0;
      case 'in':
        return stockQuantity > 0;
      default:
        return true;
    }
  }

  void _clearProductFilters() {
    setState(() {
      _productSearchCtrl.clear();
      _searchQuery = '';
      _selectedFilterCategoryId = null;
      _selectedFilterSubcategoryId = null;
      _selectedFilterDays.clear();
      _selectedStockFilter = 'all';
    });
    context.read<AdminProvider>().fetchProductsPage(
          refresh: true,
          categoryId: null,
          forceApiRefresh: true,
        );
  }

  String _categoryLabel(Product product, List<Category> categories) {
    final productCategoryId = _safeString(() => product.categoryId);
    final productSubcategoryId =
        _safeNullableString(() => product.subcategoryId);

    for (final category in categories) {
      if (category.id != productCategoryId) continue;
      final subcategories = category.subcategories.where(
        (subcategory) => subcategory.id == productSubcategoryId,
      );
      if (subcategories.isNotEmpty) {
        return '${category.name} / ${subcategories.first.name}';
      }
      return category.name;
    }
    return 'Sem categoria';
  }

  Widget _productAdminCard(Product product, List<Category> categories) {
    final isAvailable = _safeIsAvailableToday(product);
    final images = _safeImages(product);
    final stockQuantity = _safeInt(() => product.stockQuantity);
    final costPrice = _safeDouble(() => product.costPrice);
    final price = _safeDouble(() => product.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE7C2)),
        boxShadow: [_softShadow(0.025)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 58,
                decoration: BoxDecoration(
                  color: _brandOrangeSoft,
                  borderRadius: BorderRadius.circular(10),
                  image: images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: images.isEmpty
                    ? const Icon(
                        Icons.bakery_dining_rounded,
                        color: _brandOrangeDark,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _safeString(() => product.name, 'Produto'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _textDark,
                              fontSize: 14,
                              height: 1.15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? _successGreen.withOpacity(0.12)
                                : _dangerRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isAvailable ? 'Hoje' : 'Agendar',
                            style: TextStyle(
                              color: isAvailable ? _successGreen : _dangerRed,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryLabel(product, categories),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Custo: ${_money(costPrice)}  •  Venda: ${_money(price)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniPill(
                icon: Icons.warehouse_outlined,
                text: '$stockQuantity estoque',
              ),
              const Spacer(),
              _roundIconButton(
                icon: Icons.edit_rounded,
                color: Colors.blue,
                onPressed: () => _editProduct(
                  context,
                  product,
                  context.read<AdminProvider>().categories,
                ),
              ),
              const SizedBox(width: 6),
              _roundIconButton(
                icon: Icons.delete_outline_rounded,
                color: _dangerRed,
                onPressed: () => _confirmDeleteProduct(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(List<Product> products, List<Category> categories) {
    // Debug filtragem detalhado
    if (_selectedFilterCategoryId != null && products.isNotEmpty) {
      final matchCount = products
          .where((p) =>
              _safeString(() => p.categoryId).toLowerCase() ==
              _selectedFilterCategoryId!.toLowerCase())
          .length;
      final uniqueIds =
          products.map((p) => _safeString(() => p.categoryId)).toSet().toList();
      debugPrint('[AdminProducts] Filter: $_selectedFilterCategoryId | Matches: $matchCount / ${products.length}');
      debugPrint('[AdminProducts] IDs únicos nos produtos: $uniqueIds');
      debugPrint(
          '[AdminProducts] Primeiro produto: name=${_safeString(() => products.first.name)}, categoryId=${_safeString(() => products.first.categoryId)}');
    }

    final filteredProducts = products.where((p) {
      final productName = _safeString(() => p.name);
      final categoryId = _safeString(() => p.categoryId);
      final subcategoryId = _safeNullableString(() => p.subcategoryId);
      final matchesSearch =
          productName.toLowerCase().contains(_searchQuery.toLowerCase());
      // Comparação case-insensitive para IDs (UUIDs podem ter variação de case)
      final matchesCat = _selectedFilterCategoryId == null ||
          (categoryId.isNotEmpty &&
              categoryId.toLowerCase() ==
                  _selectedFilterCategoryId!.toLowerCase());
      final matchesSub = _selectedFilterSubcategoryId == null ||
          (subcategoryId?.isNotEmpty == true &&
              subcategoryId!.toLowerCase() ==
                  _selectedFilterSubcategoryId!.toLowerCase());
      final matchesDays = _matchesSelectedDays(p);
      final matchesStock = _matchesStockFilter(p);
      return matchesSearch &&
          matchesCat &&
          matchesSub &&
          matchesDays &&
          matchesStock;
    }).toList();

    final totalStock = filteredProducts.fold<int>(
      0,
      (sum, product) => sum + _safeInt(() => product.stockQuantity),
    );
    final lowStockCount = filteredProducts
        .where(
          (product) {
            final stockQuantity = _safeInt(() => product.stockQuantity);
            return stockQuantity > 0 && stockQuantity <= 5;
          },
        )
        .length;
    final hasActiveFilters = _searchQuery.isNotEmpty ||
        _selectedFilterCategoryId != null ||
        _selectedFilterSubcategoryId != null ||
        _selectedFilterDays.isNotEmpty ||
        _selectedStockFilter != 'all';

    Category? currentCategory;
    if (_selectedFilterCategoryId != null && categories.isNotEmpty) {
      currentCategory = categories.firstWhere(
        (c) => c.id == _selectedFilterCategoryId,
        orElse: () => categories.first,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
              boxShadow: [_softShadow(0.04)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _miniPill(
                        icon: Icons.inventory_2_outlined,
                        text: '${filteredProducts.length} produtos',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniPill(
                        icon: Icons.warehouse_outlined,
                        text: '$totalStock em estoque',
                      ),
                    ),
                  ],
                ),
                if (lowStockCount > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _miniPill(
                      icon: Icons.warning_amber_rounded,
                      text: '$lowStockCount com estoque baixo',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _productSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar produto...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFDA516)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedFilterCategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Todas')),
                          ...categories.map((c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedFilterCategoryId = val;
                            _selectedFilterSubcategoryId = null;
                          });
                          context.read<AdminProvider>().fetchProductsPage(
                                refresh: true,
                                categoryId: val,
                                forceApiRefresh: true,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedFilterSubcategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Subcategoria',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Todas')),
                          if (currentCategory != null)
                            ...currentCategory.subcategories.map((s) =>
                                DropdownMenuItem(
                                    value: s.id, child: Text(s.name))),
                        ],
                        onChanged: _selectedFilterCategoryId == null
                            ? null
                            : (val) => setState(
                                () => _selectedFilterSubcategoryId = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStockFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Estoque',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'in',
                            child: Text('Com estoque'),
                          ),
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('Estoque baixo'),
                          ),
                          DropdownMenuItem(
                            value: 'out',
                            child: Text('Sem estoque'),
                          ),
                        ],
                        onChanged: (val) => setState(
                          () => _selectedStockFilter = val ?? 'all',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Limpar filtros',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: hasActiveFilters
                            ? _brandOrangeSoft
                            : const Color(0xFFF1F5F9),
                        foregroundColor:
                            hasActiveFilters ? _brandOrangeDark : _mutedText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: hasActiveFilters ? _clearProductFilters : null,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const <MapEntry<int, String>>[
                        MapEntry(0, 'Dom'),
                        MapEntry(1, 'Seg'),
                        MapEntry(2, 'Ter'),
                        MapEntry(3, 'Qua'),
                        MapEntry(4, 'Qui'),
                        MapEntry(5, 'Sex'),
                        MapEntry(6, 'Sab'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(entry.value),
                            selected: _selectedFilterDays.contains(entry.key),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            selectedColor: _brandOrangeSoft,
                            checkmarkColor: _brandOrangeDark,
                            labelStyle: TextStyle(
                              color: _selectedFilterDays.contains(entry.key)
                                  ? _brandOrangeDark
                                  : _textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: _selectedFilterDays.contains(entry.key)
                                  ? const Color(0xFFFFD8A8)
                                  : const Color(0xFFE2E8F0),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFilterDays.add(entry.key);
                                } else {
                                  _selectedFilterDays.remove(entry.key);
                                }
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filteredProducts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyState(
              icon: Icons.search_off_rounded,
              title: 'Nenhum produto encontrado',
              subtitle: 'Ajuste a busca ou limpe os filtros para ver mais itens.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final prod = filteredProducts[index];
                  return _productAdminCard(prod, categories);
                },
                childCount: filteredProducts.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: false,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.createCategory(Category(
            id: '',
            name: name,
            description: desc,
            imageUrl: imageUrl,
          ));
        },
      ),
    );
  }

  void _showSubcategoryDialog(BuildContext context, String catId) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: true,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.createSubcategory(SubCategory(
            id: '',
            categoryId: catId,
            name: name,
            description: desc,
            imageUrl: imageUrl,
          ));
        },
      ),
    );
  }

  void _editCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: false,
        initialName: cat.name,
        initialDesc: cat.description,
        initialImageUrl: cat.imageUrl,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.updateCategory(cat.id, Category(
            id: cat.id,
            name: name,
            description: desc,
            imageUrl: imageUrl ?? cat.imageUrl,
          ));
        },
      ),
    );
  }

  void _confirmDeleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Deseja excluir a categoria "${cat.name}"? TUDO associado a ela pode sumir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteCategory(cat.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editSubcategory(String catId, SubCategory sub) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: true,
        initialName: sub.name,
        initialDesc: sub.description,
        initialImageUrl: sub.imageUrl,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.updateSubcategory(sub.id, SubCategory(
            id: sub.id,
            categoryId: catId,
            name: name,
            description: desc,
            imageUrl: imageUrl ?? sub.imageUrl,
          ));
        },
      ),
    );
  }

  void _confirmDeleteSubcategory(SubCategory sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Subcategoria'),
        content: Text('Deseja excluir a subcategoria "${sub.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteSubcategory(sub.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crie uma categoria primeiro.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _ProductModal(categories: categories),
    );
  }

  void _editProduct(
      BuildContext context, Product product, List<Category> categories) {
    if (categories.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => _ProductModal(categories: categories, product: product),
    );
  }

  void _confirmDeleteProduct(Product prod) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Excluir Produto?'),
              content: Text('Tem certeza que deseja excluir "${prod.name}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context.read<AdminProvider>().deleteProduct(prod.id);
                  },
                  child: const Text('Excluir',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }
}

class _ProductModal extends StatefulWidget {
  final List<Category> categories;
  final Product? product;

  const _ProductModal({required this.categories, this.product});

  @override
  State<_ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<_ProductModal> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingrCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  bool _isUploading = false;
  bool _isGeneratingImage = false;
  bool _isGeneratingDescription = false;

  List<Map<String, dynamic>> _selectedImages = []; // store bytes and name
  final Map<int, bool> _availableDays = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false
  };

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _ingrCtrl.text = p.ingredients;
      _priceCtrl.text = p.price.toStringAsFixed(2).replaceAll('.', ',');
      _costPriceCtrl.text = p.costPrice.toStringAsFixed(2).replaceAll('.', ',');
      _stockCtrl.text = p.stockQuantity.toString();
      _selectedCategoryId = p.categoryId;
      _selectedSubcategoryId = p.subcategoryId;
      _availableDays.addAll(p.availableDays);
      _selectedImages =
          p.images.map<Map<String, dynamic>>((url) => {'url': '$url?v=${DateTime.now().millisecondsSinceEpoch}'}).toList();
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo de 5 imagens permitido.')));
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        for (var image in picked) {
          if (_selectedImages.length >= 5) break;
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImages.add({'bytes': bytes, 'name': image.name});
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao abrir galeria: $e');
    }
  }

  String? _currentCategoryName() {
    if (_selectedCategoryId == null) return null;

    for (final category in widget.categories) {
      if (category.id == _selectedCategoryId) {
        return category.name;
      }
    }

    return null;
  }

  String? _currentSubcategoryName() {
    if (_selectedCategoryId == null || _selectedSubcategoryId == null) {
      return null;
    }

    for (final category in widget.categories) {
      if (category.id != _selectedCategoryId) continue;
      for (final subcategory in category.subcategories) {
        if (subcategory.id == _selectedSubcategoryId) {
          return subcategory.name;
        }
      }
    }

    return null;
  }

  void _showAiMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _generateProductDescription() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showAiMessage('Informe o nome do produto para gerar a descricao.');
      return;
    }

    setState(() => _isGeneratingDescription = true);

    try {
      final description = await context.read<ApiService>().generateCatalogDescription(
            name: name,
            itemType: 'produto',
            categoryName: _currentCategoryName(),
            subcategoryName: _currentSubcategoryName(),
          );

      if (!mounted) return;
      setState(() => _descCtrl.text = description);
    } catch (e) {
      _showAiMessage(ApiService.friendlyErrorMessage(
        e,
        fallback: 'Nao foi possivel gerar a descricao agora.',
      ));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingDescription = false);
      }
    }
  }

  Future<void> _generateProductImage() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showAiMessage('Informe o nome do produto para gerar a imagem.');
      return;
    }

    if (_selectedImages.length >= 5) {
      _showAiMessage('Maximo de 5 imagens permitido.');
      return;
    }

    setState(() => _isGeneratingImage = true);

    try {
      final generatedImage = await context.read<ApiService>().generateCatalogImage(
            name: name,
            itemType: 'produto',
            categoryName: _currentCategoryName(),
            subcategoryName: _currentSubcategoryName(),
          );

      if (!mounted) return;
      setState(() {
        _selectedImages.add({
          'bytes': generatedImage.bytes,
          'name': generatedImage.fileName,
        });
      });
    } catch (e) {
      _showAiMessage(ApiService.friendlyErrorMessage(
        e,
        fallback: 'Nao foi possivel gerar a imagem agora.',
      ));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  Future<String?> _uploadSingleImageToCloudinary(
      Dio dio, Uint8List bytes, String name) async {
    try {
final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

      final ext = name.split('.').last.toLowerCase();
      final mimeType = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      var formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: name,
            contentType: MediaType('image', mimeType),
          ),
        });

        var response = await dio.post('$baseUrl/upload/image', data: formData);
        return response.data['url'];
      } catch (e) {
        if (e is DioException) {
          debugPrint('Erro upload image API: ${e.response?.data}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Erro no upload: ${e.response?.data?['message'] ?? e.response?.data ?? e.message}')));
          }
        } else {
          debugPrint('Erro upload single image: $e');
        }
        return null;
      }
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedCategoryId == null) return;

    setState(() => _isUploading = true);

    final dio = Dio();
    final StorageService storageService = StorageService();
    await storageService.init();
    final token = storageService.getToken();

    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';

    List<String> uploadedUrls = [];
    int uploadIndex = 0;

    for (var img in _selectedImages) {
      if (img.containsKey('url')) {
        uploadedUrls.add(img['url']);
      } else {
        final originalName = img['name'] ?? 'image.jpg';
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_${uploadIndex}_$originalName';
        final url =
            await _uploadSingleImageToCloudinary(dio, img['bytes'], uniqueName);
        if (url != null) uploadedUrls.add(url);
        uploadIndex++;
      }
    }

    final adminProvider = context.read<AdminProvider>();
    final newProduct = Product(
      id: widget.product?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      ingredients: _ingrCtrl.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId,
      images: uploadedUrls,
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      costPrice: double.tryParse(_costPriceCtrl.text.replaceAll(',', '.')) ?? 0.0,
        price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
      availableDays: _availableDays,
    );

    if (widget.product == null) {
      await adminProvider.createProduct(newProduct);
    } else {
      await adminProvider.updateProduct(widget.product!.id, newProduct);
    }

    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.pop(context);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _textDark),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(int dayIndex, String label) {
    final bool isSelected = _availableDays[dayIndex] ?? false;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool val) {
        setState(() {
          _availableDays[dayIndex] = val;
        });
      },
      selectedColor: _brandOrange.withOpacity(0.2),
      checkmarkColor: _brandOrange,
      labelStyle: TextStyle(
        color: isSelected ? _brandOrange : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Category? currentCategory;
    if (_selectedCategoryId != null) {
      currentCategory = widget.categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => widget.categories.first);
    }

    Widget panel({required String title, required IconData icon, required Widget child}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3E7D8)),
          boxShadow: [_softShadow(0.035)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _brandOrangeSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _brandOrangeDark, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: _creamBg,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 18, 20),
                  decoration: const BoxDecoration(gradient: _brandGradient),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Icon(
                          widget.product == null ? Icons.add_business_rounded : Icons.edit_note_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product == null ? 'Novo Produto' : 'Editar Produto',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Preencha os dados comerciais, fotos e disponibilidade.',
                              style: TextStyle(color: Color(0xFFFFF7ED), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isUploading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        panel(
                          title: 'Fotos do produto',
                          icon: Icons.photo_library_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Use imagens quadradas. Máximo de 5 fotos por produto.',
                                style: TextStyle(color: _mutedText, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ..._selectedImages.asMap().entries.map((e) {
                                    final imgMap = e.value;
                                    final isNetwork = imgMap.containsKey('url');

                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 88,
                                          height: 88,
                                          decoration: BoxDecoration(
                                            color: _creamBg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFEADFD2)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(9),
                                            child: isNetwork
                                                ? Image.network(imgMap['url'], fit: BoxFit.cover)
                                                : _buildImagePreview(imgMap['bytes'], fit: BoxFit.cover),
                                          ),
                                        ),
                                        Positioned(
                                          right: -7,
                                          top: -7,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _selectedImages.removeAt(e.key)),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: _dangerRed,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  if (_selectedImages.length < 5)
                                    GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 88,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFCF7),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: _brandOrangeDark, width: 1.2),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_rounded, color: _brandOrangeDark, size: 26),
                                            SizedBox(height: 5),
                                            Text('Adicionar', style: TextStyle(color: _brandOrangeDark, fontSize: 11, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // ajustar essa budega
                                  // if (_selectedImages.length < 5)
                                  //   _AiParticleButton(
                                  //     tooltip: 'Gerar imagem com IA',
                                  //     onPressed: _generateProductImage,
                                  //     isLoading: _isGeneratingImage,
                                  //   ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        panel(
                          title: 'Identificação',
                          icon: Icons.inventory_2_outlined,
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                decoration: _prettyInput(label: 'Nome do produto', icon: Icons.shopping_bag_outlined),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      isExpanded: true,
                                      decoration: _prettyInput(label: 'Categoria', icon: Icons.category_outlined),
                                      items: widget.categories
                                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCategoryId = val;
                                          _selectedSubcategoryId = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSubcategoryId,
                                      isExpanded: true,
                                      decoration: _prettyInput(label: 'Subcategoria', icon: Icons.account_tree_outlined),
                                      items: [
                                        const DropdownMenuItem(value: null, child: Text('Nenhuma', overflow: TextOverflow.ellipsis)),
                                        if (currentCategory != null)
                                          ...currentCategory.subcategories.map(
                                              (s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                                      ],
                                      onChanged: (val) => setState(() => _selectedSubcategoryId = val),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        panel(
                          title: 'Descrição e ingredientes',
                          icon: Icons.receipt_long_outlined,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Descricao curta',
                                      style: TextStyle(
                                        color: _textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _AiParticleButton(
                                    tooltip: 'Gerar descrição com IA',
                                    onPressed: _generateProductDescription,
                                    isLoading: _isGeneratingDescription,
                                    size: 42,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _descCtrl,
                                maxLines: 3,
                                decoration: _prettyInput(label: 'Descrição curta', icon: Icons.notes_rounded, alignLabelWithHint: true),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _ingrCtrl,
                                maxLines: 3,
                                decoration: _prettyInput(label: 'Ingredientes', icon: Icons.restaurant_menu_rounded, alignLabelWithHint: true),
                              ),
                            ],
                          ),
                        ),
                        panel(
                          title: 'Financeiro e estoque',
                          icon: Icons.payments_outlined,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _costPriceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: _prettyInput(label: 'Custo', prefixText: 'R\$ ', icon: Icons.trending_down_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _priceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: _prettyInput(label: 'Venda', prefixText: 'R\$ ', icon: Icons.sell_outlined),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _stockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _prettyInput(label: 'Estoque atual', icon: Icons.warehouse_outlined),
                              ),
                            ],
                          ),
                        ),
                        panel(
                          title: 'Disponibilidade',
                          icon: Icons.calendar_today_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecione os dias em que este item fica disponível no cardápio.',
                                style: TextStyle(color: _mutedText, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _dayChip(0, 'Dom'),
                                  _dayChip(1, 'Seg'),
                                  _dayChip(2, 'Ter'),
                                  _dayChip(3, 'Qua'),
                                  _dayChip(4, 'Qui'),
                                  _dayChip(5, 'Sex'),
                                  _dayChip(6, 'Sáb'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF3E7D8))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _mutedText,
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandOrangeDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _isUploading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_rounded),
                          label: const Text('Salvar produto', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
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

class _ImagePickerModal extends StatefulWidget {
  final bool isSubcategory;
  final String? initialName;
  final String? initialDesc;
  final String? initialImageUrl;
  final Future<void> Function(String name, String desc, String? imageUrl) onSave;

  const _ImagePickerModal({
    required this.isSubcategory,
    this.initialName,
    this.initialDesc,
    this.initialImageUrl,
    required this.onSave,
  });

  @override
  State<_ImagePickerModal> createState() => _ImagePickerModalState();
}

class _ImagePickerModalState extends State<_ImagePickerModal> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _existingImageUrl;
  bool _isUploading = false;
  bool _isGeneratingImage = false;
  bool _isGeneratingDescription = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialName ?? '';
    _descCtrl.text = widget.initialDesc ?? '';
    _existingImageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Erro ao abrir galeria: $e');
    }
  }

  void _showAiMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _itemTypeLabel => widget.isSubcategory ? 'subcategoria' : 'categoria';

  Future<void> _generateDescription() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showAiMessage('Informe o nome para gerar a descricao.');
      return;
    }

    setState(() => _isGeneratingDescription = true);

    try {
      final description = await context.read<ApiService>().generateCatalogDescription(
            name: name,
            itemType: _itemTypeLabel,
          );

      if (!mounted) return;
      setState(() => _descCtrl.text = description);
    } catch (e) {
      _showAiMessage(ApiService.friendlyErrorMessage(
        e,
        fallback: 'Nao foi possivel gerar a descricao agora.',
      ));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingDescription = false);
      }
    }
  }

  Future<void> _generateImage() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showAiMessage('Informe o nome para gerar a imagem.');
      return;
    }

    setState(() => _isGeneratingImage = true);

    try {
      final generatedImage = await context.read<ApiService>().generateCatalogImage(
            name: name,
            itemType: _itemTypeLabel,
          );

      if (!mounted) return;
      setState(() {
        _selectedImageBytes = generatedImage.bytes;
        _selectedImageName = generatedImage.fileName;
        _existingImageUrl = null;
      });
    } catch (e) {
      _showAiMessage(ApiService.friendlyErrorMessage(
        e,
        fallback: 'Nao foi possivel gerar a imagem agora.',
      ));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImageBytes == null) return null;
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final dio = Dio();

      final StorageService storageService = StorageService();
      await storageService.init();
      final token = storageService.getToken();

      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final name = _selectedImageName ?? 'image.jpg';
      final ext = name.split('.').last.toLowerCase();
      final mimeType = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      var formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _selectedImageBytes!,
          filename: name,
          contentType: MediaType('image', mimeType),
        ),
      });

      var response = await dio.post('$baseUrl/upload/image', data: formData);
      return response.data['url'];
    } catch (e) {
      if (e is DioException) {
        debugPrint('Erro API Cloudinary: ${e.response?.data}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erro no upload: ${e.response?.data?['message'] ?? e.response?.data ?? e.message}')));
        }
      } else {
        debugPrint('Erro no upload para a API: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no upload: $e')));
        }
      }
      return null;
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isUploading = true);

    String? imageUrl = _existingImageUrl;
    if (_selectedImageBytes != null) {
      imageUrl = await _uploadToCloudinary();
    }

    await widget.onSave(_nameCtrl.text.trim(), _descCtrl.text.trim(), imageUrl);

    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialName != null && widget.initialName!.isNotEmpty;
    final String title = isEditing
        ? (widget.isSubcategory ? 'Editar Subcategoria' : 'Editar Categoria')
        : (widget.isSubcategory ? 'Nova Subcategoria' : 'Nova Categoria');
    final String subtitle = widget.isSubcategory
        ? 'Organize melhor os produtos dentro da categoria principal.'
        : 'Crie grupos claros para deixar o cardápio mais fácil de navegar.';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: _creamBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 18, 20),
                  decoration: const BoxDecoration(gradient: _brandGradient),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Icon(
                          widget.isSubcategory ? Icons.account_tree_outlined : Icons.category_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(subtitle, style: const TextStyle(color: Color(0xFFFFF7ED), fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isUploading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF3E7D8)),
                            boxShadow: [_softShadow(0.035)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _brandOrangeSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.image_outlined, color: _brandOrangeDark, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Imagem principal',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async => await _pickImage(),
                                    child: Container(
                                      width: 116,
                                      height: 116,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFCF7),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _brandOrangeDark, width: 1.2),
                                      ),
                                      child: _selectedImageBytes != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(9),
                                              child: _buildImagePreview(_selectedImageBytes!, fit: BoxFit.cover),
                                            )
                                          : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(9),
                                                  child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                                                )
                                              : const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.add_photo_alternate_rounded, color: _brandOrangeDark, size: 34),
                                                    SizedBox(height: 7),
                                                    Text(
                                                      'Adicionar\nimagem',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: _brandOrangeDark, fontSize: 12, fontWeight: FontWeight.w800),
                                                    ),
                                                  ],
                                                ),
                                    ),
                                  ),
                                  // const SizedBox(width: 16),
                                  // _AiParticleButton(
                                  //   tooltip: 'Gerar imagem com IA',
                                  //   onPressed: _generateImage,
                                  //   isLoading: _isGeneratingImage,
                                  //   size: 116,
                                  // ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'Use uma imagem quadrada com boa iluminação. Ela aparece no cardápio e nos filtros.',
                                      style: TextStyle(color: _mutedText, fontSize: 13, height: 1.35),
                                    ),
                                  ),
                                ],
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
                            border: Border.all(color: const Color(0xFFF3E7D8)),
                            boxShadow: [_softShadow(0.035)],
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                decoration: _prettyInput(label: 'Nome', icon: Icons.label_outline),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Descriçao',
                                      style: TextStyle(
                                        color: _textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _AiParticleButton(
                                    tooltip: 'Gerar descricao com IA',
                                    onPressed: _generateDescription,
                                    isLoading: _isGeneratingDescription,
                                    size: 42,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _descCtrl,
                                maxLines: 3,
                                decoration: _prettyInput(
                                  label: 'Descrição',
                                  icon: Icons.description_outlined,
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF3E7D8))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _mutedText,
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandOrangeDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _isUploading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_rounded),
                          label: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
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
