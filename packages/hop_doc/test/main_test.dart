import 'package:flutter_test/flutter_test.dart';
import 'package:hop_doc/hop_doc.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  final String appName = "rentai";
  final String projectName = "rental-friends";
  final String tokenName = "luis123456789";

  final String index = ".hop.tests";
  final String uid = "hopcolony";
  final Map<String, dynamic> data = {"purpose": "Test Hop Docs!"};

  init.App app;
  HopDoc db;

  setUpAll(() async {
    app = await init.initialize(
        app: appName, project: projectName, token: tokenName);
    db = HopDoc.instance;
  });

  test('Initialize', () {
    expect(app.config, isNot(null));
    expect(app.name, appName);

    expect(db.app.name, app.name);
    expect(db.client.host, "docs.hopcolony.io");
    expect(db.client.identity, app.config.identity);
  });

  test('Status', () async {
    final status = await db.status;
    expect(status["status"], isNot("red"));
  });

  test('Create Document', () async {
    DocumentSnapshot snapshot =
        await db.index(index).document(uid).setData(data);
    expect(snapshot.success, true);

    Document doc = snapshot.doc;
    expect(doc.index, index);
    expect(doc.id, uid);
    expect(doc.source, data);
  });

  test('Get Document', () async {
    DocumentSnapshot snapshot = await db.index(index).document(uid).get();
    expect(snapshot.success, true);

    Document doc = snapshot.doc;
    expect(doc.index, index);
    expect(doc.id, uid);
    expect(doc.source, data);
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

    Document doc = snapshot.doc;
    expect(doc.index, index);
    expect(doc.source, data);

    snapshot = await db.index(index).document(doc.id).delete();
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
