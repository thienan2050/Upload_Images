import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';


Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);
  final CameraDescription camera;
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
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
      appBar: AppBar(title: const Text('Chụp ảnh quần áo')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!mounted) return;
            // Đợi 3 giây trước khi hiển thị hình ảnh
            await Future.delayed(const Duration(seconds: 0));
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}
class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool _isChecked = false; // Trạng thái ban đầu của checkbox
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final aspectRatio = size.width / size.height;
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: FutureBuilder(
        future: uploadImage(File(widget.imagePath)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final Url = snapshot.data as String?;
              final imageUrl = snapshot.data as String?;
              if (imageUrl != null) {
                return Center(
                  child: Column(
                    children: [
                      SizedBox(
                        /* To do: hiển thị quần áo với scale bằng với bố cục layout là 3 hay 4 items. */
                        width: size.width / 1.5,
                        height: size.height / 1.5,
                        child: Image.network(imageUrl),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await saveImageToDevice(imageUrl);
                        },
                        child: Text('Save Image'),
                      ),
                      Checkbox(
                        value: _isChecked,
                        onChanged: (value) {
                          setState(() {
                            _isChecked = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return const Text('Invalid data received');
              }
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<String?> uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://thienanbui0901.pythonanywhere.com/upload'),
    );
    request.files.add(http.MultipartFile(
      'file',
      imageFile.readAsBytes().asStream(),
      imageFile.lengthSync(),
      filename: basename(widget.imagePath),
    ));
    try {
      var response = await request.send();
      /* Currently, Server does not return status Code, so skip now.
      It's always success.
      if(response.statusCode==200){
        print('Image uploaded successfully');
        return 'https://thienanbui0901.pythonanywhere.com/.../processed...;
        //return 'https://thienanbui0901.pythonanywhere.com/.../processed...';
      }else{
        print('Failed to upload image. Statuscode:${response.statusCode}');
        return null;
      }
      */
      return 'https://thienanbui0901.pythonanywhere.com/processed_images/processed_' +
          basename(widget.imagePath);
    } catch (e) {
      print('Error uploading image:$e');
      return null;
    }
  }
}

Future<void> saveImageToDevice(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  final bytes = response.bodyBytes;
  print('saveImageToDevie');

  //final directory = await getExternalStorageDirectory();
  //final imagePath = '${directory!.path}/image.png';
  //final imageFile = File(imagePath);

  //await imageFile.writeAsBytes(bytes);
  //print('Image saved at: $imagePath');
}
