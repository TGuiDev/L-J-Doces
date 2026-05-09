import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import '../providers/admin_provider.dart';
import 'qr_scanner_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  static const Color _primary = Color(0xFFFDA516);
  static const Color _dark = Color(0xFF111827);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);

  String _filterStatus = 'all';
  String _quickPeriod = 'all'; // 'all', 'today', 'yesterday', '7d', '30d', 'custom'
  String _sortBy = 'recent';
  DateTimeRange? _range;
  String? _loadedToken;
  late final AuthProvider _authProvider;
  bool _scanMode = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();

  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProvider = context.read<AuthProvider>();
      _authProvider.addListener(_onAuthChanged);
      _maybeLoadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadOrders();
  }

  void _maybeLoadOrders() {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (!authProvider.isAuthenticated || token == null) {
      return;
    }

    if (_loadedToken == token) {
      return;
    }

    _loadedToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ordersProvider = context.read<OrdersProvider>();
      final adminProvider = context.read<AdminProvider>();
      if (adminProvider.products.isEmpty) {
        adminProvider.fetchProducts();
      }
      ordersProvider.fetchAllOrders(token);
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _maybeLoadOrders();
  }

  @override
  void dispose() {
    try {
      _authProvider.removeListener(_onAuthChanged);
    } catch (_) {}
    _searchController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'delivered':
        return 'Entregue';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  double? _parseMoney(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  DateTimeRange? _quickRange() {
    final now = DateTime.now();
    switch (_quickPeriod) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case 'yesterday':
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        final end = DateTime(now.year, now.month, now.day).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case '7d':
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      case '30d':
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case 'custom':
        return _range;
      case 'all':
      default:
        return null;
    }
  }

  List<Order> _filteredOrders(List<Order> rawOrders) {
    var orders = List<Order>.from(rawOrders);

    if (_filterStatus != 'all') {
      orders = orders.where((o) => o.status.toLowerCase() == _filterStatus).toList();
    }

    final effectiveRange = _quickRange();
    if (effectiveRange != null) {
      orders = orders.where((o) {
        final created = o.createdAt;
        return created.isAfter(effectiveRange.start.subtract(const Duration(seconds: 1))) &&
            created.isBefore(effectiveRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    final minValue = _parseMoney(_minValueController.text);
    final maxValue = _parseMoney(_maxValueController.text);
    if (minValue != null) {
      orders = orders.where((o) => o.totalAmount >= minValue).toList();
    }
    if (maxValue != null) {
      orders = orders.where((o) => o.totalAmount <= maxValue).toList();
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      orders = orders.where((o) {
        final shortId = o.id.length >= 8 ? o.id.substring(0, 8).toLowerCase() : o.id.toLowerCase();
        final fullId = o.id.toLowerCase();
        final customerName = (o.customerName ?? '').toLowerCase();
        return shortId.contains(q) || fullId.contains(q) || customerName.contains(q);
      }).toList();
    }

    switch (_sortBy) {
      case 'oldest':
        orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest':
        orders.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'lowest':
        orders.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'recent':
      default:
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return orders;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && mounted) {
      setState(() {
        _range = picked;
        _quickPeriod = 'custom';
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = 'all';
      _quickPeriod = 'all';
      _sortBy = 'recent';
      _range = null;
      _searchController.clear();
      _minValueController.clear();
      _maxValueController.clear();
    });
  }

  String _money(num value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE1B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? Colors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _tryReadString(dynamic object, List<String> fields) {
    for (final field in fields) {
      try {
        dynamic value;
        switch (field) {
          case 'customerName':
            value = object.customerName;
            break;
          case 'customerPhone':
            value = object.customerPhone;
            break;
          case 'phone':
            value = object.phone;
            break;
          case 'customerEmail':
            value = object.customerEmail;
            break;
          case 'email':
            value = object.email;
            break;
          case 'paymentMethod':
            value = object.paymentMethod;
            break;
          case 'paymentStatus':
            value = object.paymentStatus;
            break;
          case 'deliveryType':
            value = object.deliveryType;
            break;
          case 'deliveryMethod':
            value = object.deliveryMethod;
            break;
          case 'address':
            value = object.address;
            break;
          case 'deliveryAddress':
            value = object.deliveryAddress;
            break;
          case 'notes':
            value = object.notes;
            break;
          case 'observation':
            value = object.observation;
            break;
          case 'customerObservation':
            value = object.customerObservation;
            break;
        }
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      } catch (_) {}
    }
    return null;
  }

  String _paymentLabel(String? value) {
    if (value == null || value.isEmpty) return 'Não informado';
    switch (value.toLowerCase()) {
      case 'pix':
        return 'Pix';
      case 'credit_card':
      case 'credit':
        return 'Cartão de crédito';
      case 'debit_card':
      case 'debit':
        return 'Cartão de débito';
      case 'cash':
      case 'money':
        return 'Dinheiro';
      default:
        return value;
    }
  }

  Future<void> _openScanner() async {
    setState(() {
      _scanMode = true;
    });

    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (scannedValue != null && scannedValue.isNotEmpty) {
      _applyScannedValue(scannedValue);
    }

    if (mounted) {
      setState(() {
        _scanMode = false;
      });
    }
  }

  void _applyScannedValue(String value) {
    final cleaned = value.trim();
    setState(() {
      _searchController.text = cleaned;
    });
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por pedido, cliente, telefone ou endereço',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _primary, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Scanner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', 'all'),
                _filterChip('Pendentes', 'pending'),
                _filterChip('Confirmados', 'confirmed'),
                _filterChip('Entregues', 'delivered'),
                _filterChip('Cancelados', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _periodChip('Tudo', 'all'),
                      _periodChip('Hoje', 'today'),
                      _periodChip('Ontem', 'yesterday'),
                      _periodChip('7 dias', '7d'),
                      _periodChip('30 dias', '30d'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Período'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dark,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          if (_quickPeriod == 'custom' && _range != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.event_available, size: 18, color: _primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${_date(_range!.start)} até ${_date(_range!.end)}')),
                  InkWell(
                    onTap: () => setState(() {
                      _range = null;
                      _quickPeriod = 'all';
                    }),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                icon: Icon(_showAdvancedFilters ? Icons.expand_less : Icons.tune),
                label: Text(_showAdvancedFilters ? 'Ocultar filtros avançados' : 'Filtros avançados'),
                style: TextButton.styleFrom(foregroundColor: _primary),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar'),
                style: TextButton.styleFrom(foregroundColor: _muted),
              ),
            ],
          ),
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _compactInput('Valor mín.', 'R\$'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _compactInput('Valor máx.', 'R\$'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: _compactInput('Ordenar por', null),
              items: const [
                DropdownMenuItem(value: 'recent', child: Text('Mais recentes primeiro')),
                DropdownMenuItem(value: 'oldest', child: Text('Mais antigas primeiro')),
                DropdownMenuItem(value: 'highest', child: Text('Maior valor primeiro')),
                DropdownMenuItem(value: 'lowest', child: Text('Menor valor primeiro')),
              ],
              onChanged: (value) => setState(() => _sortBy = value ?? 'recent'),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _compactInput(String label, String? prefix) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix == null ? null : '$prefix ',
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: _primary,
        backgroundColor: _surface,
        labelStyle: TextStyle(color: selected ? Colors.white : _dark, fontWeight: FontWeight.w600),
        side: BorderSide(color: selected ? _primary : const Color(0xFFE2E8F0)),
        onSelected: (_) => setState(() => _filterStatus = value),
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _quickPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFFFFF0D1),
        backgroundColor: _surface,
        labelStyle: TextStyle(color: selected ? _primary : _dark, fontWeight: FontWeight.w600),
        side: BorderSide(color: selected ? _primary : const Color(0xFFE2E8F0)),
        onSelected: (_) => setState(() {
          _quickPeriod = value;
          if (value != 'custom') _range = null;
        }),
      ),
    );
  }

  Widget _buildSummary(List<Order> orders) {
    final total = orders.fold<num>(0, (sum, o) => sum + o.totalAmount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _metricCard('Pedidos filtrados', orders.length.toString(), Icons.receipt_long, _primary),
          const SizedBox(width: 10),
          _metricCard('Faturamento', _money(total), Icons.payments_outlined, Colors.green),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text('Gerenciar Pedidos', style: TextStyle(color: _dark, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                if (ordersProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredOrders = _filteredOrders(ordersProvider.orders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                            child: const Icon(Icons.search_off, size: 42, color: _muted),
                          ),
                          const SizedBox(height: 16),
                          const Text('Nenhum pedido encontrado', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
                          const SizedBox(height: 6),
                          const Text('Tente ajustar a busca, o período, o status ou os valores.', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
                          const SizedBox(height: 12),
                          TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.refresh), label: const Text('Limpar filtros')),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildSummary(filteredOrders),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) => _buildOrderCard(context, filteredOrders[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final adminProvider = context.read<AdminProvider>();
    final status = order.status.toLowerCase();
    final hasActions = status != 'delivered' && status != 'cancelled';
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    final customerName =
        _tryReadString(order, ['customerName']) ?? 'Cliente não informado';
    final customerPhone = _tryReadString(order, ['customerPhone', 'phone']);
    final customerEmail = _tryReadString(order, ['customerEmail', 'email']);
    final paymentMethod = _tryReadString(order, ['paymentMethod']);
    final paymentStatus = _tryReadString(order, ['paymentStatus']);
    final deliveryType =
        _tryReadString(order, ['deliveryType', 'deliveryMethod']);
    final deliveryAddress =
        _tryReadString(order, ['deliveryAddress', 'address']);
    final observation =
        _tryReadString(order, ['notes', 'observation', 'customerObservation']);
    final totalItems =
        order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFFFE3BF)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          childrenPadding: EdgeInsets.zero,
          iconColor: Colors.orange,
          collapsedIconColor: Colors.orange,
          title: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #$shortId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_money(order.totalAmount)} • $totalItems item${totalItems == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getStatusLabel(order.status),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200, height: 24),
                  _sectionTitle('Resumo do pedido', Icons.dashboard_outlined),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth > 520;
                      final children = [
                        _infoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Data do pedido',
                          value: _formatDateTime(order.createdAt),
                        ),
                        _infoTile(
                          icon: Icons.payments_outlined,
                          label: 'Pagamento',
                          value: _paymentLabel(paymentMethod),
                        ),
                        _infoTile(
                          icon: Icons.verified_outlined,
                          label: 'Status do pagamento',
                          value: paymentStatus ?? 'Não informado',
                        ),
                        _infoTile(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Quantidade de itens',
                          value:
                              '$totalItems item${totalItems == 1 ? '' : 's'}',
                        ),
                      ];

                      if (!twoColumns) {
                        return Column(
                          children: children
                              .map((child) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: child,
                                  ))
                              .toList(),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: children
                            .map((child) => SizedBox(
                                  width: (constraints.maxWidth - 8) / 2,
                                  child: child,
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle(
                      'Cliente e entrega', Icons.person_pin_circle_outlined),
                  _infoTile(
                    icon: Icons.person_outline,
                    label: 'Cliente',
                    value: customerName,
                  ),
                  if (customerPhone != null) ...[
                    const SizedBox(height: 8),
                    _infoTile(
                      icon: Icons.phone_outlined,
                      label: 'Telefone',
                      value: customerPhone,
                    ),
                  ],
                  if (customerEmail != null) ...[
                    const SizedBox(height: 8),
                    _infoTile(
                      icon: Icons.email_outlined,
                      label: 'E-mail',
                      value: customerEmail,
                    ),
                  ],
                  if (deliveryType != null || deliveryAddress != null) ...[
                    const SizedBox(height: 8),
                    _infoTile(
                      icon: Icons.local_shipping_outlined,
                      label:
                          deliveryType != null ? 'Tipo de entrega' : 'Endereço',
                      value: deliveryType ?? deliveryAddress!,
                    ),
                  ],
                  if (deliveryAddress != null && deliveryType != null) ...[
                    const SizedBox(height: 8),
                    _infoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Endereço',
                      value: deliveryAddress,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _sectionTitle('Itens do pedido', Icons.inventory_2_outlined),
                  ...order.items.map((item) {
                    String productName = 'Produto';
                    try {
                      final prod = adminProvider.products
                          .firstWhere((p) => p.id == item.productId);
                      productName = prod.name;
                    } catch (_) {
                      productName = 'Produto não encontrado';
                    }

                    final subtotal = item.quantity * item.unitPrice;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Unitário: ${_money(item.unitPrice)}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(subtotal),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total do pedido',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatMoney(order.totalAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (observation != null) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Observação', Icons.sticky_note_2_outlined),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFECB3)),
                      ),
                      child: Text(
                        observation,
                        style: const TextStyle(
                          color: Color(0xFF6B4E00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (hasActions) ...[
                    const SizedBox(height: 18),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    _sectionTitle('Ações', Icons.tune_outlined),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateOrderStatus(order.id, 'delivered'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Entregar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _updateOrderStatus(order.id, 'cancelled'),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    final authProvider = context.read<AuthProvider>();
    final ordersProvider = context.read<OrdersProvider>();

    if (authProvider.token == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Ação'),
        content: Text('Alterar status para ${_getStatusLabel(newStatus)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final updatedOrder = await ordersProvider.updateOrderStatus(
                  authProvider.token!,
                  orderId,
                  newStatus,
                );

                if (updatedOrder != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Status atualizado com sucesso!')),
                  );
                  setState(() {});
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${ordersProvider.error}')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar status: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
