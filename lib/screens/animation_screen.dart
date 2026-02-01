import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/app_colors.dart';

class AnimationScreen extends StatelessWidget {
  final File inputImage;
  final VoidCallback? onComplete;
  final bool fromResults;

  const AnimationScreen({
    super.key,
    required this.inputImage,
    this.onComplete,
    this.fromResults = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Huffman Tree Animation', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_tree_rounded, 
                    size: 100, 
                    color: AppColors.accentBlue.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Huffman Tree Animation',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'What is Huffman Coding?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Huffman coding is a lossless data compression algorithm that assigns variable-length codes to characters based on their frequency of occurrence.',
                        style: TextStyle(fontSize: 15, color: AppColors.mutedGray, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Animation Placeholder',
                  style: TextStyle(fontSize: 16, color: AppColors.mutedGray.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
