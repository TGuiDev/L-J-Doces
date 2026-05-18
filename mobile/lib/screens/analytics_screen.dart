// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/analytics_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  late DateTime startDate;
  late DateTime endDate;

  late TextEditingController startDateController;
  late TextEditingController endDateController;

  bool isLoading = false;
  String? error;
  OperationalSummary? summary;
  int selectedTab = 0; // 0: Summary, 1: Sales, 2: Products, 3: Profitability, 4: Payments, 5: Temporal

  // Função helper para converter valores seguramente para double e formatar

  String _formatPercent(dynamic value, {int decimals = 2}) {
    double numValue = 0;
    if (value is num) {
      numValue = value.toDouble();
    } else if (value is String) {
      numValue = double.tryParse(value) ?? 0;
    }
    return numValue.toStringAsFixed(decimals);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatCurrency(dynamic value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(
      _toDouble(value),
    );
  }

  String _formatCount(dynamic value) {
    return _toInt(value).toString();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Inicializar o apiService (Singleton)
    // Não criar nova instância - obter a existente do context quando possível
    endDate = DateTime.now();
    startDate = endDate.subtract(const Duration(days: 30));

    startDateController = TextEditingController(text: dateFormat.format(startDate));
    endDateController = TextEditingController(text: dateFormat.format(endDate));

    // Carregar análise automaticamente ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _generateSummary();
      }
    });
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: endDate,
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        startDateController.text = dateFormat.format(startDate);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        endDateController.text = dateFormat.format(endDate);
      });
    }
  }

  Future<void> _generateSummary() async {
    setState(() {
      isLoading = true;
      error = null;
      summary = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.getOperationalSummary(
        startDate: dateFormat.format(startDate),
        endDate: dateFormat.format(endDate),
        stream: true,
        onStreamUpdate: (partialSummary) {
          if (!mounted) return;

          setState(() {
            summary = partialSummary;
            selectedTab = 0;
          });
        },
      );

      setState(() {
        summary = result;
        isLoading = false;
        selectedTab = 0;
      });
    } catch (e) {
      final friendlyMessage = ApiService.friendlyErrorMessage(
        e,
        fallback: 'Não foi possível gerar o resumo. Tente novamente.',
      );
      setState(() {
        error = friendlyMessage;
        summary = null;
        isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Operacional'),
        elevation: 0,
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Date Range Selector
            Container(
              padding: const EdgeInsets.all(16),
              // ignore: deprecated_member_use
              color: Colors.orange.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período de Análise',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startDateController,
                          readOnly: true,
                          onTap: _selectStartDate,
                          decoration: InputDecoration(
                            hintText: 'Data Início',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endDateController,
                          readOnly: true,
                          onTap: _selectEndDate,
                          decoration: InputDecoration(
                            hintText: 'Data Fim',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _generateSummary,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isLoading ? 'Gerando...' : 'Gerar Resumo com IA',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else if (summary != null)
              Column(
                children: [
                  // Tab Navigation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabButton(0, '📋 Resumo'),
                          _buildTabButton(1, '💰 Vendas'),
                          _buildTabButton(2, '📦 Produtos'),
                          _buildTabButton(3, '📊 Lucro'),
                          _buildTabButton(4, '💳 Pagamentos'),
                          _buildTabButton(5, '⏰ Temporal'),
                        ],
                      ),
                    ),
                  ),
                  // Tab Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTabContent(),
                  ),
                ],
              )
            else if (!isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Clique em "Gerar Resumo com IA" para\nanalisar seus dados operacionais',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  Widget _buildTabButton(int index, String label) {
    final isActive = selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (selected) {
          setState(() {
            selectedTab = index;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.orangeAccent,
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (summary == null) {
      return const SizedBox.shrink();
    }

    switch (selectedTab) {
      case 0:
        return _buildSummaryTab();
      case 1:
        return _buildSalesTabCoherent();
      case 2:
        return _buildProductsTabCoherent();
      case 3:
        return _buildProfitabilityTabCoherent();
      case 4:
        return _buildPaymentsTabCoherent();
      case 5:
        return _buildTemporalTabCoherent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSummaryTab() {
    final usedAi = summary!.usedAi;
    final sourceLabel = switch (summary!.aiSource) {
      'gemini' => 'Resultado da IA: Gemini 2.5 Flash',
      'openai' => 'Resultado da IA: OpenAI',
      _ => 'Resultado da IA',
    };
    final statusColor = usedAi ? Colors.green : Colors.orange;
    final statusIcon = usedAi ? Icons.cloud_done : Icons.info_outline;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!usedAi && summary!.fallbackReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            summary!.fallbackReason!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                summary!.summary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSalesTab() {
    final sales = summary?.rawData['sales'] as Map<String, dynamic>?;

    if (sales == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text('Dados de vendas não disponíveis'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildMetricCard(
          'Total de Pedidos',
          '${sales['totalOrders'] ?? 0}',
          '📦',
          Colors.blue,
        ),
        _buildMetricCard(
          'Receita Total',
          'R\$ ${((sales['totalRevenue'] ?? 0) as num).toStringAsFixed(2)}',
          '💰',
          Colors.green,
        ),
        _buildMetricCard(
          'Ticket Médio',
          'R\$ ${((sales['averageOrderValue'] ?? 0) as num).toStringAsFixed(2)}',
          '📊',
          Colors.orange,
        ),
        const SizedBox(height: 16),
        const Text(
          'Status dos Pedidos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...(sales['ordersByStatus'] as Map<String, dynamic>? ?? {}).entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatOrderStatus(entry.key)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _formatOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendentes';
      case 'confirmed':
        return 'Confirmados';
      case 'delivered':
        return 'Entregues';
      case 'completed':
        return 'Concluidos';
      case 'cancelled':
      case 'canceled':
        return 'Cancelados';
      default:
        return status;
    }
  }

  // ignore: unused_element
  Widget _buildProductsTab() {
    final products = summary?.rawData['products'] as Map<String, dynamic>?;

    if (products == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text('Dados de produtos não disponíveis'),
            ],
          ),
        ),
      );
    }

    final topProducts = (products['topProducts'] as List?) ?? [];
    final lowStockProducts = (products['lowStockProducts'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 Top 10 Produtos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (topProducts.isEmpty)
          Text('Nenhum produto vendido', style: TextStyle(color: Colors.grey[600]))
        else
          ...topProducts.take(5).map<Widget>(
                (product) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (product as Map)['productName'] ?? 'Produto',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${product['quantity'] ?? 0} unidades',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ ${((product['revenue'] ?? 0) as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (product['profit'] != null)
                              Text(
                                'Lucro: R\$ ${(product['profit'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        const Text(
          '⚠️ Estoque Baixo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (lowStockProducts.isEmpty)
          Text(
            'Nenhum produto com estoque baixo',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          ...lowStockProducts.map<Widget>(
            (product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((product as Map)['name'] ?? 'Produto'),
                        Text(
                          'Estoque: ${product['stock_quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'R\$ ${((product['price'] ?? 0) as num).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildProfitabilityTab() {
    final profit = summary?.rawData['profitability'] as Map<String, dynamic>?;

    if (profit == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              const Text('Dados de lucratividade não disponíveis'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCard(
          'Receita Total',
          'R\$ ${((profit['totalRevenue'] ?? 0) as num).toStringAsFixed(2)}',
          '📈',
          Colors.green,
        ),
        _buildMetricCard(
          'Custo Total',
          'R\$ ${((profit['totalCost'] ?? 0) as num).toStringAsFixed(2)}',
          '📉',
          Colors.orange,
        ),
        _buildMetricCard(
          'Lucro Líquido',
          'R\$ ${((profit['profit'] ?? 0) as num).toStringAsFixed(2)}',
          ((profit['profit'] ?? 0) as num) < 0 ? '❌' : '✅',
          ((profit['profit'] ?? 0) as num) < 0 ? Colors.red : Colors.green,
        ),
        _buildMetricCard(
          'Margem de Lucro',
          '${_formatPercent(profit['marginPercentage'])}%',
          '📊',
          Colors.blue,
        ),
        const SizedBox(height: 16),
        if ((profit['negativeMarginProducts'] as List?) != null &&
            (profit['negativeMarginProducts'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Produtos com Prejuízo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...(profit['negativeMarginProducts'] as List).map<Widget>(
                (product) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prejuízo: R\$ ${(product['loss'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildPaymentsTab() {
    final payments = summary?.rawData['payments'] as Map<String, dynamic>?;

    if (payments == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              const Text('Dados de pagamentos não disponíveis'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildMetricCard(
          'Total de Pagamentos',
          'R\$ ${((payments['totalPayments'] ?? 0) as num).toStringAsFixed(2)}',
          '💳',
          Colors.blue,
        ),
        _buildMetricCard(
          'Pagamentos Confirmados',
          '${payments['completedPayments'] ?? 0}',
          '✅',
          Colors.green,
        ),
        _buildMetricCard(
          'Taxa de Conversão',
          '${_formatPercent(payments['paymentRate'])}%',
          '📊',
          Colors.orange,
        ),
        _buildMetricCard(
          'Valor Total',
          'R\$ ${((payments['totalCompletedAmount'] ?? 0) as num).toStringAsFixed(2)}',
          '💰',
          Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'Status dos Pagamentos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...((payments['paymentsByStatus'] as Map<String, dynamic>?) ?? {}).entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTemporalTab() {
    final temporal = summary?.rawData['temporal'] as Map<String, dynamic>?;

    if (temporal == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              const Text('Dados temporais não disponíveis'),
            ],
          ),
        ),
      );
    }

    final salesByDay = (temporal['salesByDayOfWeek'] as Map<String, dynamic>?) ?? {};
    final peakDay = temporal['peakDay'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vendas por Dia da Semana',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (salesByDay.isEmpty)
          Text('Nenhum dado disponível', style: TextStyle(color: Colors.grey[600]))
        else
          ...salesByDay.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Container(
                            width: ((entry.value ?? 0) as num).toDouble() *
                                (MediaQuery.of(context).size.width / 500),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${entry.value ?? 0}',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        const SizedBox(height: 16),
        const Text(
          'Dia com Maior Receita',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (peakDay != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (peakDay as List?)?[0] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  // ignore: unnecessary_cast
                  'R\$ ${(((peakDay as List?)?[1] ?? 0) as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Nenhum dia com destaque',
            style: TextStyle(color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildSalesTabCoherent() {
    final sales = summary?.rawData['sales'] as Map<String, dynamic>?;
    if (sales == null) {
      return _buildEmptyState('Dados de vendas nao disponiveis');
    }

    final statuses = (sales['ordersByStatus'] as Map<String, dynamic>?) ?? {};
    final totalOrders = _toInt(sales['totalOrders']);
    final delivered = _toInt(statuses['delivered']);
    final confirmed = _toInt(statuses['confirmed']);
    final pending = _toInt(statuses['pending']);
    final cancelled = _toInt(statuses['cancelled'] ?? statuses['canceled']);
    final activeOrders = delivered + confirmed;
    final cancellationRate =
        totalOrders > 0 ? (cancelled / totalOrders) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCard('Total de Pedidos', _formatCount(totalOrders), 'Qtd', Colors.blue),
        _buildMetricCard('Receita Total', _formatCurrency(sales['totalRevenue']), 'R\$', Colors.green),
        _buildMetricCard('Ticket Medio', _formatCurrency(sales['averageOrderValue']), 'TM', Colors.orange),
        _buildMetricCard('Confirmados + Entregues', _formatCount(activeOrders), 'OK', Colors.teal),
        _buildMetricCard(
          'Pendentes / Cancelados',
          '$pending / $cancelled',
          '${cancellationRate.toStringAsFixed(1)}%',
          cancelled > 0 ? Colors.red : Colors.green,
        ),
        _buildSectionTitle('Status dos Pedidos'),
        ...statuses.entries.map(
          (entry) => _buildSimpleRow(
            _formatOrderStatus(entry.key),
            _formatCount(entry.value),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTabCoherent() {
    final products = summary?.rawData['products'] as Map<String, dynamic>?;
    if (products == null) {
      return _buildEmptyState('Dados de produtos nao disponiveis');
    }

    final topProducts = (products['topProducts'] as List?) ?? [];
    final lowStockProducts = (products['lowStockProducts'] as List?) ?? [];
    final productsWithoutSales = (products['productsWithoutSales'] as List?) ?? [];
    final totalProducts = _toInt(products['totalProductsInCatalog']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCard('Produtos no Catalogo', _formatCount(totalProducts), 'SKU', Colors.blue),
        _buildMetricCard('Produtos Vendidos', _formatCount(topProducts.length), 'Giro', Colors.green),
        _buildMetricCard('Estoque Baixo', _formatCount(lowStockProducts.length), 'Crit', Colors.red),
        _buildMetricCard('Sem Venda no Periodo', _formatCount(productsWithoutSales.length), 'Parado', Colors.orange),
        _buildSectionTitle('Mais Vendidos'),
        if (topProducts.isEmpty)
          Text('Nenhum produto vendido no periodo.', style: TextStyle(color: Colors.grey[600]))
        else
          ...topProducts.take(10).map<Widget>((item) {
            final product = item as Map;
            final quantity = _toInt(product['quantity']);
            final stock = _toInt(product['currentStock'] ?? product['stock_quantity']);
            return _buildDataTile(
              product['productName']?.toString() ?? 'Produto',
              '${_formatCount(quantity)} unidade(s) vendida(s) • estoque atual: $stock',
              _formatCurrency(product['revenue']),
              Colors.green,
            );
          }),
        _buildSectionTitle('Estoque Baixo'),
        if (lowStockProducts.isEmpty)
          Text('Nenhum produto com estoque baixo.', style: TextStyle(color: Colors.grey[600]))
        else
          ...lowStockProducts.take(10).map<Widget>((item) {
            final product = item as Map;
            return _buildDataTile(
              product['name']?.toString() ?? 'Produto',
              'Estoque: ${_formatCount(product['stock_quantity'])}',
              _formatCurrency(product['price']),
              Colors.red,
            );
          }),
        _buildSectionTitle('Sem Venda no Periodo'),
        if (productsWithoutSales.isEmpty)
          Text('Nenhum produto parado identificado.', style: TextStyle(color: Colors.grey[600]))
        else
          ...productsWithoutSales.take(10).map<Widget>((item) {
            final product = item as Map;
            return _buildDataTile(
              product['name']?.toString() ?? 'Produto',
              'Estoque parado: ${_formatCount(product['stock_quantity'])}',
              _formatCurrency(product['price']),
              Colors.orange,
            );
          }),
      ],
    );
  }

  Widget _buildProfitabilityTabCoherent() {
    final profit = summary?.rawData['profitability'] as Map<String, dynamic>?;
    final sales = summary?.rawData['sales'] as Map<String, dynamic>?;
    if (profit == null) {
      return _buildEmptyState('Dados de lucratividade nao disponiveis');
    }

    final itemRevenue = _toDouble(profit['totalRevenue']);
    final salesRevenue = _toDouble(sales?['totalRevenue']);
    final difference = salesRevenue - itemRevenue;
    final hasMismatch = difference.abs() > 0.01;
    final negativeProducts = (profit['negativeMarginProducts'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCard('Receita por Itens', _formatCurrency(itemRevenue), 'Itens', Colors.green),
        _buildMetricCard('Custo Estimado', _formatCurrency(profit['totalCost']), 'Custo', Colors.orange),
        _buildMetricCard(
          'Lucro Estimado',
          _formatCurrency(profit['profit']),
          _toDouble(profit['profit']) < 0 ? 'Neg' : 'Pos',
          _toDouble(profit['profit']) < 0 ? Colors.red : Colors.green,
        ),
        _buildMetricCard('Margem Estimada', '${_formatPercent(profit['marginPercentage'])}%', 'Mg', Colors.blue),
        if (hasMismatch) ...[
          _buildSectionTitle('Conferencia dos Dados'),
          Text(
            'A receita de vendas (${_formatCurrency(salesRevenue)}) esta diferente da receita por itens (${_formatCurrency(itemRevenue)}). Confira se todos os pedidos possuem itens vinculados.',
            style: TextStyle(color: Colors.orange[800], height: 1.4),
          ),
        ],
        _buildSectionTitle('Produtos com Margem Negativa'),
        if (negativeProducts.isEmpty)
          Text('Nenhum produto com prejuizo identificado.', style: TextStyle(color: Colors.grey[600]))
        else
          ...negativeProducts.map<Widget>((item) {
            final product = item as Map;
            return _buildDataTile(
              product['name']?.toString() ?? 'Produto',
              'Receita: ${_formatCurrency(product['revenue'])} • custo: ${_formatCurrency(product['cost'])}',
              _formatCurrency(product['loss']),
              Colors.red,
            );
          }),
      ],
    );
  }

  Widget _buildPaymentsTabCoherent() {
    final payments = summary?.rawData['payments'] as Map<String, dynamic>?;
    if (payments == null) {
      return _buildEmptyState('Dados de pagamentos nao disponiveis');
    }

    final totalPayments = _toInt(payments['totalPayments']);
    final completedPayments = _toInt(payments['completedPayments']);
    final pendingPayments = totalPayments - completedPayments;
    final statusMap = (payments['paymentsByStatus'] as Map<String, dynamic>?) ?? {};
    final methodMap = (payments['paymentsByMethod'] as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricCard('Pagamentos Gerados', _formatCount(totalPayments), 'Qtd', Colors.blue),
        _buildMetricCard('Pagamentos Concluidos', _formatCount(completedPayments), 'OK', Colors.green),
        _buildMetricCard('Pagamentos Pendentes', _formatCount(pendingPayments), 'Pend', pendingPayments > 0 ? Colors.orange : Colors.green),
        _buildMetricCard('Taxa de Pagamento', '${_formatPercent(payments['paymentRate'])}%', 'Taxa', Colors.orange),
        _buildMetricCard('Valor Confirmado', _formatCurrency(payments['totalCompletedAmount']), 'R\$', Colors.green),
        _buildSectionTitle('Status dos Pagamentos'),
        ...statusMap.entries.map(
          (entry) => _buildSimpleRow(
            _formatPaymentStatus(entry.key),
            _formatCount(entry.value),
          ),
        ),
        _buildSectionTitle('Metodos de Pagamento'),
        ...methodMap.entries.map(
          (entry) => _buildSimpleRow(entry.key.toString(), _formatCount(entry.value)),
        ),
      ],
    );
  }

  Widget _buildTemporalTabCoherent() {
    final temporal = summary?.rawData['temporal'] as Map<String, dynamic>?;
    if (temporal == null) {
      return _buildEmptyState('Dados temporais nao disponiveis');
    }

    final salesByDay = (temporal['salesByDayOfWeek'] as Map<String, dynamic>?) ?? {};
    final revenueByDay = (temporal['revenueByDayOfWeek'] as Map<String, dynamic>?) ?? {};
    final salesByHour = (temporal['salesByHour'] as Map<String, dynamic>?) ?? {};
    final revenueByHour = (temporal['revenueByHour'] as Map<String, dynamic>?) ?? {};
    final peakDay = temporal['peakDay'] as List?;
    final topHours = salesByHour.entries.toList()
      ..sort((a, b) => _toDouble(b.value).compareTo(_toDouble(a.value)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (peakDay != null)
          _buildDataTile(
            'Dia com Maior Receita',
            peakDay[0]?.toString() ?? 'N/A',
            _formatCurrency(peakDay.length > 1 ? peakDay[1] : 0),
            Colors.orange,
          ),
        _buildSectionTitle('Pedidos por Dia da Semana'),
        _buildBarList(
          salesByDay,
          valueBuilder: (value) => '${_formatCount(value)} pedido(s)',
          color: Colors.blue,
        ),
        _buildSectionTitle('Receita por Dia da Semana'),
        _buildBarList(
          revenueByDay,
          valueBuilder: _formatCurrency,
          color: Colors.green,
        ),
        _buildSectionTitle('Horarios com Mais Pedidos'),
        ...topHours.take(6).map(
          (entry) => _buildSimpleRow(
            entry.key.toString(),
            '${_formatCount(entry.value)} pedido(s) • ${_formatCurrency(revenueByHour[entry.key])}',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDataTile(
    String title,
    String subtitle,
    String trailing,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.06),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBarList(
    Map<String, dynamic> values, {
    required String Function(dynamic value) valueBuilder,
    required Color color,
  }) {
    if (values.isEmpty) {
      return Text('Nenhum dado disponivel.', style: TextStyle(color: Colors.grey[600]));
    }

    final maxValue = values.values
        .map(_toDouble)
        .fold<double>(0, (max, value) => value > max ? value : max);

    return Column(
      children: values.entries.map((entry) {
        final value = _toDouble(entry.value);
        final factor = maxValue > 0 ? value / maxValue : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(width: 104, child: Text(entry.key, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: factor.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 86,
                child: Text(
                  valueBuilder(entry.value),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Concluidos';
      case 'pending':
        return 'Pendentes';
      case 'failed':
        return 'Falharam';
      case 'cancelled':
      case 'canceled':
        return 'Cancelados';
      default:
        return status;
    }
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
