import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PricePredictionWidget extends StatefulWidget {
  final TextEditingController postalCodeController;
  final TextEditingController surfaceController;
  final TextEditingController numRoomsController;
  final TextEditingController predictionController; // affichage du résultat
  final double proximValue; // distance calculée en externe

  const PricePredictionWidget({
    super.key,
    required this.postalCodeController,
    required this.surfaceController,
    required this.numRoomsController,
    required this.predictionController,
    required this.proximValue,
  });

  @override
  State<PricePredictionWidget> createState() => _PricePredictionWidgetState();
}

class _PricePredictionWidgetState extends State<PricePredictionWidget> {
  bool isFurnished = false;
  bool wifiIncl = false;
  bool carPark = false;
  String? selectedType;

  Interpreter? interpreter;

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/ss2_unistay_price.tflite').then((value) {
      debugPrint("✅ Modèle trouvé (${value.lengthInBytes} bytes)");
    }).catchError((e) {
      debugPrint("❌ Erreur chargement asset: $e");
    });
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/ss2_unistay_price.tflite');
      debugPrint("✅ Modèle chargé !");
    } catch (e) {
      debugPrint("❌ Erreur chargement modèle: $e");
    }
  }

  void performPrediction() {
    if (interpreter == null) {
      widget.predictionController.text = "⚠️ Modèle pas encore chargé";
      return;
    }

    try {
      final postalCode = int.tryParse(widget.postalCodeController.text) ?? 0;
      final surface = double.tryParse(widget.surfaceController.text) ?? 0.0;
      final numRooms = int.tryParse(widget.numRoomsController.text) ?? 0;
      final proxim = widget.proximValue;

      if (selectedType == null) {
        widget.predictionController.text = "⚠️ Choisis un type !";
        return;
      }

      final features = <double>[
        postalCode.toDouble(),
        surface,
        numRooms.toDouble(),
        proxim,
        selectedType == "entire_home" ? 1.0 : 0.0,
        selectedType == "room" ? 1.0 : 0.0,
        isFurnished ? 0.0 : 1.0,
        isFurnished ? 1.0 : 0.0,
        wifiIncl ? 0.0 : 1.0,
        wifiIncl ? 1.0 : 0.0,
        carPark ? 0.0 : 1.0,
        carPark ? 1.0 : 0.0,
      ];

      final input = [features];
      final output = List.filled(1, 0.0).reshape([1, 1]);

      interpreter!.run(input, output);

      final price = output[0][0];
      widget.predictionController.text = "CHF ${price.toStringAsFixed(0)}.-";
    } catch (e) {
      widget.predictionController.text = "❌ Erreur prédiction";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Type"),
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "room", child: Text("Room")),
                DropdownMenuItem(value: "entire_home", child: Text("Entire Home")),
              ],
              onChanged: (value) => setState(() => selectedType = value),
            ),
            SwitchListTile(
              title: const Text("Mobilier inclus"),
              value: isFurnished,
              onChanged: (val) => setState(() => isFurnished = val),
            ),
            SwitchListTile(
              title: const Text("Wifi inclus"),
              value: wifiIncl,
              onChanged: (val) => setState(() => wifiIncl = val),
            ),
            SwitchListTile(
              title: const Text("Place de parking"),
              value: carPark,
              onChanged: (val) => setState(() => carPark = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await loadModel();
                performPrediction();
              },
              child: const Text("Prédire"),
            ),
          ],
        ),
      ),
    );
  }
}
