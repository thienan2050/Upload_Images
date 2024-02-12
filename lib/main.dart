import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

String ImageRootPath = '/storage/emulated/0/HNMG/Images';
String AoImagePath = '/storage/emulated/0/HNMG/Images/Ao';
String QuanImagePath = '/storage/emulated/0/HNMG/Images/Quan';
String PKImagePath = '/storage/emulated/0/HNMG/Images/PK';

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  createAppFolder();
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
        child: const Icon(Icons.camera),
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
  bool isAo = false; // Trạng thái ban đầu của checkbox
  bool isQuan = false;
  bool isPhuKien = false;
  String _imageUrl = '';
  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    uploadImageNoAsync(File(widget.imagePath));
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _imageUrl =
          'https://thienanbui0901.pythonanywhere.com/processed_images/processed_' +
              basename(widget.imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phân loại quần áo')),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      final size = MediaQuery.of(context).size;
      final aspectRatio = size.width / size.height;
      return Scaffold(
        appBar: AppBar(title: const Text('Phân loại quần áo')),
        body: Center(
          child: Column(
            children: [
              SizedBox(
                /* To do: hiển thị quần áo với scale bằng với bố cục layout là 3 hay 4 items. */
                width: size.width / 2,
                height: size.height / 2,
                child: Image.network(_imageUrl),
              ),
              ElevatedButton(
                onPressed: () async {
                  await saveImageToDevice(_imageUrl);
                },
                child: Text('Lưu thông tin'),
              ),
              Row(
                children: [
                  Text('  Áo          '),
                  Checkbox(
                    value: isAo,
                    onChanged: (value) {
                      setState(() {
                        isAo = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text('  Quần      '),
                  Checkbox(
                    value: isQuan,
                    onChanged: (value) {
                      setState(() {
                        isQuan = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text('  Phụ kiện'),
                  Checkbox(
                    value: isPhuKien,
                    onChanged: (value) {
                      setState(() {
                        isPhuKien = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<String> doNothing() async {
    return _imageUrl;
  }

  void uploadImageNoAsync(File imageFile) {
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
    request.send();
    //Future.delayed(const Duration(seconds: 10));
  }

  Future<String?> uploadImage(File imageFile) async {
    print('Requesting');
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
      _imageUrl =
          'https://thienanbui0901.pythonanywhere.com/processed_images/processed_' +
              basename(widget.imagePath);
      return 'https://thienanbui0901.pythonanywhere.com/processed_images/processed_' +
          basename(widget.imagePath);
    } catch (e) {
      print('Error uploading image:$e');
      return null;
    }
  }
  Future<void> saveImageToDevice(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;
    var imagePath;
    if (isAo == true)
    {
      imagePath = AoImagePath;
    }
    else if (isQuan == true)
      {
        imagePath = QuanImagePath;
      }
    else
      {
        imagePath = PKImagePath;
      }
    imagePath = '$imagePath/${basename(imageUrl)}';
    final imageFile = File(imagePath);

    await imageFile.writeAsBytes(bytes);
    print('Image saved at: $imagePath');
  }
}



void createAppFolder() async {
  String appFolderPath = '/storage/emulated/0';
  String yourFolderName =
      "HNMG/Images"; // Thay thế bằng tên thư mục bạn muốn tạo

  String folderPath = '$appFolderPath/$yourFolderName';
  print(folderPath);

  
  // Kiểm tra xem thư mục đã tồn tại hay chưa
  if (!await Directory(folderPath).exists()) {
    // Nếu chưa tồn tại, hãy tạo mới
    await Directory(folderPath).create(recursive: true);
    print('App Folder created: $folderPath');
  } else {
    print('App Folder already exists: $folderPath');
  }

  // Bạn có thể sử dụng đường dẫn `folderPath` để lưu trữ dữ liệu của ứng dụng.
}
