import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';

class DetailScreen extends StatefulWidget {
  final String imagePath;
  final ScanMode scanMode;

  const DetailScreen({@required this.imagePath, @required this.scanMode});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

enum ScanMode { PhoneNumber, Email }

class _DetailScreenState extends State<DetailScreen> {
  String _imagePath;
  TextDetector _textDetector;
  Size _imageSize;
  List<TextElement> _elements = [];

  List<String> _listEmailStrings;

  GlobalKey<ExpandableBottomSheetState> key = new GlobalKey();

  // Fetching the image size from the image file
  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  // To detect the email addresses present in an image
  void _recognizeEmails() async {
    _getImageSize(File(_imagePath));

    // Creating an InputImage object using the image path
    final inputImage = InputImage.fromFilePath(_imagePath);
    // Retrieving the RecognisedText from the InputImage
    final text = await _textDetector.processImage(inputImage);

    // Pattern of RegExp for matching a general email address
    String pattern;
    if (widget.scanMode == ScanMode.PhoneNumber) {
      pattern = r"^(\+)?(\d{1,2})?[( .-]*(\d{3})[) .-]*(\d{3,4})[ .-]?(\d{4})$";
    } else {
      pattern =
          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    }

    RegExp regEx = RegExp(pattern);

    List<String> emailStrings = [];

    // Finding and storing the text String(s) and the TextElement(s)
    for (TextBlock block in text.textBlocks) {
      for (TextLine line in block.textLines) {
        print('text: ${line.lineText}');
        if (regEx.hasMatch(line.lineText)) {
          emailStrings.add(line.lineText);
          for (TextElement element in line.textElements) {
            _elements.add(element);
          }
        }
      }
    }

    setState(() {
      _listEmailStrings = emailStrings;
    });
  }

  @override
  void initState() {
    _imagePath = widget.imagePath;
    // Initializing the text detector
    _textDetector = GoogleMlKit.vision.textDetector();
    _recognizeEmails();
    super.initState();
  }

  @override
  void dispose() {
    // Disposing the text detector when not used anymore
    _textDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              "Image Details",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: _imageSize != null
              ? ExpandableBottomSheet(
                  key: key,
                  background: Container(
                    width: double.maxFinite,
                    color: Colors.black,
                    child: CustomPaint(
                      foregroundPainter: TextDetectorPainter(
                        _imageSize,
                        _elements,
                      ),
                      child: AspectRatio(
                        aspectRatio: _imageSize.aspectRatio,
                        child: Image.file(
                          File(_imagePath),
                        ),
                      ),
                    ),
                  ),
                  expandableContent: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "Identified " +
                                  (widget.scanMode == ScanMode.Email
                                      ? 'emails'
                                      : 'phone numbers'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            child: SingleChildScrollView(
                              child: _listEmailStrings != null
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      physics: BouncingScrollPhysics(),
                                      itemCount: _listEmailStrings.length,
                                      itemBuilder: (context, index) =>
                                          _buildItem(context, index))
                                  : Container(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  persistentHeader: Container(
                    color: Colors.cyan,
                    constraints: BoxConstraints.expand(height: 80),
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: Color.fromARGB((0.25 * 255).round(), 0, 0, 0),
                        size: 80,
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
        ));
  }

  Widget _buildItem(BuildContext context, int index) {
    final String field = _listEmailStrings[index];
    if (widget.scanMode == ScanMode.Email) {
      return Container(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            field,
            style: TextStyle(fontSize: 25),
          ),
          IconButton(
              icon: Icon(Icons.email, color: Colors.red),
              onPressed: () {
                try {
                  launch("mailto:$field");
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Sorry. The email is incorrectly identified"),
                  ));
                }
              })
        ],
      ));
    }

    return Container(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          field,
          style: TextStyle(fontSize: 25),
        ),
        IconButton(
            icon: Icon(Icons.call, color: Colors.green),
            onPressed: () {
              try {
                launch("tel:$field");
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text("Sorry. The phone number is incorrectly identified"),
                ));
              }
            })
      ],
    ));
  }
}

// Helps in painting the bounding boxes around the recognized
// email addresses in the picture
class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.elements);

  final Size absoluteImageSize;
  final List<TextElement> elements;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextElement container) {
      return Rect.fromLTRB(
        container.rect.left * scaleX,
        container.rect.top * scaleY,
        container.rect.right * scaleX,
        container.rect.bottom * scaleY,
      );
    }

    double convertRadiusToSigma(double radius) {
      return radius * 0.57735 + 0.5;
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.yellow.withAlpha(125)
      ..style = PaintingStyle.fill;

    for (TextElement element in elements) {
      canvas.drawRect(scaleRect(element), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return true;
  }
}
