import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

String ImageRootPath = '/storage/emulated/0/HNMG/Images';
String AoImagePath = '/storage/emulated/0/HNMG/Images/Ao';
String QuanImagePath = '/storage/emulated/0/HNMG/Images/Quan';
String PKImagePath = '/storage/emulated/0/HNMG/Images/PK';

late CameraDescription firstCamera;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void createAppFolder() async {
  String appFolderPath = '/storage/emulated/0';
  String yourFolderName =
      "HNMG/Images/Ao"; // Thay thế bằng tên thư mục bạn muốn tạo

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

  yourFolderName = "HNMG/Images/Quan"; // Thay thế bằng tên thư mục bạn muốn tạo

  folderPath = '$appFolderPath/$yourFolderName';
  print(folderPath);

  // Kiểm tra xem thư mục đã tồn tại hay chưa
  if (!await Directory(folderPath).exists()) {
    // Nếu chưa tồn tại, hãy tạo mới
    await Directory(folderPath).create(recursive: true);
    print('App Folder created: $folderPath');
  } else {
    print('App Folder already exists: $folderPath');
  }

  yourFolderName = "HNMG/Images/PK"; // Thay thế bằng tên thư mục bạn muốn tạo

  folderPath = '$appFolderPath/$yourFolderName';
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

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đầm này xinh quáaa'),
      ),
      body: Center(
        child: Text('Your Content Here'),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 20, // Chiều sâu
        shape: CircularNotchedRectangle(), // Hình dạng đặc biệt
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.collections, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Display()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.photo_camera, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakePictureScreen(
                      camera: firstCamera,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CaptureImagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chụp hình'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Trở về màn hình trước đó
          },
        ),
      ),
      body: Center(
        child: Text('This is Capture Image Page'),
      ),
    );
  }
}

class DisplayImagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hiển thị ảnh'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Trở về màn hình trước đó
          },
        ),
      ),
      body: Center(
        child: Text('This is Display Images Page'),
      ),
    );
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  createAppFolder();
  firstCamera = cameras.first;
  print(firstCamera);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: MyHomePage(),
    ),
  );
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
        child: const Icon(Icons.add_a_photo),
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
  bool _triggerReBuild = false;
  var image = Image(
    image: NetworkImage(
        'https://example.com/your_image.png'), // URL của ảnh từ internet
    width: 200, // Chiều rộng (nếu cần)
    height: 100, // Chiều cao (nếu cần)
    fit: BoxFit.cover, // Cách ảnh sẽ được hiển thị (nếu cần)
  );
  @override
  void initState() {
    super.initState();
    _processImage();
    print('đã xử lý xong hình ảnhhhhhhhhhhhhhhhhhhhh');
  }

  Future<void> _processImage() async {
    uploadImageNoAsync(File(widget.imagePath));
    await Future.delayed(Duration(seconds: 2));
    _imageUrl =
        'https://thienanbui0901.pythonanywhere.com/processed_images/processed_' +
            basename(widget.imagePath);
    //await Future.delayed(Duration(seconds: 2));
    setState(() {
      _triggerReBuild = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build lạiiiiiiiiiiiiiiiiiiiiiiiiii');

    if (_triggerReBuild == false) {
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
                  // Gọi hàm lưu hình ảnh
                  await saveImageToDevice(_imageUrl);
                  // Hiển thị pop-up thông báo
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Thông báo'),
                        content: Text('Hình ảnh đã được lưu.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Đóng'),
                          ),
                        ],
                      );
                    },
                  );
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
    if (isAo == true) {
      imagePath = AoImagePath;
    } else if (isQuan == true) {
      imagePath = QuanImagePath;
    } else {
      imagePath = PKImagePath;
    }
    imagePath = '$imagePath/${basename(imageUrl)}';
    final imageFile = File(imagePath);

    await imageFile.writeAsBytes(bytes);

    print('Image saved at: $imagePath');
  }
}

//=========================================================================================
var Clothes = [];

var Ao = [];
var Quan = [];
var PK = [];

class Display extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> aos = listFilesInDirectory(AoImagePath);
    List<String> quans = listFilesInDirectory(QuanImagePath);
    List<String> PKs = listFilesInDirectory(PKImagePath);
    if (Clothes.isEmpty == false) {
      Clothes.clear();
    }
    Clothes.add(aos);
    Clothes.add(quans);
    Clothes.add(PKs);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hôm nay mặc gì ?'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 1.0),
        itemCount: Clothes.length, // Số lượng hàng bạn muốn hiển thị
        addAutomaticKeepAlives: true,
        itemBuilder: (BuildContext context, int rowIndex) {
          return Column(
            children: [
              _buildCarousel(context, rowIndex),
              SizedBox(height: 2.0), // Khoảng cách giữa các hàng
            ],
          );
        },
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildCarousel(BuildContext context, int carouselIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          // you may want to use an aspect ratio here for tablet support
          height: 200.0,
          child: Swiper(
            itemBuilder: (context, index) {
              return _buildCarouselItem(context, carouselIndex, index);
            },
            itemCount: Clothes[carouselIndex].length,
            pagination: SwiperCustomPagination(
              builder: (BuildContext context, SwiperPluginConfig config) {
                // Hiển thị số hiện tại và tổng số mục
                return Container(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.all(10.0),
                  padding: EdgeInsets.only(
                      top: 10.0), // Di chuyển số xuống dưới 10 pixels
                  child: Text(
                    "${config.activeIndex + 1}/${config.itemCount}",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16, // Đặt kích thước của số
                      fontWeight: FontWeight.bold, // In đậm chữ
                    ),
                  ),
                );
              },
            ),
            //control: const SwiperControl(color: Colors.black),
            itemWidth: 300.0,
            itemHeight: 400.0,
            layout: SwiperLayout.DEFAULT,
          ),
        )
      ],
    );
  }

  Widget _buildCarouselItem(
      BuildContext context, int carouselIndex, int itemIndex) {
    print('Row thứ ? $carouselIndex');
    print('item trong cột thứ = $itemIndex');
    String imagePath = Clothes[carouselIndex][itemIndex];
    File imageFile = File(imagePath);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.0),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(imageFile),
            fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }

  List<String> listFilesInDirectory(String directoryPath) {
    Directory directory = Directory(directoryPath);
    List<String> fileList = [];
    if (directory.existsSync()) {
      fileList = directory.listSync().map((file) => file.path).toList();
    }
    return fileList;
  }
}
