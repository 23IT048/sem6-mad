import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'results_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    StorageService.historyChangeNotifier.addListener(_onHistoryUpdated);
    _loadHistory();
  }

  void _onHistoryUpdated() {
    _loadHistory();
  }

  @override
  void dispose() {
    StorageService.historyChangeNotifier.removeListener(_onHistoryUpdated);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.loadCompressionHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Compression', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this compression record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteCompressionRecord(id);
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted')),
        );
      }
    }
  }

  void _openRecord(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          originalImagePath: record['originalPath'],
          compressedImagePath: record['compressedPath'],
          existingRecord: record,
        ),
      ),
    ).then((_) => _loadHistory());
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
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
          title: const Text('Compression History', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? _buildEmptyState()
                : FadeTransition(
                    opacity: _animationController,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _history.length,
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
                          child: _buildHistoryCard(_history[index]),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.mutedGray.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 64, color: AppColors.mutedGray.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No compression history yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.mutedGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved compressions will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.mutedGray.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRecord(record),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(record['compressedPath']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_rounded, color: AppColors.mutedGray.withValues(alpha: 0.4), size: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(record['date']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatSize(record['originalSize'])} → ${_formatSize(record['compressedSize'])}',
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedGray, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(48),
                          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${record['compressionRatio'].toStringAsFixed(1)}% saved',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _deleteRecord(record['id']),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
