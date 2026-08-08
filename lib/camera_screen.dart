import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'currency_converter.dart';
import 'ar_overlay.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;
  List<OverlayText> _overlayTexts = [];
  Size? _imageSize;
  CameraDescription? _camera;

  CurrencyInfo _sourceCurrency = CurrencyConverter.currencies['USD']!;
  CurrencyInfo _targetCurrency = CurrencyConverter.currencies['IDR']!;
  bool _isStrictMode = true;
  double _customRate = 16000.0;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _updateDefaultRate();
    _fetchLiveRates();
    _initializeCamera();
  }

  Future<void> _fetchLiveRates() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        setState(() {
          for (var currency in CurrencyConverter.currencies.values) {
             if (rates.containsKey(currency.code)) {
               currency.rateToUsd = (rates[currency.code] as num).toDouble();
             }
          }
          _updateDefaultRate(); 
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch live rates: $e");
    }
  }

  static final Map<String, double> _savedRates = {};

  void _swapCurrencies() {
    setState(() {
      final temp = _sourceCurrency;
      _sourceCurrency = _targetCurrency;
      _targetCurrency = temp;
      _updateDefaultRate();
    });
  }

  void _updateDefaultRate() {
    setState(() {
      final pairKey = '${_sourceCurrency.code}_${_targetCurrency.code}';

      if (_savedRates.containsKey(pairKey)) {
        _customRate = _savedRates[pairKey]!;
      } else {

        _customRate = _targetCurrency.rateToUsd / _sourceCurrency.rateToUsd;
      }
    });
  }

  Future<void> _showEditRateDialog() async {
    final TextEditingController controller = TextEditingController(text: _customRate.toStringAsFixed(4));

    setState(() => _isDialogOpen = true);
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Edit Exchange Rate", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "1 ${_sourceCurrency.code} = ? ${_targetCurrency.code}",
              labelStyle: const TextStyle(color: Colors.greenAccent),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  final pairKey = '${_sourceCurrency.code}_${_targetCurrency.code}';
                  _savedRates.remove(pairKey);
                  _customRate = _targetCurrency.rateToUsd / _sourceCurrency.rateToUsd;
                });
                Navigator.pop(context);
              },
              child: const Text("Reset Default", style: TextStyle(color: Colors.orangeAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final newRate = double.tryParse(controller.text);
                if (newRate != null && newRate > 0) {
                  setState(() {
                    _customRate = newRate;

                    final pairKey = '${_sourceCurrency.code}_${_targetCurrency.code}';
                    _savedRates[pairKey] = newRate;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      }
    );

    setState(() => _isDialogOpen = false);
    _controller?.startImageStream((image) => _processImage(image, _camera!));
  }

  Future<void> _showCurrencyPicker(bool isSource) async {
    String searchQuery = '';
    final topCodes = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'IDR'];

    setState(() => _isDialogOpen = true);
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            var list = CurrencyConverter.currencies.values.toList();
            if (searchQuery.isNotEmpty) {
              list = list.where((c) => c.code.toLowerCase().contains(searchQuery) || c.name.toLowerCase().contains(searchQuery)).toList();
            } else {
              list.sort((a, b) {
                final aTop = topCodes.contains(a.code);
                final bTop = topCodes.contains(b.code);
                if (aTop && !bTop) return -1;
                if (!aTop && bTop) return 1;
                return a.name.compareTo(b.name);
              });
            }

            return Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(isSource ? "Select Source Currency" : "Select Target Currency", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search country or currency...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black54,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                searchQuery = val.toLowerCase();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final currency = list[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: Text(currency.symbol, style: TextStyle(color: isSource ? Colors.white : Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(currency.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(currency.name, style: const TextStyle(color: Colors.white54)),
                            onTap: () {
                              setState(() {
                                if (isSource) {
                                  _sourceCurrency = currency;
                                } else {
                                  _targetCurrency = currency;
                                }
                                _updateDefaultRate();
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );

    setState(() => _isDialogOpen = false);
    _controller?.startImageStream((image) => _processImage(image, _camera!));
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.nv21 
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() {});
    _controller!.startImageStream((CameraImage image) {
      _processImage(image, _camera!);
    });
  }

  Future<void> _processImage(CameraImage image, CameraDescription camera) async {

    if (_isProcessing || _isDialogOpen) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      if (inputImage.metadata != null) {
        final rotation = inputImage.metadata!.rotation;
        final isRotated = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;

        _imageSize = isRotated
            ? Size(inputImage.metadata!.size.height, inputImage.metadata!.size.width)
            : Size(inputImage.metadata!.size.width, inputImage.metadata!.size.height);
      } else {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final List<OverlayText> newOverlays = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {

          final converted = CurrencyConverter.convertPrice(
            line.text, 
            _sourceCurrency, 
            _targetCurrency,
            _customRate,
            _isStrictMode,
          );
          if (converted != null) {
            newOverlays.add(OverlayText(line.boundingBox, converted));
          }
        }
      }

      if (mounted) {
        setState(() {
          _overlayTexts = newOverlays;
        });
      }
    } catch (e) {
      print("ERROR PROCESSING IMAGE: \$e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {

    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final bytes = image.planes.fold(
      <int>[],
      (List<int> previousValue, element) => previousValue..addAll(element.bytes),
    );

    return InputImage.fromBytes(
      bytes: Uint8List.fromList(bytes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          CameraPreview(_controller!),

          if (_imageSize != null)
            CustomPaint(
              painter: ArOverlayPainter(_overlayTexts, _imageSize!),
            ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  GestureDetector(
                    onTap: () => _showCurrencyPicker(true),
                    child: Row(
                      children: [
                        Text(_sourceCurrency.code, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
                    onPressed: _swapCurrencies,
                  ),

                  GestureDetector(
                    onTap: () => _showCurrencyPicker(false),
                    child: Row(
                      children: [
                        Text(_targetCurrency.code, style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _showEditRateDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Rate: 1 ${_sourceCurrency.code} = ${_customRate.toStringAsFixed(2)} ${_targetCurrency.code}",
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Require Currency Symbol",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _isStrictMode,
                    activeColor: Colors.greenAccent,
                    onChanged: (value) {
                      setState(() {
                        _isStrictMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

