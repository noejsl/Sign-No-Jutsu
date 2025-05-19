import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:math';

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
        colorScheme: ColorScheme.light(
          primary: Color(0xFFFFB6C1),
          secondary: Color(0xFFADD8E6),
          surface: Color(0xFFFFF0F5),
          background: Color(0xFFF5F5F5),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFFB6C1),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFB6C1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: ASLMenu(cameras: cameras),
    );
  }
}

class ASLMenu extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ASLMenu({Key? key, required this.cameras}) : super(key: key);

  @override
  State<ASLMenu> createState() => _ASLMenuState();
}

class _ASLMenuState extends State<ASLMenu> {
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

  void _openLivePrediction(BuildContext context) {
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivePredictionScreen(
          camera: frontCamera,
        ),
      ),
    );
  }

  void _openGameMode(BuildContext context) {
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameModeScreen(
          camera: frontCamera,
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFF0F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opciones ASL',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF69B4),
              ),
            ),
            SizedBox(height: 20),
            _buildOptionButton(
              icon: Icons.videocam,
              label: 'Predicción en vivo',
              onPressed: () {
                Navigator.pop(context);
                _openLivePrediction(context);
              },
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              icon: Icons.photo_library,
              label: 'Seleccionar desde galería',
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalleryScreen(onResult: _addToHistory),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              icon: Icons.history,
              label: 'Ver historial',
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(
                      history: _history,
                      onDelete: _removeFromHistory,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              icon: Icons.games,
              label: 'Modo Juego',
              onPressed: () {
                Navigator.pop(context);
                _openGameMode(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label, style: TextStyle(fontSize: 18)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign No Jutsu - ASL')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/asl_logo.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 30),
            Text(
              'Lengua de Señas Americana',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF69B4)),
            ),
            SizedBox(height: 10),
            Text(
              'Aprende y practica el alfabeto ASL',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600]),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showOptions(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Comenzar',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LivePredictionScreen extends StatefulWidget {
  final CameraDescription camera;

  const LivePredictionScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _LivePredictionScreenState createState() => _LivePredictionScreenState();
}

class _LivePredictionScreenState extends State<LivePredictionScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  String _currentPrediction = "Esperando predicción...";
  double _currentConfidence = 0.0;
  Timer? _predictionTimer;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      _startPredictionLoop();
    });
  }

  void _startPredictionLoop() {
    _predictionTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) async {
      if (_isProcessing) return;
      await _predictCurrentFrame();
    });
  }

  Future<void> _predictCurrentFrame() async {
    if (!_controller.value.isInitialized || _isProcessing) return;

    if (!_isProcessing) {
      setState(() => _isProcessing = true);
    }

    try {
      final image = await _controller.takePicture();
      final imageFile = File(image.path);
      final result = await _sendToRoboflow(imageFile);

      _currentPrediction = result['class'] ?? "Sin predicción";
      _currentConfidence = result['confidence'] ?? 0.0;
      
      setState(() {});

      await imageFile.delete();
    } catch (e) {
      print("Error en predicción: $e");
      _currentPrediction = "Error";
      _currentConfidence = 0.0;
      setState(() {});
    } finally {
      if (_isProcessing) {
        setState(() => _isProcessing = false);
      }
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

  @override
  void dispose() {
    _predictionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Predicción en vivo - ASL')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _buildResultsContainer(),
        ],
      ),
    );
  }

  Widget _buildResultsContainer() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFFF0F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Predicción actual:',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontSize: 20,
              fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: Center(
              child: Text(
                _currentPrediction,
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Confianza: ${(_currentConfidence * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18),
          ),
          if (_isProcessing)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            ),
        ],
      ),
    );
  }
}

class GameModeScreen extends StatefulWidget {
  final CameraDescription camera;

  const GameModeScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  String _currentPrediction = "";
  double _currentConfidence = 0.0;
  Timer? _predictionTimer;
  String _targetLetter = "";
  bool _isCorrect = false;
  bool _showResult = false;

