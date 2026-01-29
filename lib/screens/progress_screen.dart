import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../utils/app_colors.dart';
import 'animation_screen.dart';
import 'results_screen.dart';

class ProgressScreen extends StatefulWidget {
  final File inputImage;

  const ProgressScreen({super.key, required this.inputImage});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _currentPhase = 0;
  bool _isProcessing = true;
  Timer? _timer;

  final List<String> _phases = [
    'Color Space Conversion',
    'Chroma Subsampling',
    'DCT Transform',
    'Quantization',
    'Huffman Coding',
  ];

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPhase < _phases.length - 1) {
        setState(() => _currentPhase++);
      } else {
        timer.cancel();
        setState(() => _isProcessing = false);
        _navigateToResults();
      }
    });
  }

  void _navigateToResults() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              inputImage: widget.inputImage,
              outputImage: widget.inputImage, // Same image for now
            ),
          ),
        );
      }
    });
  }

  void _navigateToAnimation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimationScreen(
          inputImage: widget.inputImage,
          onComplete: () {
            if (_isProcessing == false) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultsScreen(
                    inputImage: widget.inputImage,
                    outputImage: widget.inputImage,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compression Progress', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.inputImage, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentPhase + 1) / _phases.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              'Phase ${_currentPhase + 1} of ${_phases.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Phase Cards
            Expanded(
              child: ListView.builder(
                itemCount: _phases.length,
                itemBuilder: (context, index) {
                  final isCompleted = index < _currentPhase;
                  final isCurrent = index == _currentPhase;
                  final isHuffman = index == 4;

                  return _buildPhaseCard(
                    _phases[index],
                    index + 1,
                    isCompleted,
                    isCurrent,
                    isHuffman,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Status Text
            Text(
              _isProcessing ? 'Processing...' : 'Compression Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isProcessing ? AppColors.primaryBlue : AppColors.accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(String title, int number, bool isCompleted, bool isCurrent, bool isHuffman) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primaryBlue : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.accentGreen : (isCurrent ? AppColors.primaryBlue : Colors.grey.shade300),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? AppColors.accentGreen : (isCurrent ? AppColors.primaryBlue : Colors.grey.shade600),
              ),
            ),
          ),
          if (isHuffman && isCurrent)
            TextButton.icon(
              onPressed: _navigateToAnimation,
              icon: const Icon(Icons.play_circle_outline, size: 20),
              label: const Text('Animate'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
        ],
      ),
    );
  }
}
