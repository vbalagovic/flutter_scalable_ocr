library flutter_scalable_ocr;

import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// import 'package:satya_textocr/src_path/SatyaTextKit.dart';
import './text_recognizer_painter.dart';

// import 'package:satya_textocr/satya_textocr.dart';
class ScalableOCR extends StatefulWidget {
  const ScalableOCR({
    Key? key,
    this.boxLeftOff = 4,
    this.boxRightOff = 4,
    this.boxBottomOff = 2.7,
    this.boxTopOff = 2.7,
    this.centerRadius = Radius.zero,
    this.boxHeight,
    required this.getScannedText,
    this.getRawData,
    this.paintboxCustom,
    this.cameraMarginColor,
  }) : super(key: key);

  /// Offset on recalculated image left
  final double boxLeftOff;

  /// Offset on recalculated image bottom
  final double boxBottomOff;

  /// Offset on recalculated image right
  final double boxRightOff;

  /// Offset on recalculated image top
  final double boxTopOff;

  /// Radius of center RRect
  final Radius centerRadius;

  /// Height of narowed image
  final double? boxHeight;

  /// Function to get scanned text as a string
  final Function getScannedText;

  /// Get raw data from scanned image
  final Function? getRawData;

  /// Narower box paint
  final Paint? paintboxCustom;

  /// Color of camera margin
  final Color? cameraMarginColor;

  @override
  ScalableOCRState createState() => ScalableOCRState();
}

class ScalableOCRState extends State<ScalableOCR> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final cameraPrev = GlobalKey();
  final thePainter = GlobalKey();

  final bool _canProcess = true;
  bool _isBusy = false;
  bool converting = false;
  CustomPaint? customPaint;
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  double zoomLevel = 3.0;
  double minZoomLevel = 0.0;
  double maxZoomLevel = 10.0;
  // Counting pointers (number of user fingers on screen)
  final double _minAvailableZoom = 1.0;
  final double _maxAvailableZoom = 10.0;
  double _currentScale = 3.0;
  double _baseScale = 3.0;
  double maxWidth = 0;
  double maxHeight = 0;

  @override
  void initState() {
    super.initState();
    startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _liveFeedBody();
  }

  // Body of live camera stream
  Widget _liveFeedBody() {
    final bool isNotInitializedCamera = _controller == null ||
        _controller?.value == null ||
        _controller?.value.isInitialized == false;
    if (isNotInitializedCamera) {
      return SizedBox.shrink();
    }
    const double previewAspectRatio = 0.5;
    return SizedBox(
      height: widget.boxHeight ?? MediaQuery.of(context).size.height / 5,
      child: Stack(
        key: cameraPrev,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Transform.scale(
              scale: _controller!.value.aspectRatio / previewAspectRatio,
              child: Center(
                child: CameraPreview(
                  _controller!,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      maxWidth = constraints.maxWidth;
                      maxHeight = constraints.maxHeight;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: _handleScaleUpdate,
                        onTapDown: (TapDownDetails details) =>
                            onViewFinderTap(details, constraints),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (customPaint != null)
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                maxWidth = constraints.maxWidth;
                maxHeight = constraints.maxHeight;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onTapDown: (TapDownDetails details) =>
                      onViewFinderTap(details, constraints),
                  child: customPaint!,
                );
              },
            ),
        ],
      ),
    );
  }

  // Start camera stream function
  Future startLiveFeed() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    final camera = _cameras[0];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        zoomLevel = value;
        minZoomLevel = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            log('User denied camera access.');
            break;
          default:
            log('Handle other errors.');
            break;
        }
      }
    });
  }

  // Process image from camera stream
  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = _cameras[0];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage =
        // InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
        InputImage.fromBytes(bytes: bytes, metadata: planeData);

    processImage(inputImage);
  }

  // Scale image
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  // Handle scale update
  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_controller == null) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _controller!.setZoomLevel(_currentScale);
  }

  // Focus image
  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) {
      return;
    }

    final CameraController cameraController = _controller!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  // Stop camera live stream
  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  // Process image
  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final recognizedText = await _textRecognizer.processImage(inputImage);
    final bool isImageMetadataAvailable = inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null;
    final bool isCameraContextAvailable = cameraPrev.currentContext != null;
    if (isImageMetadataAvailable && isCameraContextAvailable) {
      final RenderBox renderBox =
          cameraPrev.currentContext?.findRenderObject() as RenderBox;

      final painter = TextRecognizerPainter(
        recognizedText,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        renderBox,
        (value) {
          widget.getScannedText(value);
        },
        getRawData: (value) {
          if (widget.getRawData != null) {
            widget.getRawData!(value);
          }
        },
        widget.centerRadius,
        boxBottomOff: widget.boxBottomOff,
        boxTopOff: widget.boxTopOff,
        boxRightOff: widget.boxRightOff,
        boxLeftOff: widget.boxRightOff,
        paintboxCustom: widget.paintboxCustom,
        cameraMarginColor: widget.cameraMarginColor,
      );

      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    Future.delayed(const Duration(milliseconds: 900)).then(
      (value) {
        if (!converting) {
          _isBusy = false;
        }

        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
