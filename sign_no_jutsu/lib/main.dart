import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(const SignNoJutsuApp());
}

class SignNoJutsuApp extends StatelessWidget {
  const SignNoJutsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign No Jutsu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignLanguageMenu(),
    );
  }
}

class SignLanguageMenu extends StatelessWidget {
  const SignLanguageMenu({super.key});

  void _openCamera(BuildContext context, String language) async {
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
   (camera) => camera.lensDirection == CameraLensDirection.front,
   orElse: () => cameras.first, // Usa la primera si no hay cámara frontal
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CameraScreen(
        camera: frontCamera,
        language: language,
      ),
    ),
    );
  }

  void _showOptions(BuildContext context, String language) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Qué deseas hacer con $language?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.translate),
                label: const Text('Traductor'),
                onPressed: () {
                  Navigator.pop(context); // Cierra el modal
                  _openCamera(context, language); // Abre la cámara
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.videogame_asset),
                label: const Text('Juego'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modo juego en desarrollo')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un lenguaje de señas'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageTile(context, 'Lengua de Señas Americana (ASL)', 'ASL'),
          _buildLanguageTile(context, 'Lengua de Señas Mexicana (LSM)', 'LSM'),
          _buildLanguageTile(context, 'Lengua de Señas Británica (BSL)', 'BSL'),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String title, String code) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showOptions(context, code),
      ),
    );
  }
}


class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String language;

  const CameraScreen({super.key, required this.camera, required this.language});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cámara - ${widget.language}')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
