import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class GifService {
  static String apiBasePath = '/static/assets/gifs'; 
  
  static String getGifUrl(String gifName) {
    if (gifName.startsWith('http')) {
      return gifName;
    }
    
    return '${ApiService.baseUrl}$apiBasePath/$gifName';
  }
  
  static List<String> getAlternativeGifUrls(String gifName) {
    if (gifName.startsWith('http')) {
      return [gifName];
    }
    
    return [
      '${ApiService.baseUrl}/static/assets/gifs/$gifName', 
      '${ApiService.baseUrl}/assets/gifs/$gifName',  
      '${ApiService.baseUrl}/gifs/$gifName',        
      '${ApiService.baseUrl}/static/gifs/$gifName',
    ];
  }
  
  static Future<bool> checkGifAvailability(String gifName) async {
    try {
      final urls = getAlternativeGifUrls(gifName);
      
      for (final url in urls) {
        try {
          final response = await http.head(Uri.parse(url));
          if (response.statusCode == 200) {
            print('GIF found at URL: $url');
            if (url.contains('/static/assets/gifs/')) {
            } else if (url.contains('/assets/gifs/')) {
              apiBasePath = '/assets/gifs';
            } else if (url.contains('/static/gifs/')) {
              apiBasePath = '/static/gifs';
            } else if (url.contains('/gifs/')) {
              apiBasePath = '/gifs';
            }
            return true;
          }
        } catch (e) {
          print('Failed to check URL: $url, error: $e');
        }
      }
      
      print('GIF not found on server: $gifName');
      return false;
    } catch (e) {
      print('Error checking GIF availability: $e');
      return false;
    }
  }
  
  static Widget loadNetworkGif({
    required String gifName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool checkAvailability = false,
  }) {
    _incrementLoadCount(gifName);
    
    final url = getGifUrl(gifName);
    
    if (checkAvailability) {
      checkGifAvailability(gifName).then((available) {
        if (!available) {
          print('WARNING: Image not available: $gifName');
        }
      });
    }
    
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Color(0xFFF0F0F0),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7A97F)),
            strokeWidth: 2.0,
          ),
        ),
      ),
    );
    
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Color(0xFFF0F0F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPngFile(gifName) ? Icons.image : Icons.gif_box, 
                 color: Color(0xFFC7A97F), size: 24),
            SizedBox(height: 4),
            Text('Image not found',
                 style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
    
    if (gifName.toLowerCase().endsWith('.gif')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return placeholder ?? defaultPlaceholder;
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading GIF from URL: $url, Error: $error');
          return errorWidget ?? defaultErrorWidget;
        },
        gaplessPlayback: false,
        cacheWidth: null,
        cacheHeight: null,
      );
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) {
        print('Error loading image from URL: $url, Error: $error');
        
        if (isPngFile(gifName)) {
          final gifVersion = gifName.replaceAll('.png', '.gif');
          return loadNetworkGif(
            gifName: gifVersion, 
            width: width, 
            height: height, 
            fit: fit,
            errorWidget: errorWidget ?? defaultErrorWidget,
          );
        }
        
        return errorWidget ?? defaultErrorWidget;
      },
    );
  }
  
  static final Map<String, int> _loadCounters = {};
  
  static void _incrementLoadCount(String gifName) {
    _loadCounters[gifName] = (_loadCounters[gifName] ?? 0) + 1;
  }
  
  static Map<String, int> getLoadStatistics() {
    return Map.from(_loadCounters);
  }
  
  static void resetLoadStatistics() {
    _loadCounters.clear();
  }
  
  static Future<void> preloadGif(String gifName) async {
    final url = getGifUrl(gifName);
    await DefaultCacheManager().getSingleFile(url);
  }
  
  static Future<void> preloadGifs(List<String> gifNames) async {
    for (final gifName in gifNames) {
      await preloadGif(gifName);
    }
  }
  
  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }
  
  static Future<Map<String, String>> clearCacheAndGetStats() async {
    final beforeSize = await getFormattedCacheSize();
    await clearCache();
    
    await Future.delayed(Duration(milliseconds: 500));
    
    final afterSize = await getFormattedCacheSize();
    return {
      'before': beforeSize,
      'after': afterSize,
    };
  }
  
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      
      if (!await cacheDir.exists()) {

        try {
          final possibleCacheDirs = [
            Directory('${tempDir.path}/cached_image_data'),
            Directory('${tempDir.path}/.image_cache'),
            Directory('${tempDir.path}/image_cache'),
          ];
          
          for (var dir in possibleCacheDirs) {
            if (await dir.exists()) {
              return _calculateDirSize(dir);
            }
          }
        } catch (e) {
          print('Error accessing alternative cache directories: $e');
        }
        return 0;
      }
      
      return _calculateDirSize(cacheDir);
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }
  
  static Future<String> getFormattedCacheSize() async {
    final sizeInBytes = await getCacheSize();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
  
  static Future<int> _calculateDirSize(Directory directory) async {
    int totalSize = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
          }
        }
      }
    } catch (e) {
      print('Error during directory traversing: $e');
    }
    return totalSize;
  }
  
  static bool isPngFile(String fileName) {
    return fileName.toLowerCase().endsWith('.png');
  }
  
  static String getPngPreviewName(String gifName) {
    if (isPngFile(gifName)) {
      return gifName;
    }
    
    return gifName.replaceAll(RegExp(r'\.gif$', caseSensitive: false), '.png');
  }
  
  static Widget loadNetworkPreview({
    required String gifName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final pngName = getPngPreviewName(gifName);
    
    return loadNetworkGif(
      gifName: pngName,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
  
  static Future<void> preloadExercisePreviews(List<dynamic> exercises) async {
    if (exercises.isEmpty) return;
    
    print('Preloading ${exercises.length} exercise previews...');
    
    final initialBatch = exercises.take(5).toList();
    for (final ex in initialBatch) {
      final gifFileName = ex.gifFileName;
      if (gifFileName != null) {
        try {
          await preloadGif(getPngPreviewName(gifFileName));
        } catch (e) {
        }
      }
    }
    
    if (exercises.length > 5) {
      final remainingExercises = exercises.skip(5).toList();
      Future.microtask(() async {
        for (final ex in remainingExercises) {
          final gifFileName = ex.gifFileName;
          if (gifFileName != null) {
            try {
              await preloadGif(getPngPreviewName(gifFileName));
            } catch (e) {
            }
          }
        }
        print('Preloaded all ${exercises.length} exercise previews');
      });
    }
  }
  
  static Widget loadAnimatedGif({
    required String gifName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final url = getGifUrl(gifName);
    
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Color(0xFFF0F0F0),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7A97F)),
            strokeWidth: 2.0,
          ),
        ),
      ),
    );
    
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Color(0xFFF0F0F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gif_box, color: Color(0xFFC7A97F), size: 24),
            SizedBox(height: 4),
            Text('Image not found', 
                 style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
    
    if (gifName.toLowerCase().endsWith('.gif')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return placeholder ?? defaultPlaceholder;
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading GIF from URL: $url, Error: $error');
          return errorWidget ?? defaultErrorWidget;
        },
        gaplessPlayback: false, 
        repeat: ImageRepeat.noRepeat,
        cacheWidth: null,
        cacheHeight: null,
      );
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) {
        print('Error loading image from URL: $url, Error: $error');
        
        if (isPngFile(gifName)) {
          final gifVersion = gifName.replaceAll('.png', '.gif');
          return loadNetworkGif(
            gifName: gifVersion, 
            width: width, 
            height: height, 
            fit: fit,
            errorWidget: errorWidget ?? defaultErrorWidget,
          );
        }
        
        return errorWidget ?? defaultErrorWidget;
      },
    );
  }
} 