import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
import 'drive.dart';
import 'object.dart' as hop;
import 'object.dart';

class BucketReference {
  final HopDriveClient client;
  final String bucket;
  BucketReference(this.client, this.bucket);

  Future<BucketSnapshot> get() async {
    List<hop.Object> objects = [];
    try {
      http.Response response = await client.get("/$bucket");
      final document = XmlDocument.parse(await response.body);
      for (final soup in document.findAllElements("Contents")) {
        final String url =
            object(soup.findElements('Key').single.text).getPresigned();
        objects.add(hop.Object.fromSoup(url, soup));
      }
      return BucketSnapshot(objects, success: true);
    } catch (_) {
      return BucketSnapshot(null, success: false);
    }
  }

  Future<bool> get exists async {
    try {
      await client.get("/$bucket");
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> create() async {
    try {
      await client.put("/$bucket");
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ObjectSnapshot> add(Uint8List data) async {
    String id = Uuid().v4().substring(0, 10);
    return object(id).put(data);
  }

  ObjectReference object(String id) => ObjectReference(client, this, id);

  Future<bool> delete() async {
    // Delete all the objects before deleting the bucket
    if (!await exists) return true;
    BucketSnapshot snapshot = await get();
    snapshot.objects.forEach((obj) async {
      await object(obj.id).delete();
    });
    try {
      await client.delete("/$bucket");
      return true;
    } catch (_) {
      return false;
    }
  }
}

class BucketSnapshot {
  final List<Object> objects;
  final bool success;
  BucketSnapshot(this.objects, {this.success});
}

class Bucket {
  final String name;
  final DateTime creationDate;
  final int numObjs;

  Bucket(this.name, this.creationDate, this.numObjs);

  Map<String, dynamic> get json =>
      {"name": name, "creationDate": creationDate, "numObjs": numObjs};
}
