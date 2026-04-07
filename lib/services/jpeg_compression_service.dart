import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

import 'storage_service.dart';

Future<Map<String, dynamic>> compressImageInBackground(
  Map<String, dynamic> args,
) async {
  final service = JpegCompressionService();
  final result = await service.compressToMemory(
    imagePath: args['imagePath'] as String,
    compressionLevel: args['compressionLevel'] as String,
  );

  return {
    'jpegBytes': result.jpegBytes,
    'originalWidth': result.originalWidth,
    'originalHeight': result.originalHeight,
    'targetWidth': result.targetWidth,
    'targetHeight': result.targetHeight,
  };
}

class CompressionMemoryResult {
  final List<int> jpegBytes;
  final int originalWidth;
  final int originalHeight;
  final int targetWidth;
  final int targetHeight;

  const CompressionMemoryResult({
    required this.jpegBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.targetWidth,
    required this.targetHeight,
  });
}

class CompressionResult {
  final String outputPath;
  final int originalWidth;
  final int originalHeight;
  final int targetWidth;
  final int targetHeight;

  const CompressionResult({
    required this.outputPath,
    required this.originalWidth,
    required this.originalHeight,
    required this.targetWidth,
    required this.targetHeight,
  });
}

class JpegCompressionService {
  static const List<List<int>> _baseLuminanceQuant = [
    [16, 11, 10, 16, 24, 40, 51, 61],
    [12, 12, 14, 19, 26, 58, 60, 55],
    [14, 13, 16, 24, 40, 57, 69, 56],
    [14, 17, 22, 29, 51, 87, 80, 62],
    [18, 22, 37, 56, 68, 109, 103, 77],
    [24, 35, 55, 64, 81, 104, 113, 92],
    [49, 64, 78, 87, 103, 121, 120, 101],
    [72, 92, 95, 98, 112, 100, 103, 99],
  ];

  static const List<Point<int>> _zigZag = [
    Point(0, 0),
    Point(0, 1),
    Point(1, 0),
    Point(2, 0),
    Point(1, 1),
    Point(0, 2),
    Point(0, 3),
    Point(1, 2),
    Point(2, 1),
    Point(3, 0),
    Point(4, 0),
    Point(3, 1),
    Point(2, 2),
    Point(1, 3),
    Point(0, 4),
    Point(0, 5),
    Point(1, 4),
    Point(2, 3),
    Point(3, 2),
    Point(4, 1),
    Point(5, 0),
    Point(6, 0),
    Point(5, 1),
    Point(4, 2),
    Point(3, 3),
    Point(2, 4),
    Point(1, 5),
    Point(0, 6),
    Point(0, 7),
    Point(1, 6),
    Point(2, 5),
    Point(3, 4),
    Point(4, 3),
    Point(5, 2),
    Point(6, 1),
    Point(7, 0),
    Point(7, 1),
    Point(6, 2),
    Point(5, 3),
    Point(4, 4),
    Point(3, 5),
    Point(2, 6),
    Point(1, 7),
    Point(2, 7),
    Point(3, 6),
    Point(4, 5),
    Point(5, 4),
    Point(6, 3),
    Point(7, 2),
    Point(7, 3),
    Point(6, 4),
    Point(5, 5),
    Point(4, 6),
    Point(3, 7),
    Point(4, 7),
    Point(5, 6),
    Point(6, 5),
    Point(7, 4),
    Point(7, 5),
    Point(6, 6),
    Point(5, 7),
    Point(6, 7),
    Point(7, 6),
    Point(7, 7),
  ];

  Future<CompressionResult> compressImage({
    required String imagePath,
    required String compressionLevel,
    bool grayscale = false,
    void Function(int step, String name)? onStep,
  }) async {
    final memoryResult = await compressToMemory(
      imagePath: imagePath,
      compressionLevel: compressionLevel,
      grayscale: grayscale,
      onStep: onStep,
    );

    final directories = await StorageService.getAppDirectories();
    final compressedDir = directories['compressed']!;
    final outputPath = '${compressedDir.path}/${StorageService.generateFilename()}';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(memoryResult.jpegBytes, flush: true);

    return CompressionResult(
      outputPath: outputPath,
      originalWidth: memoryResult.originalWidth,
      originalHeight: memoryResult.originalHeight,
      targetWidth: memoryResult.targetWidth,
      targetHeight: memoryResult.targetHeight,
    );
  }

  Future<CompressionMemoryResult> compressToMemory({
    required String imagePath,
    required String compressionLevel,
    bool grayscale = false,
    void Function(int step, String name)? onStep,
  }) async {
    onStep?.call(1, 'Input Image');
    final sourceFile = File(imagePath);
    final bytes = await sourceFile.readAsBytes();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported input image');
    }

