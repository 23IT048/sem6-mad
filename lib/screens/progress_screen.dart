import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../utils/app_colors.dart';
import 'animation_screen.dart';
import 'results_screen.dart';

class ProgressScreen extends StatefulWidget {
  final String imagePath;

  const ProgressScreen({super.key, required this.imagePath});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  int _currentPhase = 0;
  bool _isProcessing = true;
  Timer? _timer;
  late AnimationController _animationController;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
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
              originalImagePath: widget.imagePath,
              compressedImagePath: widget.imagePath,
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
          inputImage: File(widget.imagePath),
          onComplete: () {
            if (_isProcessing == false) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultsScreen(
                    originalImagePath: widget.imagePath,
                    compressedImagePath: widget.imagePath,
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          Navigator.pop(context, false);
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Compressing...', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImagePreview(),
                const SizedBox(height: 24),
                _buildProgressCard(),
                const SizedBox(height: 24),
                Expanded(child: _buildPhasesList()),
                const SizedBox(height: 16),
                _buildStatusText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: (_currentPhase + 1) / _phases.length,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Phase ${_currentPhase + 1} of ${_phases.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesList() {
    return ListView.builder(
      itemCount: _phases.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildPhaseCard(
            _phases[index],
            index + 1,
            index < _currentPhase,
            index == _currentPhase,
            index == 4,
          ),
        );
      },
    );
  }

  Widget _buildPhaseCard(String title, int number, bool isCompleted, bool isCurrent, bool isHuffman) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppColors.accentBlue : AppColors.borderGray.withValues(alpha: 0.5),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent ? AppColors.cardShadow : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isCompleted 
                  ? AppColors.successGradient 
                  : (isCurrent ? AppColors.accentGradient : null),
              color: isCompleted || isCurrent ? null : AppColors.borderGray,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : AppColors.mutedGray,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                color: isCompleted ? AppColors.successGreen : (isCurrent ? AppColors.accentBlue : AppColors.mutedGray),
              ),
            ),
          ),
          if (isHuffman && isCurrent)
            _AnimatedButton(
              onPressed: _navigateToAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_outline, size: 18, color: AppColors.accentBlue),
                    SizedBox(width: 4),
                    Text('Animate', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      _isProcessing ? 'Processing...' : 'Compression Complete!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _isProcessing ? AppColors.accentBlue : AppColors.successGreen,
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _AnimatedButton({required this.child, required this.onPressed});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}
