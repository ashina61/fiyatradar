import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImage({
    required File file,
    required String folder,
    String? customName,
  }) async {
    try {
      final fileName = customName ?? '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child(folder).child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Resim yüklenirken hata oluştu: $e');
    }
  }

  Future<List<String>> uploadMultipleImages({
    required List<File> files,
    required String folder,
  }) async {
    final List<String> urls = [];

    for (final file in files) {
      final url = await uploadImage(file: file, folder: folder);
      urls.add(url);
    }

    return urls;
  }

  Future<String> uploadUserAvatar({
    required File file,
    required String userId,
  }) async {
    return await uploadImage(
      file: file,
      folder: 'avatars',
      customName: '$userId.jpg',
    );
  }

  Future<List<String>> uploadPriceImages({
    required List<File> files,
    required String priceId,
  }) async {
    return await uploadMultipleImages(
      files: files,
      folder: 'prices/$priceId',
    );
  }

  Future<String> uploadBannerImage({
    required File file,
    required String bannerId,
  }) async {
    return await uploadImage(
      file: file,
      folder: 'banners',
      customName: '$bannerId.jpg',
    );
  }

  Future<String> uploadProductImage({
    required File file,
    required String productId,
  }) async {
    return await uploadImage(
      file: file,
      folder: 'products/$productId',
    );
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Silme hatası görmezden gelinebilir
    }
  }

  Future<void> deleteFolder(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }

      for (final prefix in result.prefixes) {
        await deleteFolder(prefix.fullPath);
      }
    } catch (e) {
      // Klasör silme hatası görmezden gelinebilir
    }
  }
}