    final extension = imagePath.toLowerCase();
    final isSupported = extension.endsWith('.png') ||
        extension.endsWith('.bmp') ||
        extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg');
    if (!isSupported) {
      throw Exception('Only PNG, BMP, JPG are supported');
    }

    final originalWidth = decoded.width;
    final originalHeight = decoded.height;

    onStep?.call(2, 'RGB to YCbCr');
    final yPlane = _matrix(originalHeight, originalWidth);
    final cbPlane = _matrix(originalHeight, originalWidth);
    final crPlane = _matrix(originalHeight, originalWidth);

    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        yPlane[y][x] = 0.299 * r + 0.587 * g + 0.114 * b;
        cbPlane[y][x] = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
        crPlane[y][x] = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
      }
    }

    if (grayscale) {
      for (int y = 0; y < originalHeight; y++) {
        for (int x = 0; x < originalWidth; x++) {
          cbPlane[y][x] = 128;
          crPlane[y][x] = 128;
        }
      }
    }

    onStep?.call(3, 'Gaussian Filtering');
    final sigma = _sigmaForLevel(compressionLevel);
    final yFiltered = _gaussianBlur(yPlane, sigma);
    final cbFiltered = _gaussianBlur(cbPlane, sigma);
    final crFiltered = _gaussianBlur(crPlane, sigma);

    onStep?.call(4, 'Spatial Downsampling');
    final downScale = _downscaleForLevel(compressionLevel);
    final targetWidth = max(8, (originalWidth * downScale).round());
    final targetHeight = max(8, (originalHeight * downScale).round());

    final yResized = _resizeBilinear(yFiltered, targetWidth, targetHeight);
    final cbResized = _resizeBilinear(cbFiltered, targetWidth, targetHeight);
    final crResized = _resizeBilinear(crFiltered, targetWidth, targetHeight);

    onStep?.call(5, '8x8 Block Splitting');
    final paddedWidth = ((targetWidth + 7) ~/ 8) * 8;
    final paddedHeight = ((targetHeight + 7) ~/ 8) * 8;
    final yPadded = _padPlane(yResized, paddedWidth, paddedHeight);

    onStep?.call(6, 'Discrete Cosine Transform');
    final dctBlocks = <List<List<double>>>[];
    for (int by = 0; by < paddedHeight; by += 8) {
      for (int bx = 0; bx < paddedWidth; bx += 8) {
        final block = _extractBlock(yPadded, bx, by);
        dctBlocks.add(_dct2d(block));
      }
    }

    onStep?.call(7, 'Quantization');
    final quantMatrix = _scaledQuantization(compressionLevel);
    final quantizedBlocks = <List<List<int>>>[];
    for (final coeffs in dctBlocks) {
      quantizedBlocks.add(_quantize(coeffs, quantMatrix));
    }

    onStep?.call(8, 'Zig-Zag Ordering');
    final zigzagBlocks = <List<int>>[];
    for (final block in quantizedBlocks) {
      zigzagBlocks.add(_zigZagLinearize(block));
    }

    onStep?.call(9, 'Run-Length Encoding');
    final symbols = <String>[];
    for (final seq in zigzagBlocks) {
      final rle = _rleEncode(seq);
      symbols.addAll(rle.map((entry) => '${entry.$1}:${entry.$2}'));
    }

    onStep?.call(10, 'Huffman Coding');
    final huffmanCodes = _buildHuffmanCodes(symbols);
    final _ = huffmanCodes.length;

    onStep?.call(11, 'JPEG File Construction');
    final yReconstructed = _reconstructLuma(
      quantizedBlocks,
      quantMatrix,
      paddedWidth,
      paddedHeight,
      targetWidth,
      targetHeight,
    );

    final outImage = img.Image(width: targetWidth, height: targetHeight);
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final yy = yReconstructed[y][x];
        final cb = cbResized[y][x];
        final cr = crResized[y][x];

        final r = (yy + 1.402 * (cr - 128)).clamp(0, 255).round();
        final g =
            (yy - 0.344136 * (cb - 128) - 0.714136 * (cr - 128)).clamp(0, 255)
                .round();
        final b = (yy + 1.772 * (cb - 128)).clamp(0, 255).round();
        outImage.setPixelRgb(x, y, r, g, b);
      }
    }

    int quality = _jpegQualityForLevel(compressionLevel);
    final sourceSize = await sourceFile.length();
    List<int> jpegBytes = img.encodeJpg(outImage, quality: quality);

    int retries = 0;
    img.Image shrinkingImage = outImage;
    while (jpegBytes.length >= sourceSize && retries < 6) {
      retries++;

      if (quality > 22) {
        quality = max(22, quality - 8);
      } else {
        final nextWidth = max(8, (shrinkingImage.width * 0.88).round());
        final nextHeight = max(8, (shrinkingImage.height * 0.88).round());
        shrinkingImage = img.copyResize(
          shrinkingImage,
          width: nextWidth,
          height: nextHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      jpegBytes = img.encodeJpg(shrinkingImage, quality: quality);
    }

    return CompressionMemoryResult(
      jpegBytes: jpegBytes,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  List<List<double>> _matrix(int h, int w) {
    return List.generate(h, (_) => List.filled(w, 0.0));
  }

  double _sigmaForLevel(String level) {
    switch (level) {
      case 'Low':
        return 0.7;
      case 'High':
        return 1.3;
      default:
        return 1.0;
    }
  }

  double _downscaleForLevel(String level) {
    switch (level) {
      case 'Low':
        return 0.9;
      case 'High':
        return 0.45;
      default:
        return 0.65;
    }
  }

  int _jpegQualityForLevel(String level) {
    switch (level) {
      case 'Low':
        return 76;
      case 'High':
        return 34;
      default:
        return 52;
    }
  }

  List<List<double>> _gaussianBlur(List<List<double>> input, double sigma) {
    final h = input.length;
    final w = input.first.length;
    final kernel = _gaussianKernel(5, sigma);
    final out = _matrix(h, w);
    final center = kernel.length ~/ 2;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double sum = 0;
        for (int ky = 0; ky < kernel.length; ky++) {
          for (int kx = 0; kx < kernel.length; kx++) {
            final iy = (y + ky - center).clamp(0, h - 1);
            final ix = (x + kx - center).clamp(0, w - 1);
            sum += input[iy][ix] * kernel[ky][kx];
          }
        }
        out[y][x] = sum;
      }
    }

    return out;
  }

  List<List<double>> _gaussianKernel(int size, double sigma) {
    final kernel = List.generate(size, (_) => List.filled(size, 0.0));
    final center = size ~/ 2;
    final s2 = 2 * sigma * sigma;
    double total = 0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dy = y - center;
        final dx = x - center;
        final value = exp(-(dx * dx + dy * dy) / s2);
        kernel[y][x] = value;
        total += value;
      }
    }

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        kernel[y][x] /= total;
      }
    }

    return kernel;
  }

  List<List<double>> _resizeBilinear(
    List<List<double>> source,
    int newW,
    int newH,
  ) {
    final srcH = source.length;
    final srcW = source.first.length;
    final out = _matrix(newH, newW);

    if (newW == 1 || newH == 1) {
      for (int y = 0; y < newH; y++) {
        for (int x = 0; x < newW; x++) {
          out[y][x] = source[(y * srcH ~/ newH).clamp(0, srcH - 1)]
              [(x * srcW ~/ newW).clamp(0, srcW - 1)];
        }
      }
      return out;
    }

    for (int y = 0; y < newH; y++) {
      final gy = (y * (srcH - 1)) / (newH - 1);
      final y0 = gy.floor();
      final y1 = min(y0 + 1, srcH - 1);
      final wy = gy - y0;

      for (int x = 0; x < newW; x++) {
        final gx = (x * (srcW - 1)) / (newW - 1);
        final x0 = gx.floor();
        final x1 = min(x0 + 1, srcW - 1);
        final wx = gx - x0;

        final top = source[y0][x0] * (1 - wx) + source[y0][x1] * wx;
        final bottom = source[y1][x0] * (1 - wx) + source[y1][x1] * wx;
        out[y][x] = top * (1 - wy) + bottom * wy;
      }
    }

    return out;
  }

  List<List<double>> _padPlane(
    List<List<double>> source,
    int paddedW,
    int paddedH,
  ) {
    final srcH = source.length;
    final srcW = source.first.length;
    final out = _matrix(paddedH, paddedW);

    for (int y = 0; y < paddedH; y++) {
      for (int x = 0; x < paddedW; x++) {
        final sy = y.clamp(0, srcH - 1);
        final sx = x.clamp(0, srcW - 1);
        out[y][x] = source[sy][sx];
      }
    }
    return out;
  }

  List<List<double>> _extractBlock(List<List<double>> plane, int bx, int by) {
    return List.generate(8, (y) {
      return List.generate(8, (x) => plane[by + y][bx + x] - 128.0);
    });
  }

  List<List<double>> _dct2d(List<List<double>> block) {
    final out = _matrix(8, 8);
    for (int u = 0; u < 8; u++) {
      for (int v = 0; v < 8; v++) {
        double sum = 0;
        for (int x = 0; x < 8; x++) {
          for (int y = 0; y < 8; y++) {
            sum += block[y][x] *
                cos(((2 * x + 1) * u * pi) / 16.0) *
                cos(((2 * y + 1) * v * pi) / 16.0);
          }
        }
        out[v][u] = 0.25 * _alpha(u) * _alpha(v) * sum;
      }
    }
    return out;
  }

  double _alpha(int index) {
    return index == 0 ? 1 / sqrt(2) : 1;
  }

  List<List<int>> _scaledQuantization(String level) {
    double scale;
    switch (level) {
      case 'Low':
        scale = 0.9;
        break;
      case 'High':
        scale = 2.2;
        break;
      default:
        scale = 1.5;
    }

    return List.generate(8, (y) {
      return List.generate(8, (x) {
        final q = (_baseLuminanceQuant[y][x] * scale).round();
        return q.clamp(1, 255);
      });
    });
  }

  List<List<int>> _quantize(List<List<double>> dct, List<List<int>> q) {
    return List.generate(8, (y) {
      return List.generate(8, (x) {
        return (dct[y][x] / q[y][x]).round();
      });
    });
  }

  List<int> _zigZagLinearize(List<List<int>> block) {
    return _zigZag.map((p) => block[p.y][p.x]).toList();
  }

  List<(int, int)> _rleEncode(List<int> values) {
    final out = <(int, int)>[];
    int run = 0;

    for (final value in values) {
      if (value == 0) {
        run++;
      } else {
        if (run > 0) {
          out.add((run, 0));
          run = 0;
        }
        out.add((0, value));
      }
    }

    if (run > 0) {
      out.add((run, 0));
    }

    return out;
  }

  Map<String, String> _buildHuffmanCodes(List<String> symbols) {
    if (symbols.isEmpty) {
      return {};
    }

    final freq = <String, int>{};
    for (final s in symbols) {
      freq[s] = (freq[s] ?? 0) + 1;
    }

    final nodes = freq.entries
        .map((e) => _HuffmanNode(symbol: e.key, frequency: e.value))
        .toList();

    while (nodes.length > 1) {
      nodes.sort((a, b) => a.frequency.compareTo(b.frequency));
      final left = nodes.removeAt(0);
      final right = nodes.removeAt(0);
      nodes.add(
        _HuffmanNode(
          symbol: null,
          frequency: left.frequency + right.frequency,
          left: left,
          right: right,
        ),
      );
    }

    final codes = <String, String>{};
    _walkHuffman(nodes.first, '', codes);
    return codes;
  }

  void _walkHuffman(_HuffmanNode node, String prefix, Map<String, String> codes) {
    if (node.symbol != null) {
      codes[node.symbol!] = prefix.isEmpty ? '0' : prefix;
      return;
    }

    if (node.left != null) {
      _walkHuffman(node.left!, '${prefix}0', codes);
    }
    if (node.right != null) {
      _walkHuffman(node.right!, '${prefix}1', codes);
    }
  }

  List<List<double>> _reconstructLuma(
    List<List<List<int>>> quantized,
    List<List<int>> q,
    int paddedW,
    int paddedH,
    int targetW,
    int targetH,
  ) {
    final padded = _matrix(paddedH, paddedW);
    int blockIndex = 0;

    for (int by = 0; by < paddedH; by += 8) {
      for (int bx = 0; bx < paddedW; bx += 8) {
        final block = _inverseQuantize(quantized[blockIndex], q);
        final spatial = _idct2d(block);
        for (int y = 0; y < 8; y++) {
          for (int x = 0; x < 8; x++) {
            padded[by + y][bx + x] = (spatial[y][x] + 128).clamp(0, 255);
          }
        }
        blockIndex++;
      }
    }

    return List.generate(
      targetH,
      (y) => List.generate(targetW, (x) => padded[y][x]),
    );
  }

  List<List<double>> _inverseQuantize(List<List<int>> block, List<List<int>> q) {
    return List.generate(8, (y) {
      return List.generate(8, (x) {
        return block[y][x] * q[y][x].toDouble();
      });
    });
  }

  List<List<double>> _idct2d(List<List<double>> coeffs) {
    final out = _matrix(8, 8);

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        double sum = 0;
        for (int u = 0; u < 8; u++) {
          for (int v = 0; v < 8; v++) {
            sum += _alpha(u) *
                _alpha(v) *
                coeffs[v][u] *
                cos(((2 * x + 1) * u * pi) / 16.0) *
                cos(((2 * y + 1) * v * pi) / 16.0);
          }
        }
        out[y][x] = 0.25 * sum;
      }
    }

    return out;
  }
}

class _HuffmanNode {
  final String? symbol;
  final int frequency;
  final _HuffmanNode? left;
  final _HuffmanNode? right;

  const _HuffmanNode({
    required this.symbol,
    required this.frequency,
    this.left,
    this.right,
  });
}
