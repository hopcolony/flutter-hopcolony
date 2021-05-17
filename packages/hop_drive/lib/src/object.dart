import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'bucket.dart';
import 'drive.dart';
import 'package:xml/xml.dart';

class ObjectReference {
  final HopDriveClient client;
  final BucketReference bucketRef;
  final String id;
  ObjectReference(this.client, this.bucketRef, this.id);

  Future<ObjectSnapshot> get() async {
    try {
      http.Response response = await client.get("/${bucketRef.bucket}/$id");
      return ObjectSnapshot(
          Object(id, data: Uint8List.fromList(response.bodyBytes)),
          success: true);
    } catch (_) {
      return ObjectSnapshot(null, success: false);
    }
  }

  String getPresigned() {
    String resource = "/${bucketRef.bucket}/$id";
    String query = client.signer.getQuerySignature("GET", resource);
    String encodedPath = resource.split("/").map(Uri.encodeComponent).join("/");
    return "${client.baseUrl}/${client.identity}$encodedPath$query";
  }

  Future<ObjectSnapshot> put(Uint8List data) async {
    if (!await bucketRef.exists) {
      bool success = await bucketRef.create();
      assert(success,
          "${bucketRef.bucket} did not exist and could not be created");
    }
    try {
      await client.put("/${bucketRef.bucket}/$id", bodyBytes: data);
      return ObjectSnapshot(Object(id, data: data), success: true);
    } catch (_) {
      return ObjectSnapshot(null, success: false);
    }
  }

  Future<bool> delete() async {
    try {
      await client.delete("/${bucketRef.bucket}/$id");
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ObjectSnapshot {
  final Object? object;
  final bool success;
  ObjectSnapshot(this.object, {required this.success});
}

class Owner {
  final String id, displayName;
  Owner.fromSoup(XmlElement soup)
      : id = soup.findElements('ID').single.text,
        displayName = soup.findElements('DisplayName').single.text;

  Map<String, dynamic> get json => {"id": id, "display_name": displayName};
}

class Object {
  String id;
  Uint8List? data;
  late String url, etag, storageclass;
  late DateTime lastModified;
  late int size;
  late Owner owner;

  Object(this.id, {this.data});

  Object.fromSoup(String url, XmlElement soup)
      : id = soup.findElements('Key').single.text,
        url = url,
        etag = soup.findElements('ETag').single.text,
        size = int.parse(soup.findElements('Size').single.text),
        owner = Owner.fromSoup(soup.findElements('Owner').single),
        storageclass = soup.findElements('StorageClass').single.text {
    final date = soup.findElements('LastModified').single.text;
    lastModified = DateTime.parse(date).toLocal();
  }

  Map<String, dynamic> get json => {
        "id": id,
        "url": url,
        "last_modified": lastModified,
        "etag": etag,
        "size": size,
        "owner": owner.json,
        "storageclass": storageclass
      };
}
