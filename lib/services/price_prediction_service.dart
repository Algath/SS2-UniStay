import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:unistay/models/room.dart';

/// Service for predicting property prices using TensorFlow Lite model
class PricePredictionService {
  static final PricePredictionService _instance = PricePredictionService._internal();
  factory PricePredictionService() => _instance;
  PricePredictionService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Initialize the TensorFlow Lite interpreter
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Try loading from assets folder first, then fallback to root assets
      try {
        _interpreter = await Interpreter.fromAsset('ss2_unistay_price.tflite');
      } catch (_) {
        _interpreter = await Interpreter.fromAsset('assets/ss2_unistay_price.tflite');
      }

      if (_interpreter != null) {
        _isInitialized = true;
        return true;
      }
    } catch (e) {
      print('Failed to initialize price prediction model: $e');
    }

    return false;
  }

  /// Predict price for a given room
  /// Returns null if prediction fails or model is not available
  Future<double?> predictPrice(Room room) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      final features = _extractFeatures(room);
      return _runInference(features);
    } catch (e) {
      print('Price prediction error: $e');
      return null;
    }
  }

  /// Extract features from room data for ML model
  List<double> _extractFeatures(Room room) {
    // Parse postal code to numeric value (remove non-digits)
    final postal = double.tryParse(
        room.postcode.replaceAll(RegExp('[^0-9]'), '')
    ) ?? 0.0;

    // Basic room properties
    final surface = room.sizeSqm.toDouble();
    final numRooms = room.rooms.toDouble();
    final proxim = 0.0; // Future: distance to campus could be added here

    // Property type encoding (one-hot)
    final isEntire = room.type == 'whole';
    final isRoom = room.type == 'room';

    // Boolean features
    final furnished = room.furnished;
    final wifi = room.amenities.contains('Internet');
    final carPark = room.amenities.contains('Parking');

    // Feature vector matching the model's expected input
    return [
      postal,
      surface,
      numRooms,
      proxim,
      // Property type (one-hot encoded)
      isEntire ? 1.0 : 0.0,
      isRoom ? 1.0 : 0.0,
      // Furnished (binary encoded)
      furnished ? 0.0 : 1.0,  // Not furnished
      furnished ? 1.0 : 0.0,  // Furnished
      // WiFi (binary encoded)
      wifi ? 0.0 : 1.0,       // No WiFi
      wifi ? 1.0 : 0.0,       // Has WiFi
      // Parking (binary encoded)
      carPark ? 0.0 : 1.0,    // No parking
      carPark ? 1.0 : 0.0,    // Has parking
    ];
  }

  /// Run inference using the TensorFlow Lite model
  double? _runInference(List<double> features) {
    if (_interpreter == null) return null;

    try {
      // Prepare input tensor
      final input = [features];

      // Prepare output tensor
      final output = List.filled(1, 0.0).reshape([1, 1]);

      // Run inference
      _interpreter!.run(input, output);

      // Extract prediction
      final prediction = (output[0][0] as num).toDouble();

      // Validate prediction result
      if (prediction.isNaN || prediction.isInfinite) {
        return null;
      }

      return prediction;
    } catch (e) {
      print('Inference error: $e');
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  /// Check if the service is ready for predictions
  bool get isReady => _isInitialized && _interpreter != null;

  /// Get model input shape information (for debugging)
  List<List<int>>? get inputShape => _interpreter?.getInputTensors().map((t) => t.shape).toList();

  /// Get model output shape information (for debugging)
  List<List<int>>? get outputShape => _interpreter?.getOutputTensors().map((t) => t.shape).toList();
}