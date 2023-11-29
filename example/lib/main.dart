import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Scalable OCR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Scalable OCR'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String text = "";
  final StreamController<String> controller = StreamController<String>();

  void setText(value) {
    controller.add(value);
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          children: [
            ScalableOCR(
              paintboxCustom: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4.0
                ..color = Colors.blue,
              boxLeftOff: 5,
              boxBottomOff: 2.5,
              boxRightOff: 5,
              boxTopOff: 2.5,
              centerRadius: const Radius.circular(8.0),
              boxHeight: MediaQuery.of(context).size.height / 3,
              getRawData: (value) {
                inspect(value);
              },
              getScannedText: (value) {
                setText(value);
              },
              cameraMarginColor: const Color(0xCC000000),
            ),
            StreamBuilder<String>(
              stream: controller.stream,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                return Text(
                  snapshot.data != null ? snapshot.data! : "",
                  style: const TextStyle(color: Colors.white),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
