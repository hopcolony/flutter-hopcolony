import 'dart:typed_data';
import 'package:hop_init/hop_init.dart' as init;
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'signer.dart';
import 'bucket.dart';

Future<Uint8List> loadImage(path) async {
  return (await rootBundle.load(path)).buffer.asUint8List();
}

class HopDrive {
  init.App app;
  HopDriveClient client;
  Signer signer;
  static final HopDrive instance = HopDrive._internal();
  factory HopDrive() => instance;
  HopDrive._internal() {
    if (client == null) {
      app = init.app;
      signer = Signer(
        host: "drive.hopcolony.io",
        accessKey: app.config.app,
        secretKey: app.config.token,
      );
      client = HopDriveClient(
        app: init.app,
        signer: signer,
      );
    }
  }

  BucketReference bucket(bucket) => BucketReference(client, bucket);

  Future<List<Bucket>> get() async {
    List<Bucket> buckets = [];
    try {
      Response response = await client.get("/");
      final document = XmlDocument.parse(await response.data);
      for (final soup in document.findAllElements("Bucket")) {
        final name = soup.findElements('Name').single.text;
        final date = soup.findElements('CreationDate').single.text;
        final creationDate = DateTime.parse(date).toLocal();
        BucketSnapshot snapshot = await bucket(name).get();
        int numObjs = 0;
        if (snapshot.success) {
          numObjs = snapshot.objects.length;
        }
        buckets.add(Bucket(name, creationDate, numObjs));
      }
    } catch (_) {}
    return buckets;
  }
}

class HopDriveClient {
  init.App app;
  final String host = "drive.hopcolony.io";
  final int port = 443;
  String identity, _baseUrl;
  final Signer signer;
  final Dio dio = Dio();

  String get baseUrl => _baseUrl;

  HopDriveClient({init.App app, this.signer})
      : app = app,
        identity = app.config.identity {
    _baseUrl = "https://$host:$port/$identity";
  }

  Future<Response> get(String path, {Options options}) async {
    options = options ?? Options();
    SignDetails signDetails = signer.sign("GET", path);
    options.headers = signDetails.headers;
    return await dio.get("$_baseUrl$path", options: options);
  }

  Future<Response> put(String path, {Uint8List bodyBytes}) async {
    bodyBytes = bodyBytes ?? Uint8List(0);
    SignDetails signDetails = signer.sign("PUT", path, bodyBytes: bodyBytes);
    signDetails.headers["contentLengthHeader"] = bodyBytes.length;
    return await dio.put(
      "$_baseUrl$path",
      options: Options(headers: signDetails.headers),
      data: Stream.fromIterable(bodyBytes.map((e) => [e])),
    );
  }

  Future<Response> delete(String path) async {
    SignDetails signDetails = signer.sign("DELETE", path);
    return await dio.delete("$_baseUrl$path",
        options: Options(headers: signDetails.headers));
  }
}