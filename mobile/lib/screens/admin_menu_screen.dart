import 'package:flutter/material.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  static const Color _brandOrange = Color(0xFFFDA516);
  static const Color _brandOrangeDark = Color(0xFFF97316);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFFFFBF4);
  static const Color _card = Colors.white;
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [_brandOrange, _brandOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  BoxShadow _shadow([double opacity = 0.08]) => BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: 26,
        spreadRadius: -8,
        offset: const Offset(0, 14),
      );

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) {
    return InkWell(
      onTap: () {
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title em breve!')),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFE6BF)),
          boxShadow: [_shadow(0.05)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [_shadow(0.12)],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Text(
                    'Abrir painel',
                    style: TextStyle(
                      color: _brandOrangeDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: _brandOrangeDark),
                ],
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
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _brandGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Painel de Administração',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Atalhos rápidos para operação',
              style: TextStyle(
                color: Color(0xFFFFF7ED),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandOrange.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandOrangeDark.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              children: [
                // Container(
                //   padding: const EdgeInsets.all(18),
                //   decoration: BoxDecoration(
                //     gradient: _brandGradient,
                //     borderRadius: BorderRadius.circular(28),
                //     boxShadow: [_shadow(0.16)],
                //   ),
                //   child: Row(
                //     children: [
                //       Container(
                //         width: 56,
                //         height: 56,
                //         decoration: BoxDecoration(
                //           color: Colors.white.withOpacity(0.18),
                //           borderRadius: BorderRadius.circular(18),
                //           border: Border.all(color: Colors.white24),
                //         ),
                //         child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
                //       ),
                //       const SizedBox(width: 14),
                //       const Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Text(
                //               'Gestão centralizada',
                //               style: TextStyle(
                //                 color: Colors.white,
                //                 fontSize: 18,
                //                 fontWeight: FontWeight.w900,
                //                 letterSpacing: -0.2,
                //               ),
                //             ),
                //             SizedBox(height: 4),
                //             Text(
                //               'Acesse pedidos, produtos, vendas e análise em um fluxo mais claro e elegante.',
                //               style: TextStyle(
                //                 color: Color(0xFFFFF7ED),
                //                 fontSize: 12.5,
                //                 height: 1.35,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 18),
                const Text(
                  'Acessos rápidos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha a área que deseja administrar agora.',
                  style: TextStyle(color: _muted, height: 1.35),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.94,
                  children: [
                    _buildMenuCard(
                      context,
                      'Pedidos',
                      'Acompanhe e gerencie pedidos em tempo real.',
                      Icons.shopping_bag_outlined,
                      '/admin/orders',
                    ),
                    _buildMenuCard(
                      context,
                      'Produtos',
                      'Organize catálogo, categorias e imagens.',
                      Icons.inventory_2_outlined,
                      '/admin/products',
                    ),
                    _buildMenuCard(
                      context,
                      'Vendas',
                      'Veja o desempenho comercial com mais clareza.',
                      Icons.attach_money,
                      '/admin/sales',
                    ),
                    _buildMenuCard(
                      context,
                      'Resumo Operacional',
                      'Acesse indicadores e leitura geral do negócio.',
                      Icons.analytics_outlined,
                      '/admin/analytics',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
