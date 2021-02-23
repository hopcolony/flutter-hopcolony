import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hop_drive/hop_drive.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'img.dart' as asset;

void main() async {
  final String userName = "console@hopcolony.io";
  final String projectName = "console";
  final String tokenName = "supersecret";

  final String bucket = "hop-test";
  final String obj = "test_img";
  Uint8List img;

  init.Project project;
  HopDrive db;

  setUpAll(() async {
    project = await init.initialize(
        username: userName, project: projectName, token: tokenName);
    db = HopDrive.instance;
    img = Uint8List.fromList(asset.test_img);
  });

  test('Initialize', () {
    expect(project.config, isNot(null));
    expect(project.name, projectName);

    expect(db.project.name, project.name);
    expect(db.client.host, "drive.hopcolony.io");
    expect(db.client.identity, project.config.identity);
  });

  test('Get non existing Bucket', () async {
    BucketSnapshot snapshot = await db.bucket("whatever").get();
    expect(snapshot.success, false);
  });

  test('Create Bucket', () async {
    bool success = await db.bucket(bucket).create();
    expect(success, true);
  });

  test('Get existing Bucket', () async {
    BucketSnapshot snapshot = await db.bucket(bucket).get();
    expect(snapshot.success, true);
  });

  test('List Buckets', () async {
    List<Bucket> result = await db.get();
    List<String> buckets = result.map((bucket) => bucket.name).toList();
    expect(buckets.contains(bucket), true);
  });

  test('Delete Bucket', () async {
    bool success = await db.bucket(bucket).delete();
    expect(success, true);
  });

  test('Delete non existing Bucket', () async {
    bool success = await db.bucket(bucket).delete();
    expect(success, true);
  });

  test('Create Object', () async {
    ObjectSnapshot snapshot = await db.bucket(bucket).object(obj).put(img);
    expect(snapshot.success, true);
  });

  test('Find Object', () async {
    BucketSnapshot snapshot = await db.bucket(bucket).get();
    expect(snapshot.success, true);
    List<String> objects = snapshot.objects.map((obj) => obj.id).toList();
    expect(objects.contains(obj), true);
  });

  test('Get Object', () async {
    ObjectSnapshot snapshot = await db.bucket(bucket).object(obj).get();
    expect(snapshot.success, true);
    expect(snapshot.object.id, obj);
    expect(snapshot.object.data, img);
  });

  test('Get Presigned Object', () async {
    String url = db.bucket(bucket).object(obj).getPresigned();
    Response response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    expect(Uint8List.fromList(response.data), img);
  });

  test('Delete Object', () async {
    bool success = await db.bucket(bucket).object(obj).delete();
    expect(success, true);
  });

  test('Add Object', () async {
    ObjectSnapshot snapshot = await db.bucket(bucket).add(img);
    expect(snapshot.success, true);
    expect(snapshot.object.id, isNot(null));
  });

  test('Delete Bucket', () async {
    bool success = await db.bucket(bucket).delete();
    expect(success, true);
  });
}
