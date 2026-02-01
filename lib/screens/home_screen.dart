import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware, SingleTickerProviderStateMixin {
  File? _selectedImage;
  String? _originalImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route.settings.name == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedImage = null;
            _originalImagePath = null;
          });
          _animationController.forward(from: 0);
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        try {
          final originalPath = await StorageService.copyOriginalImage(pickedFile.path);
          
          setState(() {
            _selectedImage = File(originalPath);
            _originalImagePath = originalPath;
            _isLoading = false;
          });
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving image: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startCompression() {
    if (_selectedImage != null && _originalImagePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressScreen(
            imagePath: _originalImagePath!,
          ),
        ),
      ).then((shouldClearImage) {
        if (shouldClearImage == true && mounted) {
          setState(() {
            _selectedImage = null;
            _originalImagePath = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('JPEG-Lite Compressor', 
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        _buildImagePreview(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.compress, size: 48, color: AppColors.accentBlue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to JPEG-Lite',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Learn how JPEG compression works with interactive visualization',
            style: TextStyle(fontSize: 15, color: AppColors.mutedGray, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _selectedImage == null ? AppColors.backgroundGradient : null,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5), width: 2),
        boxShadow: _selectedImage != null ? AppColors.cardShadow : null,
        color: Colors.white,
      ),
      child: _selectedImage == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 72, color: AppColors.mutedGray.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No image selected', 
                    style: TextStyle(fontSize: 16, color: AppColors.mutedGray, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: _selectedImage == null
          ? [
              _buildModernButton(
                label: 'Take Photo',
                icon: Icons.camera_alt_rounded,
                gradient: AppColors.primaryGradient,
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              _buildModernButton(
                label: 'Choose from Gallery',
                icon: Icons.photo_library_rounded,
                gradient: AppColors.accentGradient,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ]
          : [
              _buildModernButton(
                label: 'Change Image',
                icon: Icons.swap_horiz_rounded,
                gradient: AppColors.accentGradient,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              _buildModernButton(
                label: 'Start Compression',
                icon: Icons.compress,
                gradient: AppColors.successGradient,
                onPressed: _startCompression,
              ),
            ],
    );
  }

  Widget _buildModernButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return _AnimatedButton(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.buttonShadow,
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
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
