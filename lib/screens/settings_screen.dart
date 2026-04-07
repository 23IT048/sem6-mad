import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool _showAnimations = true;
  bool _saveHistory = false;
  String _compressionQuality = 'Medium';
  String _outputDirectory = '';
  bool _isLoadingSettings = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.loadSettings();
    final outputPath = await StorageService.getOutputDirectoryPath();

    if (!mounted) return;
    setState(() {
      _showAnimations = settings['showAnimations'] as bool;
      _saveHistory = settings['saveHistory'] as bool;
      _compressionQuality = settings['compressionQuality'] as String;
      _outputDirectory = outputPath;
      _isLoadingSettings = false;
    });
  }

  Future<void> _setShowAnimations(bool value) async {
    setState(() => _showAnimations = value);
    await StorageService.setShowAnimations(value);
  }

  Future<void> _setSaveHistory(bool value) async {
    if (value) {
      final granted = await StorageService.requestHistoryStoragePermission();
      if (!granted) {
        if (!mounted) return;
        setState(() => _saveHistory = false);
        await StorageService.setSaveHistory(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied. Save History remains off.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _saveHistory = value);
    await StorageService.setSaveHistory(value);
  }

  Future<void> _setCompressionQuality(String quality) async {
    setState(() => _compressionQuality = quality);
    await StorageService.setCompressionQuality(quality);
  }

  Future<void> _showOutputDirectoryDialog() async {
    final controller = TextEditingController(text: _outputDirectory);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Set Output Folder', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter full folder path',
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await StorageService.setOutputDirectory(result);
      final outputPath = await StorageService.getOutputDirectoryPath();
      if (!mounted) return;
      setState(() => _outputDirectory = outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Output folder updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to set folder: $e')),
      );
    }
  }

  Future<void> _resetOutputDirectory() async {
    await StorageService.setOutputDirectory(null);
    final outputPath = await StorageService.getOutputDirectoryPath();
    if (!mounted) return;
    setState(() => _outputDirectory = outputPath);
  }

  Future<void> _clearHistory() async {
    await StorageService.clearCompressionHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History cleared')),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
        ),
        body: _isLoadingSettings
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
          opacity: _animationController,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildSection('Display'),
              _buildSwitchTile(
                'Show Animations',
                'Enable step-by-step visualization',
                _showAnimations,
                _setShowAnimations,
              ),
              const SizedBox(height: 20),
              
              _buildSection('Storage'),
              _buildSwitchTile(
                'Save History',
                'Keep track of previous compressions',
                _saveHistory,
                _setSaveHistory,
              ),
              const SizedBox(height: 20),

              _buildStoragePathTile(),
              const SizedBox(height: 20),
              
              _buildSection('Compression'),
              _buildQualityTile(),
              const SizedBox(height: 20),
              
              _buildSection('About'),
              _buildInfoTile('Version', '1.0.0'),
              _buildInfoTile('Developer', 'JPEG-Lite Team'),
              const SizedBox(height: 24),
              
              _buildClearButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.mutedGray)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compression Quality', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.borderGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _compressionQuality,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['Low', 'Medium', 'High'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _setCompressionQuality(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primaryNavy)),
          Text(value, style: const TextStyle(fontSize: 16, color: AppColors.mutedGray, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStoragePathTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'History Folder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          Text(
            _outputDirectory,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedGray),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _showOutputDirectoryDialog,
                  child: const Text('Change Folder'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetOutputDirectory,
                  child: const Text('Use Default'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return _AnimatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Clear History', style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('Are you sure you want to clear all compression history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGray)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearHistory();
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text('Clear All History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
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
