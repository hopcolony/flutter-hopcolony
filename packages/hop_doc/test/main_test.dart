import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Platform;
import 'package:hop_doc/hop_doc.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  final String? userName = Platform.environment['HOP_USER_NAME'];
  final String? projectName = Platform.environment['HOP_PROJECT_NAME'];
  final String? tokenName = Platform.environment['HOP_TOKEN'];

  final String index = ".hop.tests";
  final String uid = "hopcolony";
  final Map<String, dynamic> data = {"purpose": "Test Hop Docs!"};

  late init.Project project;
  late HopDoc db;

  setUpAll(() async {
    project = await init.initialize(
        username: userName, project: projectName, token: tokenName);
    db = HopDoc.instance;
  });

  test('Initialize', () {
    expect(project.config, isNot(null));
    expect(project.name, projectName);

    expect(db.project.name, project.name);
    expect(db.client?.host, "docs.hopcolony.io");
    expect(db.client?.identity, project.config.identity);
  });

  test('Status', () async {
    final status = await db.status;
    expect(status["status"], isNot("red"));
  });

  test('Create Document', () async {
    DocumentSnapshot snapshot =
        await db.index(index).document(uid).setData(data);
    expect(snapshot.success, true);

    Document? doc = snapshot.doc;
    expect(doc?.index, index);
    expect(doc?.id, uid);
    expect(doc?.source, data);
  });

  test('Get Document', () async {
    DocumentSnapshot snapshot = await db.index(index).document(uid).get();
    expect(snapshot.success, true);

    Document? doc = snapshot.doc;
    expect(doc?.index, index);
    expect(doc?.id, uid);
    expect(doc?.source, data);
  });

  test('Delete Document', () async {
    DocumentSnapshot snapshot = await db.index(index).document(uid).delete();
    expect(snapshot.success, true);
  });

  test('Find non existing Document', () async {
    DocumentSnapshot snapshot = await db.index(index).document(uid).get();
    expect(snapshot.success, false);

    snapshot = await db.index(index).document(uid).update({"data": "test"});
    expect(snapshot.success, false);

    snapshot = await db.index(index).document(uid).delete();
    expect(snapshot.success, false);

    IndexSnapshot snap = await db.index(".does.not.exist").get();
    expect(snap.success, false);
  });

  test('Create Document without ID', () async {
    DocumentSnapshot snapshot = await db.index(index).add(data);
    expect(snapshot.success, true);

    Document? doc = snapshot.doc;
    expect(doc?.index, index);
    expect(doc?.source, data);

    snapshot = await db.index(index).document(doc!.id).delete();
    expect(snapshot.success, true);
  });

  test('Delete Index', () async {
    bool result = await db.index(index).delete();
    expect(result, true);
  });

  test('Index not there', () async {
    List<Index> result = await db.get();
    List<String> indices = result.map((index) => index.name).toList();
    expect(indices.contains(index), false);
  });
}
