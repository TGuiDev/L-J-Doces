import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import '../providers/admin_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrdersScreen extends StatefulWidget {
  final bool showBackButton;

  const OrdersScreen({Key? key, this.showBackButton = true}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _dateFilter = 'all'; // 'all', '24h', '7d', 'custom'
  DateTimeRange? _customDateRange;
  String? _loadedToken;
  // Mantém referência para remover o listener
  late final AuthProvider _authProvider;

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
      ordersProvider.fetchUserOrders(token);
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

  List<Order> _applyDateFilter(List<Order> orders) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case '24h':
        final cutoff = now.subtract(const Duration(hours: 24));
        return orders.where((o) => o.createdAt.isAfter(cutoff)).toList();
      case '7d':
        final cutoff = now.subtract(const Duration(days: 7));
        return orders.where((o) => o.createdAt.isAfter(cutoff)).toList();
      case 'custom':
        if (_customDateRange != null) {
          return orders
              .where((o) =>
                  o.createdAt.isAfter(_customDateRange!.start) &&
                  o.createdAt.isBefore(_customDateRange!.end.add(const Duration(days: 1))))
              .toList();
        }
        return orders;
      case 'all':
      default:
        return orders;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && mounted) {
      setState(() {
        _customDateRange = picked;
        _dateFilter = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Minhas Compras', style: TextStyle(color: Colors.black87)),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateFilterChip('Todos', 'all'),
                  _buildDateFilterChip('24h', '24h'),
                  _buildDateFilterChip('7 dias', '7d'),
                  _buildDateFilterChip('Customizado', 'custom'),
                  if (_dateFilter == 'custom' && _customDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text(
                          '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () {
                          setState(() {
                            _customDateRange = null;
                            _dateFilter = 'all';
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, child) {
          if (ordersProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (ordersProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${ordersProvider.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final token = context.read<AuthProvider>().token;
                      if (token != null) context.read<OrdersProvider>().fetchUserOrders(token);
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (ordersProvider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma compra realizada',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Aplicar filtro de data
          var orders = _applyDateFilter(ordersProvider.orders);

          if (orders.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma compra encontrada neste período',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _dateFilter == value,
        onSelected: (selected) {
          if (value == 'custom') {
            _selectDateRange();
          } else {
            setState(() {
              _dateFilter = value;
              _customDateRange = null;
            });
          }
        },
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: _dateFilter == value ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusLabel(order.status),
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                _buildOrderInfo(order),
                const SizedBox(height: 16),
                _buildOrderItems(order),
                const SizedBox(height: 16),
                _buildPaymentInfo(order),
                if (order.status.toLowerCase() == 'confirmed' ||
                    order.status.toLowerCase() == 'delivered')
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildQRCode(order),
                    ],
                  ),
                const SizedBox(height: 16),
                _buildOrderTracking(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações do Pedido',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Data:', _formatDate(order.createdAt)),
        _buildInfoRow('ID:', order.id.substring(0, 12).toUpperCase()),
        _buildInfoRow('Última Atualização:', _formatDate(order.updatedAt)),
      ],
    );
  }

  Widget _buildOrderItems(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Itens do Pedido',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...order.items.map((item) {
          String productName = 'Produto';
          try {
            final adminProvider = context.read<AdminProvider>();
            final prod = adminProvider.products.firstWhere((p) => p.id == item.productId);
            productName = prod.name;
          } catch (_) {
            productName = 'Produto';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${item.quantity}x $productName\nR\$ ${item.unitPrice.toStringAsFixed(2).replaceAll('.', ',')} (Subtotal: R\$ ${(item.quantity * item.unitPrice).toStringAsFixed(2).replaceAll('.', ',')})',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentInfo(Order order) {
    final payment = order.payment;
    if (payment == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações de Pagamento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Status:', _getStatusLabel(payment.status)),
        _buildInfoRow('Método:', payment.paymentMethod),
        if (payment.receiptNumber != null)
          _buildInfoRow('Comprovante:', payment.receiptNumber!),
        if (payment.transactionId != null)
          _buildInfoRow('Transação:', payment.transactionId!.substring(0, 16)),
        if (payment.paidAt != null)
          _buildInfoRow('Data do Pagamento:', _formatDate(payment.paidAt!)),
      ],
    );
  }

  Widget _buildQRCode(Order order) {
    return Center(
      child: Column(
        children: [
          const Text(
            'Código QR para Admin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: order.id,
                size: 200.0,
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Apresente este QR Code para o admin',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTracking(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico de Rastreamento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...order.tracking.asMap().entries.map((entry) {
          final track = entry.value;
          final isLast = entry.key == order.tracking.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(track.status),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusLabel(track.status),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        track.message,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDate(track.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
