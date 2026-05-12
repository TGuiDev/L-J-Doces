import 'package:flutter/material.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (route.isNotEmpty) {
            Navigator.pushNamed(context, route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title em breve!')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFFFDA516)), // Amarelo/laranja do projeto
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Cinza escuro
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6), // Fundo claro baseado no layout
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xffffffff)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Painel de Administração',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(context, 'Pedidos', Icons.shopping_bag_outlined, '/admin/orders'),
            _buildMenuCard(context, 'Produtos', Icons.inventory_2_outlined, '/admin/products'),
            // _buildMenuCard(context, 'Banners', Icons.view_carousel_outlined, '/admin/banners'),
            _buildMenuCard(context, 'Vendas', Icons.attach_money, '/admin/sales'),
            _buildMenuCard(context, 'Resumo Operacional', Icons.analytics_outlined, '/admin/analytics'),
          ],
        ),
      ),
    );
  }
}
