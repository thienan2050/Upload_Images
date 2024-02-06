import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
      appBar: AppBar(title: const Text('Take a picture')),
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
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    print(imagePath);
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: FutureBuilder(
        future: uploadImage(File(imagePath)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final Url = snapshot.data as String?;
              final imageUrl = snapshot.data as String?;
              if (imageUrl != null ) {
                return Image.network(imageUrl);
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
  Future<String?>uploadImage(File imageFile)async{
    var request=http.MultipartRequest(
      'POST',
      Uri.parse('https://thienanbui0901.pythonanywhere.com/upload'),
    );
    request.files.add(http.MultipartFile(
      'file',
      imageFile.readAsBytes().asStream(),
      imageFile.lengthSync(),
      filename:basename(imagePath),
    ));
    try{
      var response=await request.send();
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
      return 'https://thienanbui0901.pythonanywhere.com/processed_images/processed_'+basename(imagePath);
    }catch(e){
      print('Error uploading image:$e');
      return null;
    }
  }
}
