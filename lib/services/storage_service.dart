import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  Future<String> uploadImage({
    required String bucket,
    required XFile imageFile,
    String? customFileName,
    bool isPublic = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String extension = _getFileExtension(imageFile);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 100000;
      final uniqueFileName =
          customFileName ?? '${user.id}_${timestamp}_$random.$extension';

      final bytes = await imageFile.readAsBytes();

      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('Image file too large. Maximum size is 10MB.');
      }

      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            uniqueFileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              cacheControl: '3600',
              contentType: _getMimeType(extension),
            ),
          );

      final String imageUrl;
      if (isPublic) {
        final baseUrl = _supabase.storage
            .from(bucket)
            .getPublicUrl(uniqueFileName);

        imageUrl = '$baseUrl?t=$timestamp';
      } else {
        final response = await _supabase.storage
            .from(bucket)
            .createSignedUrl(uniqueFileName, 60 * 60);
        imageUrl = response;
      }

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (e.toString().contains('The resource already exists')) {
        throw Exception('File with this name already exists');
      } else if (e.toString().contains('permissions')) {
        throw Exception('You don\'t have permission to upload to this bucket');
      } else if (e.toString().contains('size')) {
        throw Exception('File size too large');
      }
      rethrow;
    }
  }

  // NEW METHOD: Upload multiple images at once (from my version)
  Future<List<String>> uploadMultipleImages({
    required String bucket,
    required List<XFile> imageFiles,
    String? customFileNamePrefix,
    bool isPublic = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final List<String> uploadedUrls = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        String extension = _getFileExtension(imageFile);

        final random = DateTime.now().microsecondsSinceEpoch % 100000;
        final uniqueFileName = customFileNamePrefix != null
            ? '${customFileNamePrefix}_${timestamp}_${i}_$random.$extension'
            : '${user.id}_${timestamp}_${i}_$random.$extension';

        final bytes = await imageFile.readAsBytes();

        if (bytes.length > 10 * 1024 * 1024) {
          throw Exception('Image file too large. Maximum size is 10MB.');
        }

        await _supabase.storage
            .from(bucket)
            .uploadBinary(
              uniqueFileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                cacheControl: '3600',
                contentType: _getMimeType(extension),
              ),
            );

        final String imageUrl;
        if (isPublic) {
          final baseUrl = _supabase.storage
              .from(bucket)
              .getPublicUrl(uniqueFileName);

          imageUrl = '$baseUrl?t=$timestamp';
        } else {
          final response = await _supabase.storage
              .from(bucket)
              .createSignedUrl(uniqueFileName, 60 * 60);
          imageUrl = response;
        }

        uploadedUrls.add(imageUrl);
      }

      return uploadedUrls;
    } catch (e) {
      print('Error uploading multiple images: $e');
      rethrow;
    }
  }

  String _getFileExtension(XFile file) {
    try {
      final filePath = file.path;
      if (filePath.isNotEmpty) {
        final extension = path.extension(filePath).toLowerCase();
        if (extension.isNotEmpty && extension.length > 1) {
          return extension.substring(1);
        }
      }

      final name = file.name;
      if (name.contains('.')) {
        return name.split('.').last.toLowerCase();
      }

      final mimeType = file.mimeType?.toLowerCase() ?? '';
      if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return 'jpg';
      if (mimeType.contains('png')) return 'png';
      if (mimeType.contains('gif')) return 'gif';
      if (mimeType.contains('webp')) return 'webp';

      return 'jpg';
    } catch (e) {
      return 'jpg';
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg';
    }
  }

  // NEW METHOD: Pick multiple images from gallery (from my version)
  Future<List<XFile>?> pickMultipleImagesFromGallery({
    int maxWidth = 1920,
    int maxHeight = 1080,
    int imageQuality = 85,
    int maxImages = 10, // Limit number of images user can select
  }) async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      // Limit to maxImages if needed
      if (pickedFiles.length > maxImages) {
        return pickedFiles.sublist(0, maxImages);
      }

      return pickedFiles;
    } catch (e) {
      print('Error picking multiple images from gallery: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery({
    int maxWidth = 1920,
    int maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        requestFullMetadata: false,
      );
      return pickedFile;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera({
    int maxWidth = 1920,
    int maxHeight = 1080,
    int imageQuality = 85,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCamera,
      );
      return pickedFile;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  Future<void> deleteImage({
    required String bucket,
    required String fileName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (fileName.startsWith('${user.id}_')) {
        await _supabase.storage.from(bucket).remove([fileName]);
      } else {
        throw Exception('You can only delete your own files');
      }
    } catch (e) {
      print('Error deleting image: $e');
      if (e.toString().contains('not found')) {
        throw Exception('File not found');
      }
      rethrow;
    }
  }

  String getImageUrl({
    required String bucket,
    required String path,
    bool cacheBust = false,
  }) {
    final url = _supabase.storage.from(bucket).getPublicUrl(path);

    if (cacheBust) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '$url?t=$timestamp';
    }

    return url;
  }

  // NEW METHOD: Delete multiple comment images (from my version)
  Future<void> deleteCommentImages(List<String> imageUrls) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final List<String> filenames = [];
      for (final imageUrl in imageUrls) {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length < 2) {
          continue;
        }

        final filename = pathSegments.last;
        if (filename.startsWith('${user.id}_')) {
          filenames.add(filename);
        }
      }

      if (filenames.isNotEmpty) {
        await _supabase.storage.from('comment-images').remove(filenames);
      }
    } catch (e) {
      print('Error deleting comment images: $e');
      rethrow;
    }
  }

  // Convenience method for uploading multiple comment images (from my version)
  Future<List<String>> uploadCommentImages(
    List<XFile> imageFiles, {
    String? fileNamePrefix,
  }) async {
    return uploadMultipleImages(
      bucket: 'comment-images',
      imageFiles: imageFiles,
      customFileNamePrefix: fileNamePrefix ?? 'comment',
      isPublic: true,
    );
  }

  Future<String> uploadCommentImage(XFile imageFile, {String? fileName}) async {
    return uploadImage(
      bucket: 'comment-images',
      imageFile: imageFile,
      customFileName: fileName,
      isPublic: true,
    );
  }

  // Convenience method for uploading multiple blog images (from my version)
  Future<List<String>> uploadBlogImages(
    List<XFile> imageFiles, {
    String? fileNamePrefix,
  }) async {
    return uploadMultipleImages(
      bucket: 'blog-images',
      imageFiles: imageFiles,
      customFileNamePrefix: fileNamePrefix ?? 'blog',
      isPublic: true,
    );
  }

  Future<String> uploadBlogImage(
    XFile imageFile, {
    String? fileName,
    bool isPublic = true,
  }) async {
    return uploadImage(
      bucket: 'blog-images',
      imageFile: imageFile,
      customFileName: fileName,
      isPublic: isPublic,
    );
  }

  Future<String> uploadProfileImage(XFile imageFile, {String? fileName}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final profileFileName = fileName ?? '${user.id}_profile';

    return uploadImage(
      bucket: 'profile-images',
      imageFile: imageFile,
      customFileName: profileFileName,
      isPublic: true,
    );
  }

  Future<List<int>> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).download(path);

      return response;
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  Future<List<String>> listFiles({
    required String bucket,
    String? prefix,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).list();

      List<FileObject> filteredFiles = response;
      if (prefix != null) {
        filteredFiles = response
            .where((file) => file.name.startsWith(prefix))
            .toList();
      }

      final paginatedFiles = filteredFiles.skip(offset).take(limit).toList();

      return paginatedFiles.map((file) => file.name).toList();
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }

  Future<bool> fileExists({
    required String bucket,
    required String path,
  }) async {
    try {
      final files = await listFiles(bucket: bucket, prefix: path, limit: 1);

      return files.any((file) => file == path);
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> createSignedUrls({
    required String bucket,
    required List<String> paths,
    int expiryInSeconds = 3600,
  }) async {
    try {
      final urls = <String>[];
      for (final path in paths) {
        final url = await _supabase.storage
            .from(bucket)
            .createSignedUrl(path, expiryInSeconds);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      print('Error creating signed URLs: $e');
      rethrow;
    }
  }

  // Note: Your original deleteCommentImage method remains unchanged
  Future<void> deleteCommentImage(String imageUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 2) {
        throw Exception('Invalid image URL');
      }

      final filename = pathSegments.last;

      if (filename.startsWith('${user.id}_')) {
        await _supabase.storage.from('comment-images').remove([filename]);
      } else {
        throw Exception('You can only delete your own comment images');
      }
    } catch (e) {
      print('Error deleting comment image: $e');
      rethrow;
    }
  }
}
