import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hop_drive/hop_drive.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:image_picker_web/image_picker_web.dart';

void main() async {
  await init.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final drive = HopDrive.instance;

  @override
  void initState() {
    super.initState();

    print(drive.bucket("demo").object("idealista.jpg").getPresigned());

    drive.get().then((buckets) => buckets.forEach((bucket) {
          print(bucket.name);
        }));
  }

  void putImage() async {
    Uint8List bytesFromPicker =
        await ImagePickerWeb.getImage(outputType: ImageType.bytes);

    print(await drive
        .bucket("profile")
        .object("examplePut@gmail.com")
        .put(bytesFromPicker));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
            child: TextButton(
          onPressed: putImage,
          child: Text("Put Image"),
        )),
      ),
    );
  }
}
