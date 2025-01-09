# Flutter Scalable OCR

```
QUICK NOTE: I know I'm a bit late on issue fixes due to some private problems. 
Package is not abandoned, all PR-s are welcome and I'll try to fix everything as soon I find some free time. 
Thanks for the understanding.
```

`v2.1.1`

Flutter scalable OCR package is a wrapper around [Google ML kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition). It tackles the issue of fetching data just from part od a camera and also narowing down the camera viewport which was common problem. To see how it work in real case scenario you can check the app where it was used [Exchange Rate Scanner](https://www.erscanner.com/) and here are some gifs from example project.

<p float="left">
  <img src="https://user-images.githubusercontent.com/30495155/214034242-c9ef8046-f193-4c7b-8fed-483ccc277511.gif" width="300" />
  <img src="https://user-images.githubusercontent.com/30495155/214034570-c305c19b-3d81-4a09-8e54-f395916f065e.gif" width="300" />
</p>

## Requirements

Since thus package uses [ML Kit](https://pub.dev/packages/google_mlkit_commons) check [requirements](https://github.com/bharat-biradar/Google-Ml-Kit-plugin#requirements) before running the package in project.

## Features

Scan text from narow window of camera and not whole screen. There are two function `getScannedText` to fetch readed text as a string, or `getRawData` which returns list of `TextElement` consult [ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition) objects as from followin structure from google developer site image. Pinch and zoom should also work:

Note: Wrapper uses [Camera](https://pub.dev/packages/camera) package so you need to add perimission as in documentation.

<p float="left">
  <img src="https://developers.google.com/static/ml-kit/vision/text-recognition/images/text-structure.png" width="600" />
</p>

## Usage

Add the package to pubspec.yaml

```dart
dependencies:
  flutter_scalable_ocr: x.x.x
```

Import it

```dart
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';
```

Full examples for all three options are in `/example` folder so please take a look for working version.

Parameters:

| Parameter      |      Description      |  Default |
|--------------- |:---------------------:|---------:|
| `boxLeftOff`     |  Scalable center square left         | 4        |
| `boxBottomOff`   |  Scalable center square bottom    | 2.7      |
| `boxRightOff`    |  Scalable center square right  | 4        |
| `boxTopOff`      |  Scalable center square top   | 2.7      |
| `paintboxCustom`      |  Narrowed square in camera window  | from example|
| `boxHeight`      |  Camera Window height | from example      |
| `getScannedText`      |  Callback function that returns string |     |
| `getRawData`      |  Callback function that returns list of `TextElement`     |

Use widget:

```dart
ScalableOCR(
    paintboxCustom: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = const Color.fromARGB(153, 102, 160, 241),
    boxLeftOff: 4,
    boxBottomOff: 2.7,
    boxRightOff: 4,
    boxTopOff: 2.7,
    boxHeight: MediaQuery.of(context).size.height / 5,
    getRawData: (value) {
        inspect(value);
    },
    getScannedText: (value) {
        setText(value);
    }),
```
