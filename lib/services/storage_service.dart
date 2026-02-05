import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // Upload image to Supabase Storage with improved error handling
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

      // Get file extension from path or MIME type
      String extension = _getFileExtension(imageFile);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 100000;
      final uniqueFileName =
          customFileName ?? '${user.id}_${timestamp}_$random.$extension';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Validate file size (max 10MB)
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('Image file too large. Maximum size is 10MB.');
      }

      // Upload file
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

      // Get URL with cache busting query parameter
      final String imageUrl;
      if (isPublic) {
        // For public URLs
        final baseUrl = _supabase.storage
            .from(bucket)
            .getPublicUrl(uniqueFileName);

        // Add timestamp to prevent caching issues
        imageUrl = '$baseUrl?t=$timestamp';
      } else {
        // For private files, use signed URL
        final response = await _supabase.storage
            .from(bucket)
            .createSignedUrl(uniqueFileName, 60 * 60); // 1 hour expiry
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

  // Helper method to get file extension
  String _getFileExtension(XFile file) {
    try {
      // Try to get extension from path
      final filePath = file.path;
      if (filePath.isNotEmpty) {
        final extension = path.extension(filePath).toLowerCase();
        if (extension.isNotEmpty && extension.length > 1) {
          return extension.substring(1); // Remove the dot
        }
      }

      // Try to get from name
      final name = file.name;
      if (name.contains('.')) {
        return name.split('.').last.toLowerCase();
      }

      // Fallback: check MIME type
      final mimeType = file.mimeType?.toLowerCase() ?? '';
      if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return 'jpg';
      if (mimeType.contains('png')) return 'png';
      if (mimeType.contains('gif')) return 'gif';
      if (mimeType.contains('webp')) return 'webp';

      // Default to jpg
      return 'jpg';
    } catch (e) {
      return 'jpg'; // Default fallback
    }
  }

  // Helper method to get MIME type from extension
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

  // Pick image from gallery with compression options
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
        requestFullMetadata: false, // For better performance
      );
      return pickedFile;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick image from camera with compression
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

  // Delete image from storage with validation
  Future<void> deleteImage({
    required String bucket,
    required String fileName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Optional: Validate user owns the file
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

  // Get image URL with cache busting option
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

  // Delete comment image with validation
  Future<void> deleteCommentImage(String imageUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 2) {
        throw Exception('Invalid image URL');
      }

      final filename = pathSegments.last;

      // Validate user owns the file before deleting
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

  // Upload comment image with specific bucket
  Future<String> uploadCommentImage(XFile imageFile, {String? fileName}) async {
    return uploadImage(
      bucket: 'comment-images',
      imageFile: imageFile,
      customFileName: fileName,
      isPublic: true,
    );
  }

  // Upload blog image with specific bucket
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

  // Upload profile image with specific bucket and validation
  Future<String> uploadProfileImage(XFile imageFile, {String? fileName}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Always use user ID in profile image filename
    final profileFileName = fileName ?? '${user.id}_profile';

    return uploadImage(
      bucket: 'profile-images',
      imageFile: imageFile,
      customFileName: profileFileName,
      isPublic: true,
    );
  }

  // Download file as bytes (for private files)
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

  // List files in a bucket - Simplified version without SearchOptions
  Future<List<String>> listFiles({
    required String bucket,
    String? prefix,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // Get all files
      final response = await _supabase.storage.from(bucket).list();

      // Filter by prefix if provided
      List<FileObject> filteredFiles = response;
      if (prefix != null) {
        filteredFiles = response
            .where((file) => file.name.startsWith(prefix))
            .toList();
      }

      // Apply pagination
      final paginatedFiles = filteredFiles.skip(offset).take(limit).toList();

      return paginatedFiles.map((file) => file.name).toList();
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }

  // Check if file exists
  Future<bool> fileExists({
    required String bucket,
    required String path,
  }) async {
    try {
      // Try to list files with the exact path as prefix
      final files = await listFiles(bucket: bucket, prefix: path, limit: 1);

      // Check if any file matches exactly
      return files.any((file) => file == path);
    } catch (e) {
      return false;
    }
  }

  // Get multiple signed URLs for private files
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
}
