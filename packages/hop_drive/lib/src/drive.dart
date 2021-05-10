import 'dart:typed_data';
import 'package:hop_init/hop_init.dart' as init;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'signer.dart';
import 'bucket.dart';

Future<Uint8List> loadImage(path) async {
  return (await rootBundle.load(path)).buffer.asUint8List();
}

class HopDrive {
  init.Project project;
  HopDriveClient client;
  Signer signer;
  static final HopDrive instance = HopDrive._internal();
  factory HopDrive() => instance;
  HopDrive._internal() {
    if (client == null) {
      project = init.project;
      signer = Signer(
        host: "drive.hopcolony.io",
        accessKey: project.config.project,
        secretKey: project.config.token,
      );
      client = HopDriveClient(
        project: init.project,
        signer: signer,
      );
    }
  }

  BucketReference bucket(bucket) => BucketReference(client, bucket);

  Future<List<Bucket>> get() async {
    List<Bucket> buckets = [];
    try {
      http.Response response = await client.get("/");
      final document = XmlDocument.parse(await response.body);
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
  init.Project project;
  final String host = "drive.hopcolony.io";
  final int port = 443;
  String identity, _baseUrl;
  final Signer signer;
  final http.Client client = http.Client();

  String get baseUrl => _baseUrl;

  HopDriveClient({init.Project project, this.signer})
      : project = project,
        identity = project.config.identity {
    _baseUrl = "https://$host:$port";
  }

  Future<http.Response> get(String path) async {
    SignDetails signDetails = signer.sign("GET", path);
    final response = await client.get(
      Uri.parse("$_baseUrl/$identity$path"),
      headers: Map<String, String>.from(signDetails.headers),
    );
    if (response.statusCode >= 400) throw Exception(response.body);
    return response;
  }

  Future<http.Response> put(String path, {Uint8List bodyBytes}) async {
    bodyBytes = bodyBytes ?? Uint8List(0);
    SignDetails signDetails = signer.sign("PUT", path, bodyBytes: bodyBytes);
    signDetails.headers["contentLengthHeader"] = bodyBytes.length.toString();

    final response = await client.put(
      Uri.parse("$_baseUrl/$identity$path"),
      headers: Map<String, String>.from(signDetails.headers),
      body: bodyBytes,
    );
    if (response.statusCode >= 400) throw Exception(response.body);
    return response;
  }

  Future<http.Response> delete(String path) async {
    SignDetails signDetails = signer.sign("DELETE", path);
    final response = await client.delete(
      Uri.parse("$_baseUrl/$identity$path"),
      headers: Map<String, String>.from(signDetails.headers),
    );
    if (response.statusCode >= 400) throw Exception(response.body);
    return response;
  }
}
