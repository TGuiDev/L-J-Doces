import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget para exibir imagens de perfil com cache otimizado
/// Trata erros de rate limit (429) e oferece fallback gracioso
class ProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.radius = 60,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final isSvg = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        (imageUrl!.toLowerCase().contains('.svg') || imageUrl!.toLowerCase().contains('/svg?'));

    Widget imageWidget;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (isSvg) {
        imageWidget = SvgPicture.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        // Headers para melhor cache e evitar rate limits
        httpHeaders: const {
          'Cache-Control': 'max-age=2592000', // 30 dias
          'Accept': 'image/*',
          'Connection': 'keep-alive',
        },
        placeholder: (context, url) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorWidget: (context, url, error) {
          debugPrint('[ProfileImageWidget] Erro ao carregar imagem: $url, Error: $error');
          // Fallback para erro de rede/rate limit (429)
          return Container(
            color: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: radius * 0.8,
              color: Colors.grey[600],
            ),
          );
        },
        // Configurar retry em caso de erro
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
      );
      }
    } else {
      imageWidget = Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius * 0.8,
          color: Colors.grey[600],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
        padding: padding ?? EdgeInsets.zero,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[100],
          child: ClipOval(
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}
