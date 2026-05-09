import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../models/order_model.dart';
import '../providers/admin_provider.dart';

class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {
  static const Color _primary = Color(0xFFFDA516);
  static const Color _dark = Color(0xFF111827);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);

  String _statusFilter = 'all';
  String _quickPeriod = 'all';
  String _sortBy = 'recent';
  DateTimeRange? _range;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();

  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();
      if (adminProvider.products.isEmpty) {
        adminProvider.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
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

  String _shortId(String id) {
    return id.substring(0, id.length >= 8 ? 8 : id.length).toUpperCase();
  }

  String _money(num value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _dateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double? _parseMoney(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _readString(dynamic source, List<String> keys) {
    for (final key in keys) {
      try {
        final value = _readValue(source, key);
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      } catch (_) {}
    }
    return null;
  }

  dynamic _readValue(dynamic source, String key) {
    if (source == null) return null;
    if (source is Map) return source[key];
    try {
      switch (key) {
        case 'customerPhone':
          return source.customerPhone;
        case 'phone':
          return source.phone;
        case 'customerEmail':
          return source.customerEmail;
        case 'email':
          return source.email;
        case 'deliveryType':
          return source.deliveryType;
        case 'deliveryMethod':
          return source.deliveryMethod;
        case 'deliveryAddress':
          return source.deliveryAddress;
        case 'address':
          return source.address;
        case 'street':
          return source.street;
        case 'number':
          return source.number;
        case 'neighborhood':
          return source.neighborhood;
        case 'city':
          return source.city;
        case 'notes':
          return source.notes;
        case 'observation':
          return source.observation;
        case 'observations':
          return source.observations;
        case 'paymentMethod':
          return source.paymentMethod;
        case 'status':
          return source.status;
        case 'paidAt':
          return source.paidAt;
        case 'name':
          return source.name;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  String _orderSearchableText(Order order) {
    final pieces = <String>[
      order.id,
      _shortId(order.id),
      order.customerName ?? '',
      order.status,
      _getStatusLabel(order.status),
      _readString(order, ['customerPhone', 'phone']) ?? '',
      _readString(order, ['customerEmail', 'email']) ?? '',
      _readString(order, ['deliveryAddress', 'address', 'street']) ?? '',
      _readString(order, ['notes', 'observation', 'observations']) ?? '',
      order.payment?.paymentMethod ?? '',
      order.payment?.status ?? '',
    ];
    return pieces.join(' ').toLowerCase();
  }

  DateTimeRange? _quickRange() {
    final now = DateTime.now();
    switch (_quickPeriod) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case 'yesterday':
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
        final end = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case '7d':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
      case '30d':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now);
      case 'custom':
        return _range;
      case 'all':
      default:
        return null;
    }
  }

  List<Order> _filteredOrders(List<Order> rawOrders) {
    var orders = List<Order>.from(rawOrders);

    if (_statusFilter != 'all') {
      orders =
          orders.where((o) => o.status.toLowerCase() == _statusFilter).toList();
    }

    final effectiveRange = _quickRange();
    if (effectiveRange != null) {
      orders = orders.where((o) {
        final created = o.createdAt;
        return created.isAfter(
                effectiveRange.start.subtract(const Duration(seconds: 1))) &&
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
      final tokens =
          q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      orders = orders.where((o) {
        final searchable = _orderSearchableText(o);
        return tokens.every(searchable.contains);
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
      initialDateRange: _range ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
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
      _statusFilter = 'all';
      _quickPeriod = 'all';
      _sortBy = 'recent';
      _range = null;
      _searchController.clear();
      _minValueController.clear();
      _maxValueController.clear();
    });
  }

  int _countItems(Order order) {
    return order.items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  String _paymentLabel(Order order) {
    final method = order.payment?.paymentMethod ??
        _readString(order, ['paymentMethod']) ??
        'Não informado';
    final status = order.payment?.status ?? 'unknown';
    final paid =
        status.toLowerCase() == 'completed' || status.toLowerCase() == 'paid';
    return '$method • ${paid ? 'Pago' : 'Pendente'}';
  }

  String _deliveryLabel(Order order) {
    return _readString(order, ['deliveryType', 'deliveryMethod']) ??
        'Entrega/retirada não informada';
  }

  String _addressLabel(Order order) {
    final full = _readString(order, ['deliveryAddress', 'address']);
    if (full != null) return full;
    final parts = <String>[
      _readString(order, ['street']) ?? '',
      _readString(order, ['number']) ?? '',
      _readString(order, ['neighborhood']) ?? '',
      _readString(order, ['city']) ?? '',
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Endereço não informado' : parts.join(', ');
  }

  Map<String, num> _summary(List<Order> orders) {
    final total = orders.fold<num>(0, (sum, o) => sum + o.totalAmount);
    final delivered =
        orders.where((o) => o.status.toLowerCase() == 'delivered').length;
    final pending =
        orders.where((o) => o.status.toLowerCase() == 'pending').length;
    final ticket = orders.isEmpty ? 0 : total / orders.length;
    return {
      'total': total,
      'delivered': delivered,
      'pending': pending,
      'ticket': ticket
    };
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
            BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Buscar por pedido, cliente, telefone, endereço ou pagamento',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _searchController.clear()),
                    )
                  : null,
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todas', 'all'),
                _filterChip('Pendentes', 'pending'),
                _filterChip('Confirmadas', 'confirmed'),
                _filterChip('Entregues', 'delivered'),
                _filterChip('Canceladas', 'cancelled'),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          if (_quickPeriod == 'custom' && _range != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.event_available, size: 18, color: _primary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          '${_date(_range!.start)} até ${_date(_range!.end)}')),
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
                onPressed: () => setState(
                    () => _showAdvancedFilters = !_showAdvancedFilters),
                icon:
                    Icon(_showAdvancedFilters ? Icons.expand_less : Icons.tune),
                label: Text(_showAdvancedFilters
                    ? 'Ocultar filtros avançados'
                    : 'Filtros avançados'),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _compactInput('Valor mín.', 'R\$'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                DropdownMenuItem(
                    value: 'recent', child: Text('Mais recentes primeiro')),
                DropdownMenuItem(
                    value: 'oldest', child: Text('Mais antigas primeiro')),
                DropdownMenuItem(
                    value: 'highest', child: Text('Maior valor primeiro')),
                DropdownMenuItem(
                    value: 'lowest', child: Text('Menor valor primeiro')),
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
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: _primary,
        backgroundColor: _surface,
        labelStyle: TextStyle(
            color: selected ? Colors.white : _dark,
            fontWeight: FontWeight.w600),
        side: BorderSide(color: selected ? _primary : const Color(0xFFE2E8F0)),
        onSelected: (_) => setState(() => _statusFilter = value),
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
        labelStyle: TextStyle(
            color: selected ? _primary : _dark, fontWeight: FontWeight.w600),
        side: BorderSide(color: selected ? _primary : const Color(0xFFE2E8F0)),
        onSelected: (_) => setState(() {
          _quickPeriod = value;
          if (value != 'custom') _range = null;
        }),
      ),
    );
  }

  Widget _buildSummary(List<Order> orders) {
    final summary = _summary(orders);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _metricCard('Vendas filtradas', orders.length.toString(),
              Icons.receipt_long, _primary),
          const SizedBox(width: 10),
          _metricCard('Faturamento', _money(summary['total'] ?? 0),
              Icons.payments_outlined, Colors.green),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final itemsCount = _countItems(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showOrderDetailsDialog(context, order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: _primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Pedido #${_shortId(order.id)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: _dark)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(statusLabel,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(order.customerName ?? 'Cliente não informado',
                            style: const TextStyle(
                                color: _muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoPill(Icons.event, _dateTime(order.createdAt)),
                  _infoPill(Icons.inventory_2_outlined,
                      '$itemsCount item${itemsCount == 1 ? '' : 's'}'),
                  _infoPill(Icons.credit_card, _paymentLabel(order)),
                  _infoPill(
                      Icons.local_shipping_outlined, _deliveryLabel(order)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Total',
                      style: TextStyle(
                          color: _muted, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(_money(order.totalAmount),
                      style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _muted),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: _dark, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _productName(dynamic item, Map<String, dynamic> productsById) {
    try {
      final productMap = item.product;
      if (productMap is Map &&
          productMap['name'] != null &&
          productMap['name'].toString().trim().isNotEmpty) {
        return productMap['name'].toString();
      }
    } catch (_) {}
    final fallbackProduct = productsById[item.productId];
    try {
      if (fallbackProduct?.name != null &&
          fallbackProduct!.name.toString().trim().isNotEmpty) {
        return fallbackProduct.name;
      }
    } catch (_) {}
    return 'Produto sem nome';
  }

  void _showOrderDetailsDialog(BuildContext context, Order order) {
    final adminProvider = context.read<AdminProvider>();
    final productsById = {
      for (final product in adminProvider.products) product.id: product
    };
    final statusColor = _getStatusColor(order.status);
    final paidAt = order.payment?.paidAt;
    final notes = _readString(order, ['notes', 'observation', 'observations']);
    final customerPhone = _readString(order, ['customerPhone', 'phone']);
    final customerEmail = _readString(order, ['customerEmail', 'email']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
              maxWidth: 720),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: _dark,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child:
                          const Icon(Icons.receipt_long, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedido #${_shortId(order.id)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(
                              '${order.customerName ?? 'Cliente não informado'} • ${_dateTime(order.createdAt)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(_getStatusLabel(order.status),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _dialogMetric('Total', _money(order.totalAmount),
                              Icons.payments_outlined, _primary),
                          const SizedBox(width: 10),
                          _dialogMetric('Itens', _countItems(order).toString(),
                              Icons.inventory_2_outlined, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: 'Cliente',
                        icon: Icons.person_outline,
                        children: [
                          _detailRow(
                              'Nome', order.customerName ?? 'Não informado'),
                          _detailRow(
                              'Telefone', customerPhone ?? 'Não informado'),
                          _detailRow(
                              'E-mail', customerEmail ?? 'Não informado'),
                          _detailRow('ID completo', order.id),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Entrega ou retirada',
                        icon: Icons.local_shipping_outlined,
                        children: [
                          _detailRow('Modalidade', _deliveryLabel(order)),
                          _detailRow('Endereço', _addressLabel(order)),
                          if (notes != null) _detailRow('Observação', notes),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Pagamento',
                        icon: Icons.credit_card,
                        children: [
                          _detailRow(
                              'Método',
                              order.payment?.paymentMethod ??
                                  _readString(order, ['paymentMethod']) ??
                                  'Não informado'),
                          _detailRow(
                              'Status',
                              order.payment?.status == 'completed'
                                  ? 'Pago'
                                  : (order.payment?.status ?? 'Não informado')),
                          if (paidAt != null)
                            _detailRow('Pago em', _dateTime(paidAt)),
                          _detailRow('Valor total', _money(order.totalAmount),
                              emphasized: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Itens vendidos',
                        icon: Icons.shopping_basket_outlined,
                        children: [
                          ...order.items.map((item) {
                            final productName =
                                _productName(item, productsById);
                            final subtotal = item.unitPrice * item.quantity;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(productName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: _dark)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _miniTag('${item.quantity}x'),
                                      const SizedBox(width: 8),
                                      _miniTag('${_money(item.unitPrice)} un.'),
                                      const Spacer(),
                                      Text(_money(subtotal),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: _primary)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 20),
                          _detailRow(
                              'Subtotal dos itens', _money(order.totalAmount)),
                          _detailRow(
                              'Total do pedido', _money(order.totalAmount),
                              emphasized: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Fechar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _dark,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogMetric(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: _primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: _dark)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 118,
              child: Text(label,
                  style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: emphasized ? _primary : _dark,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                fontSize: emphasized ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: _dark, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 16,
                          width: 160,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Container(
                          height: 12,
                          width: 230,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8))),
                    ]),
              ),
              Container(
                  height: 26,
                  width: 78,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999))),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text('Vendas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, _) {
          if (ordersProvider.isLoading) {
            return Column(children: [
              _buildFilters(),
              Expanded(child: _buildLoadingList())
            ]);
          }

          final filteredOrders = _filteredOrders(ordersProvider.orders);

          return Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildFilters(),
                _buildSummary(filteredOrders),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.search_off,
                                    size: 42,
                                    color: _muted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhuma venda encontrada',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _dark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tente ajustar a busca, o período, o status ou os valores.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _muted),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Limpar filtros'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) =>
                              _buildOrderCard(context, filteredOrders[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
