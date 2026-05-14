import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_sync_provider.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum DeliveryType { pickup, delivery }

enum PaymentMethod { pix, card, cash }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _districtController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isProcessing = false;
  DeliveryType _deliveryType = DeliveryType.pickup;
  PaymentMethod _paymentMethod = PaymentMethod.pix;

  double get _deliveryFee {
    if (_deliveryType == DeliveryType.delivery) return 8.00;
    return 0.00;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final cartProvider = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final authProvider = context.read<AuthProvider>();
    final stockSyncProvider = context.read<StockSyncProvider>();

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua sacola está vazia.')),
      );
      return;
    }

    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para fazer um pedido.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      for (final item in cartProvider.items.values) {
        final cachedStock =
            stockSyncProvider.getProductStock(item.product.id) ??
                item.product.stockQuantity;

        if (item.quantity > cachedStock) {
          throw Exception(
            'O item ${item.product.name} excede o estoque disponível. Disponível: $cachedStock',
          );
        }
      }

      final items = cartProvider.items.values.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'observation': item.observation,
        };
      }).toList();

      final totalWithDelivery = cartProvider.totalPrice + _deliveryFee;

      final order = await ordersProvider.createOrder(
        authProvider.token!,
        items,
        totalWithDelivery,
      );

      if (order != null) {
        final paidOrder = await ordersProvider.simulatePayment(
          authProvider.token!,
          order.id,
        );

        if (paidOrder != null && mounted) {
          for (final item in cartProvider.items.values) {
            final currentStock =
                stockSyncProvider.getProductStock(item.product.id) ??
                    item.product.stockQuantity;

            final nextStock = currentStock - item.quantity;

            stockSyncProvider.updateProductStock(
              item.product.id,
              nextStock > 0 ? nextStock : 0,
            );
          }

          cartProvider.clear();

          _showPaymentReceipt(paidOrder);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.friendlyErrorMessage(
                e,
                fallback: 'Nao foi possivel finalizar o pedido.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentReceipt(Order order) {
    final payment = order.payment;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF16A34A),
                        Color(0xFF22C55E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pedido confirmado!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pagamento simulado aprovado com sucesso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      _ReceiptBox(
                        children: [
                          _buildReceiptInfo(
                            'Pedido',
                            order.id.length >= 8
                                ? '#${order.id.substring(0, 8).toUpperCase()}'
                                : '#${order.id.toUpperCase()}',
                          ),
                          _buildReceiptInfo(
                            'Comprovante',
                            payment?.receiptNumber ?? 'N/A',
                          ),
                          _buildReceiptInfo(
                            'Status',
                            order.status.toUpperCase(),
                          ),
                          _buildReceiptInfo(
                            'Total',
                            'R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                          ),
                          _buildReceiptInfo(
                            'Entrega',
                            _deliveryType == DeliveryType.delivery
                                ? 'Delivery'
                                : 'Retirada',
                          ),
                          _buildReceiptInfo(
                            'Pagamento',
                            _paymentMethodLabel(_paymentMethod),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFFFF7A00),
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Você pode acompanhar tudo em “Minhas Compras”.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.28),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: const Text(
                            'Continuar',
                            style: TextStyle(
                              color: Color(0xFF1F1F1F),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/orders');
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: const Text(
                            'Ver pedidos',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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

  Widget _buildReceiptInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.pix:
        return 'PIX simulado';
      case PaymentMethod.card:
        return 'Cartão simulado';
      case PaymentMethod.cash:
        return 'Dinheiro na retirada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    final subtotal = cartProvider.totalPrice;
    final total = subtotal + _deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFFFFFFF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      bottomNavigationBar: _CheckoutBottomBar(
        subtotal: subtotal,
        deliveryFee: _deliveryFee,
        total: total,
        isProcessing: _isProcessing,
        onConfirm: _processPayment,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            _CheckoutProgress(),
            const SizedBox(height: 18),
            _CheckoutSection(
              title: 'Resumo do pedido',
              icon: Icons.shopping_bag_outlined,
              child: Column(
                children: [
                  ...cartProvider.items.values.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              item.product.images.isNotEmpty
                                  ? item.product.images.first
                                  : 'assets/images/app_icon.png',
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  width: 58,
                                  height: 58,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.product.name}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                  ),
                                ),
                                if (item.observation.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Obs: ${item.observation}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'R\$ ${(item.quantity * item.product.price).toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE86F00),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CheckoutSection(
              title: 'Forma de pagamento',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFFF7A00),
                          size: 21,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pagamento simulado para testes. Nenhuma cobrança real será feita.',
                            style: TextStyle(
                              color: Color(0xFFE86F00),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OptionTile(
                    selected: _paymentMethod == PaymentMethod.pix,
                    icon: Icons.qr_code_rounded,
                    title: 'PIX',
                    subtitle: 'Confirmação simulada imediata',
                    onTap: () {
                      setState(() {
                        _paymentMethod = PaymentMethod.pix;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    selected: _paymentMethod == PaymentMethod.card,
                    icon: Icons.credit_card_rounded,
                    title: 'Cartão',
                    subtitle: 'Cartão de teste simulado',
                    onTap: () {
                      setState(() {
                        _paymentMethod = PaymentMethod.card;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    selected: _paymentMethod == PaymentMethod.cash,
                    icon: Icons.payments_rounded,
                    title: 'Dinheiro',
                    subtitle: _deliveryType == DeliveryType.delivery
                        ? 'Pagamento na entrega'
                        : 'Pagamento na retirada',
                    onTap: () {
                      setState(() {
                        _paymentMethod = PaymentMethod.cash;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CheckoutSection(
              title: 'Observações',
              icon: Icons.edit_note_rounded,
              child: _InputField(
                controller: _notesController,
                label: 'Alguma observação para o pedido?',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          _ProgressStep(
            active: true,
            icon: Icons.shopping_bag_outlined,
            label: 'Sacola',
          ),
          _ProgressLine(active: true),
          _ProgressStep(
            active: true,
            icon: Icons.receipt_long_outlined,
            label: 'Dados',
          ),
          _ProgressLine(active: false),
          _ProgressStep(
            active: false,
            icon: Icons.check_circle_outline_rounded,
            label: 'Finalizar',
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;

  const _ProgressStep({
    required this.active,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF7A00) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? const Color(0xFFFF7A00) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final bool active;

  const _ProgressLine({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 21),
      color: active ? const Color(0xFFFF7A00) : Colors.grey[300],
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CheckoutSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFFF7A00),
                size: 22,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F1F1F),
                  ),
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
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E8) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFFF7A00) : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF7A00) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.black45,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: Color(0xFFE86F00),
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? const Color(0xFFFF7A00) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFFF7A00),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final bool isProcessing;
  final VoidCallback onConfirm;

  const _CheckoutBottomBar({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.isProcessing,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: 'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            const SizedBox(height: 7),
            _SummaryRow(
              label: 'Entrega',
              value: deliveryFee == 0
                  ? 'Grátis'
                  : 'R\$ ${deliveryFee.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: Color(0xFFE86F00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  disabledBackgroundColor: Colors.orange.withOpacity(0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Finalizar Pedido',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReceiptBox extends StatelessWidget {
  final List<Widget> children;

  const _ReceiptBox({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
