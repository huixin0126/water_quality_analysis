import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:water_quality_analysis/main.dart';
import 'water_turbidity_result_page.dart';
import '../class/water_quality_model.dart';

class WaterTurbidityPage extends StatefulWidget {
  const WaterTurbidityPage({Key? key}) : super(key: key);

  @override
  State<WaterTurbidityPage> createState() => _WaterTurbidityPageState();
}

class _WaterTurbidityPageState extends State<WaterTurbidityPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _preloadModel();
  }

  Future<void> _preloadModel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final model = WaterQualityModel();
      await model.loadModel();
    } catch (e) {
      debugPrint('Error preloading model: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _navigateToAnalysisResult() {
    if (_imageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaterTurbidityResultPage(imageFile: _imageFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Turbidity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Water Turbidity (Image)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Image upload container
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "It's empty here",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showImageSourceOptions,
                            icon: const Icon(Icons.add),
                            label: const Text('Upload new'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(150, 36),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions or Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How to take a good water turbidity photo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Use a clear glass or container\n'
                    '• Ensure good lighting\n'
                    '• Place against a white background\n'
                    '• Avoid reflections or shadows',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Model loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Initializing analysis model...'),
                  ],
                ),
              ),
            
            // Analyze button
            ElevatedButton(
              onPressed: _imageFile != null && !_isLoading
                  ? _navigateToAnalysisResult
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Analyze Water',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}