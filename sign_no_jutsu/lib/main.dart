import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(SignNoJutsuApp(cameras: cameras));
}

class SignNoJutsuApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const SignNoJutsuApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign No Jutsu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SignLanguageMenu(cameras: cameras),
    );
  }
}

class SignLanguageMenu extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SignLanguageMenu({Key? key, required this.cameras}) : super(key: key);

  @override
  State<SignLanguageMenu> createState() => _SignLanguageMenuState();
}

class _SignLanguageMenuState extends State<SignLanguageMenu> {
  final List<PredictionRecord> _history = [];

  void _addToHistory(PredictionRecord record) {
    setState(() {
      _history.add(record);
    });
  }

  void _removeFromHistory(String imagePath) {
    setState(() {
      _history.removeWhere((record) => record.imagePath == imagePath);
      File(imagePath).delete();
    });
  }

  void _openCamera(BuildContext context, String language) {
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          camera: frontCamera,
          language: language,
          onResult: _addToHistory),
      ),
    );
  }

  void _showOptions(BuildContext context, String language) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Qué deseas hacer con $language?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Usar cámara'),
              onPressed: () {
                Navigator.pop(context);
                _openCamera(context, language);
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Seleccionar desde galería'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalleryScreen(
                        language: language, onResult: _addToHistory),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.history),
              label: Text('Ver historial'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(
                        history: _history, onDelete: _removeFromHistory),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Selecciona un lenguaje de señas')),
      body: ListView(padding: EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            title: Text('Lengua de Señas Americana (ASL)'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showOptions(context, 'ASL'),
          ),
        ),
      ]),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String language;
  final Function(PredictionRecord) onResult;

  const CameraScreen(
      {Key? key,
      required this.camera,
      required this.language,
      required this.onResult})
      : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;

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

  Future<void> _takePictureAndPredict() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _initializeControllerFuture;
      final XFile file = await _controller.takePicture();
      final result = await _sendToRoboflow(File(file.path));
      
      final directory = await getApplicationDocumentsDirectory();
      final newImagePath = path.join(
          directory.path, 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(file.path).copy(newImagePath);

      final record = PredictionRecord(
        imagePath: newImagePath,
        prediction: result['class'],
        confidence: result['confidence'],
      );

      widget.onResult(record);
      
      _showPrediction(result);
    } catch (e) {
      _showPrediction({'class': 'Error', 'confidence': 0.0, 'message': e.toString()});
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, dynamic>> _sendToRoboflow(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse(
      'https://serverless.roboflow.com/rdsl/1?api_key=fYRVd9ZCSEXpM8aJqHMI&name=test.jpg',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: base64Image,
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        return {
          'class': data['predictions'][0]['class'],
          'confidence': (data['predictions'][0]['confidence'] as num).toDouble()
        };
      }
      return {'class': 'No prediction', 'confidence': 0.0};
    }
    return {'class': 'API Error', 'confidence': 0.0};
  }

  void _showPrediction(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Predicción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Letra: ${result['class']}'),
            Text('Confianza: ${(result['confidence'] * 100).toStringAsFixed(2)}%'),
            if (result['message'] != null) Text(result['message']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cámara - ${widget.language}')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(children: [
              CameraPreview(_controller),
              if (_isProcessing) Center(child: CircularProgressIndicator()),
            ]);
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePictureAndPredict,
        child: Icon(Icons.camera),
      ),
    );
  }
}

class PredictionRecord {
  final String imagePath;
  final String prediction;
  final double confidence;

  PredictionRecord({
    required this.imagePath,
    required this.prediction,
    required this.confidence,
  });
}

class HistoryScreen extends StatefulWidget {
  final List<PredictionRecord> history;
  final Function(String) onDelete;

  const HistoryScreen({
    required this.history, 
    required this.onDelete, 
    Key? key
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: ListView.builder(
        itemCount: widget.history.length,
        itemBuilder: (context, index) {
          final record = widget.history[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.file(
                File(record.imagePath),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text('Letra: ${record.prediction}'),
              subtitle: Text('Confianza: ${(record.confidence * 100).toStringAsFixed(2)}%'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  widget.onDelete(record.imagePath);
                  setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
class GalleryScreen extends StatefulWidget {
  final String language;
  final Function(PredictionRecord) onResult;

  const GalleryScreen({
    Key? key, 
    required this.language, 
    required this.onResult
  }) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  File? _selectedImage;
  String? _predictedClass;
  double? _confidence;

  Future<void> _pickAndPredict() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageFile = File(picked.path);
    final result = await _sendToRoboflow(imageFile);

    final directory = await getApplicationDocumentsDirectory();
    final newImagePath = path.join(
      directory.path, 
      'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg'
    );
    await imageFile.copy(newImagePath);

    final record = PredictionRecord(
      imagePath: newImagePath,
      prediction: result['class'],
      confidence: result['confidence'],
    );

    widget.onResult(record); // Uso correcto de widget.onResult

    setState(() { // Uso correcto de setState
      _selectedImage = File(newImagePath);
      _predictedClass = result['class'];
      _confidence = result['confidence'];
    });
  }

  Future<Map<String, dynamic>> _sendToRoboflow(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse(
      'https://serverless.roboflow.com/rdsl/1?api_key=fYRVd9ZCSEXpM8aJqHMI&&name=test.jpg',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: base64Image,
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        return {
          'class': data['predictions'][0]['class'],
          'confidence': (data['predictions'][0]['confidence'] as num).toDouble()
        };
      }
      return {'class': 'No prediction', 'confidence': 0.0};
    }
    return {'class': 'API Error', 'confidence': 0.0};

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Galería - ${widget.language}')), // Uso correcto de widget.language
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              Image.file(_selectedImage!, height: 200),
              const SizedBox(height: 20),
              Text('Predicción: $_predictedClass'),
              Text('Confianza: ${(_confidence! * 100).toStringAsFixed(2)}%'),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _pickAndPredict,
              child: const Text('Seleccionar imagen de la galería'),
            ),
          ],
        ),
      ),
    );
  }
}