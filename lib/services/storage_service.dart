import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _historyKey = 'compression_history';
  
  // Request storage permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we don't need external storage permission for app-specific directories
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // Android 13+ - Request photos permission for picking images
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      } else if (androidInfo >= 30) {
        // Android 11-12 - Use manage external storage or app-specific directory
        final status = await Permission.storage.request();
        return status.isGranted;
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }
  
  static Future<int> _getAndroidVersion() async {
    try {
      // Get Android SDK version
      return 30; // Default to API 30 for safety
    } catch (e) {
      return 30;
    }
  }
  
  // Get app folder structure - using app-specific external storage (no permissions needed)
  static Future<Map<String, Directory>> getAppDirectories() async {
    // Use getExternalStorageDirectory() which gives us app-specific external storage
    // This is in /storage/emulated/0/Android/data/com.example.my_app/files/
    // No permissions needed for this location
    final Directory? appDocDir = await getExternalStorageDirectory();
    
    if (appDocDir == null) {
      throw Exception('External storage not available');
    }
    
    // Create subdirectories in app-specific storage
    final Directory jpegLiteDir = Directory('${appDocDir.path}/JPEG-Lite');
    final Directory originalDir = Directory('${jpegLiteDir.path}/original');
    final Directory compressedDir = Directory('${jpegLiteDir.path}/compressed');
    
    // Create directories if they don't exist
    if (!await jpegLiteDir.exists()) {
      await jpegLiteDir.create(recursive: true);
    }
    if (!await originalDir.exists()) {
      await originalDir.create(recursive: true);
    }
    if (!await compressedDir.exists()) {
      await compressedDir.create(recursive: true);
    }
    
    debugPrint('JPEG-Lite directories created at: ${jpegLiteDir.path}');
    
    return {
      'main': jpegLiteDir,
      'original': originalDir,
      'compressed': compressedDir,
    };
  }
  
  // Generate unique filename
  static String generateFilename() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    return 'IMG_${formatter.format(now)}.jpg';
  }
  
  // Copy original image to original folder
  static Future<String> copyOriginalImage(String sourcePath) async {
    try {
      final directories = await getAppDirectories();
      final originalDir = directories['original']!;
      final filename = generateFilename();
      final destinationPath = '${originalDir.path}/$filename';
      
      final sourceFile = File(sourcePath);
      
      // Check if source file exists
      if (!await sourceFile.exists()) {
        throw Exception('Source image not found: $sourcePath');
      }
      
      // Copy the file
      await sourceFile.copy(destinationPath);
      
      debugPrint('Image copied to: $destinationPath');
      
      return destinationPath;
    } catch (e) {
      debugPrint('Error copying image: $e');
      rethrow;
    }
  }
  
  // Save compressed image
  static Future<String> saveCompressedImage(String originalPath, File compressedFile) async {
    final directories = await getAppDirectories();
    final compressedDir = directories['compressed']!;
    
    // Use same filename as original
    final filename = originalPath.split('/').last;
    final destinationPath = '${compressedDir.path}/$filename';
    
    await compressedFile.copy(destinationPath);
    
    debugPrint('Compressed image saved to: $destinationPath');
    
    return destinationPath;
  }
  
  // Save compression record to history
  static Future<void> saveCompressionRecord({
    required String originalPath,
    required String compressedPath,
    required int originalSize,
    required int compressedSize,
    required double compressionRatio,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    final record = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'originalPath': originalPath,
      'compressedPath': compressedPath,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'date': DateTime.now().toIso8601String(),
    };
    
    history.insert(0, record); // Add to beginning
    await prefs.setString(_historyKey, jsonEncode(history));
    
    debugPrint('Compression record saved to history');
  }
  
  // Load compression history
  static Future<List<Map<String, dynamic>>> loadCompressionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    return history.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  // Delete compression record
  static Future<void> deleteCompressionRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    // Find and delete files
    final record = history.firstWhere((item) => item['id'] == id, orElse: () => null);
    if (record != null) {
      try {
        final originalFile = File(record['originalPath']);
        final compressedFile = File(record['compressedPath']);
        
        if (await originalFile.exists()) await originalFile.delete();
        if (await compressedFile.exists()) await compressedFile.delete();
      } catch (e) {
        debugPrint('Error deleting files: $e');
      }
    }
    
    // Remove from history
    history.removeWhere((item) => item['id'] == id);
    await prefs.setString(_historyKey, jsonEncode(history));
  }
  
  // Get file size
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    return await file.length();
  }
}