  final List<String> _alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 
    'T', 'U', 'V', 'W', 'X', 'Y'
  ];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      _startNewRound();
    });
  }

  void _startNewRound() {
    _predictionTimer?.cancel();
    
    setState(() {
      _targetLetter = _alphabet[Random().nextInt(_alphabet.length)];
      _isCorrect = false;
      _showResult = false;
      _currentPrediction = "";
      _currentConfidence = 0.0;
    });
    
    _startPredictionLoop();
  }

  void _startPredictionLoop() {
    _predictionTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) async {
      if (_isProcessing || _isCorrect) return;
      await _predictCurrentFrame();
    });
  }

  Future<void> _predictCurrentFrame() async {
    if (!_controller.value.isInitialized || _isProcessing || _isCorrect) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller.takePicture();
      final imageFile = File(image.path);
      final result = await _sendToRoboflow(imageFile);

      final prediction = result['class']?.toUpperCase() ?? "";
      final confidence = result['confidence'] ?? 0.0;

      if (prediction == _targetLetter.toUpperCase() && confidence > 0.5) {
        _predictionTimer?.cancel();
        setState(() {
          _isCorrect = true;
          _showResult = true;
          _currentPrediction = prediction;
          _currentConfidence = confidence;
        });
      } else {
        setState(() {
          _currentPrediction = prediction;
          _currentConfidence = confidence;
        });
      }

      await imageFile.delete();
    } catch (e) {
      print("Error en predicción: $e");
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

  @override
  void dispose() {
    _predictionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modo Juego - ASL')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      CameraPreview(_controller),
                      if (_isCorrect)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¡Correcto!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Letra: $_targetLetter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                  ),
                                ),
                                SizedBox(height: 40),
                                ElevatedButton(
                                  onPressed: _startNewRound,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    child: Text(
                                      'Siguiente Letra',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _buildGameControls(),
        ],
      ),
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFFF0F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            'Haz la letra:',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _targetLetter,
            style: TextStyle(
              color: Colors.pinkAccent,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          if (!_isCorrect) ...[
            Text(
              'Predicción: $_currentPrediction',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Confianza: ${(_currentConfidence * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
              ),
            ),
          ],
          if (_isProcessing)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            ),
        ],
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
      appBar: AppBar(title: Text('Historial ASL')),
      body: widget.history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 50, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Aún no hay predicciones',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                final record = widget.history[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(record.imagePath),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        'Letra: ${record.prediction}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Confianza: ${(record.confidence * 100).toStringAsFixed(2)}%',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.pinkAccent),
                        onPressed: () {
                          widget.onDelete(record.imagePath);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Predicción eliminada'),
                              backgroundColor: Colors.pinkAccent,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  final Function(PredictionRecord) onResult;

  const GalleryScreen({
    Key? key, 
    required this.onResult
  }) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  File? _selectedImage;
  String? _predictedClass;
  double? _confidence;
  bool _isProcessing = false;

  Future<void> _pickAndPredict() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

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

      widget.onResult(record);

      setState(() {
        _selectedImage = File(newImagePath);
        _predictedClass = result['class'];
        _confidence = result['confidence'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
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
      appBar: AppBar(title: Text('Galería ASL')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedImage != null) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _selectedImage!,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Resultado:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _predictedClass ?? '',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Confianza: ${(_confidence ?? 0 * 100).toStringAsFixed(2)}%',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ] else ...[
                Icon(
                  Icons.photo_library,
                  size: 100,
                  color: Color(0xFFFFB6C1)),
                SizedBox(height: 20),
                Text(
                  'Selecciona una imagen para analizar',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 30),
              ],
              ElevatedButton.icon(
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(Icons.image),
                label: Text(
                  _isProcessing ? 'Procesando...' : 'Seleccionar imagen',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: _isProcessing ? null : _pickAndPredict,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}