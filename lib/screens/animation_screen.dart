import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/app_colors.dart';

class AnimationScreen extends StatefulWidget {
  final File inputImage;
  final VoidCallback? onComplete;

  const AnimationScreen({super.key, required this.inputImage, this.onComplete});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huffman Coding Animation', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_tree, size: 120, color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              const Text(
                'Huffman Tree Animation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Animation Placeholder',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The Huffman coding animation will be implemented here.\nThis screen shows the tree building process step by step.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      'What is Huffman Coding?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Huffman coding is a lossless data compression algorithm that assigns variable-length codes to characters based on their frequency of occurrence.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
