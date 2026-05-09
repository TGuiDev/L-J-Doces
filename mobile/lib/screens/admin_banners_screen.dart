import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchBanners();
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    final dio = Dio();
    final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000');
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      // ignore: use_build_context_synchronously
      dio.options.headers['Authorization'] = 'Bearer ${context.read<AuthProvider>().token}';

      final response = await dio.post(
        '$baseUrl/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Erro no upload: $e');
      return null;
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      // ignore: use_build_context_synchronously
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Não autenticado');

      final imageUrl = await _uploadImage(File(image.path));
      if (imageUrl != null) {
      // ignore: use_build_context_synchronously
        final success = await context.read<AdminProvider>().createBanner(token, imageUrl, true);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner adicionado com sucesso!')),
          );
        }
      } else {
        throw Exception('Falha ao enviar arquivo');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gerenciar Banners', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadBanner,
        backgroundColor: Colors.orange[800],
        icon: _isUploading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate),
        label: Text(_isUploading ? 'Enviando...' : 'Novo Banner'),
      ),
      body: adminProvider.isLoading && adminProvider.banners.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.banners.isEmpty
              ? const Center(
                  child: Text('Nenhum banner cadastrado.\nFaça o upload do primeiro!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: adminProvider.banners.length,
                  itemBuilder: (context, index) {
                    final banner = adminProvider.banners[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Column(
                        children: [
                          Image.network(
                            banner.imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      banner.active ? Icons.check_circle : Icons.cancel,
                                      color: banner.active ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      banner.active ? 'Ativo' : 'Inativo',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover Banner'),
                                        content: const Text('Tem certeza que deseja apagar este banner?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (authProvider.token != null) {
                                                adminProvider.deleteBanner(authProvider.token!, banner.id);
                                              }
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Remover', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
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
