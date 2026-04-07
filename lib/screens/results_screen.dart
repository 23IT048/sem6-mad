import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'animation_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String originalImagePath;
  final String compressedImagePath;
  final Map<String, dynamic>? existingRecord;
  final bool autoSavedToHistory;

  const ResultsScreen({
    super.key,
    required this.originalImagePath,
    required this.compressedImagePath,
    this.existingRecord,
    this.autoSavedToHistory = false,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  bool _isSaved = false;
  bool _showOriginal = true;
  bool _showAnimations = true;
  int? _originalSize;
  int? _compressedSize;
  double? _compressionRatio;
  bool _saveHistoryEnabled = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final saveHistoryEnabled = await StorageService.getSaveHistory();
    final showAnimations = await StorageService.getShowAnimations();

    if (widget.existingRecord != null) {
      setState(() {
        _originalSize = widget.existingRecord!['originalSize'];
        _compressedSize = widget.existingRecord!['compressedSize'];
        _compressionRatio = widget.existingRecord!['compressionRatio'];
        _isSaved = true;
        _saveHistoryEnabled = true;
        _showAnimations = showAnimations;
      });
    } else {
      final originalSize = await StorageService.getFileSize(widget.originalImagePath);
      final compressedSize = await StorageService.getFileSize(widget.compressedImagePath);
      final ratio = ((originalSize - compressedSize) / originalSize * 100);

      setState(() {
        _originalSize = originalSize;
        _compressedSize = compressedSize;
        _compressionRatio = ratio;
        _saveHistoryEnabled = saveHistoryEnabled;
        _isSaved = widget.autoSavedToHistory;
        _showAnimations = showAnimations;
      });
    }
  }

  Future<void> _saveResults() async {
    if (_isSaved || _originalSize == null || _compressedSize == null || !_saveHistoryEnabled) return;

    setState(() => _isSaving = true);

    try {
      await StorageService.saveCompressionRecord(
        originalPath: widget.originalImagePath,
        compressedPath: widget.compressedImagePath,
        originalSize: _originalSize!,
        compressedSize: _compressedSize!,
        compressionRatio: _compressionRatio!,
      );

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Compression saved successfully!'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  void _navigateToAnimation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimationScreen(
          inputImage: File(widget.compressedImagePath),
          fromResults: true,
        ),
      ),
    );
  }

  void _backToHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Compression Results', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: FadeTransition(
          opacity: _animationController,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildImageComparisonCard(),
                const SizedBox(height: 24),
                _buildStatsCard(),
                const SizedBox(height: 24),
                if (_showAnimations) ...[
                  _buildActionButton(
                    label: 'View Huffman Animation',
                    icon: Icons.animation,
                    gradient: AppColors.accentGradient,
                    onPressed: _navigateToAnimation,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_saveHistoryEnabled)
                  _buildSavedBadge(
                    label: _isSaved ? 'Auto-saved to History' : 'Save History Enabled',
                  )
                else if (!_isSaved)
                  _buildActionButton(
                    label: !_saveHistoryEnabled
                        ? 'Enable Save History in Settings'
                        : (_isSaving ? 'Saving...' : 'Save to History'),
                    icon: Icons.bookmark_rounded,
                    gradient: _saveHistoryEnabled ? AppColors.successGradient : AppColors.primaryGradient,
                    onPressed: (_isSaving || !_saveHistoryEnabled) ? null : _saveResults,
                  )
                else
                  _buildSavedBadge(),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: 'Back to Home',
                  icon: Icons.home_rounded,
                  gradient: AppColors.primaryGradient,
                  onPressed: _backToHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _buildToggleButtons(),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_showOriginal),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(_showOriginal ? widget.originalImagePath : widget.compressedImagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.borderGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('Original', true)),
          Expanded(child: _buildToggleButton('Compressed', false)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isOriginal) {
    final isSelected = _showOriginal == isOriginal;
    return GestureDetector(
      onTap: () => setState(() => _showOriginal = isOriginal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? AppColors.cardShadow : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primaryNavy : AppColors.mutedGray,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Column(
        children: [
          _buildStatRow('Original Size', _formatSize(_originalSize ?? 0)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24, height: 1),
          ),
          _buildStatRow('Compressed Size', _formatSize(_compressedSize ?? 0)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24, height: 1),
          ),
          _buildStatRow(
            'Compression Ratio',
            '${_compressionRatio?.toStringAsFixed(1) ?? '0'}%',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.successGreen : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    VoidCallback? onPressed,
  }) {
    return _AnimatedButton(
      onPressed: onPressed ?? () {},
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : gradient,
          color: onPressed == null ? AppColors.borderGray : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: onPressed == null ? null : AppColors.buttonShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedBadge({String label = 'Saved to History'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
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
