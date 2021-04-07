import 'package:flutter/material.dart';
import 'package:hop_doc/hop_doc.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final instance = HopDoc.instance;

  getIndices() async {
    List<Index> resp = await instance.get();
    resp.forEach((element) {
      print(element.name);
    });
  }

  getDocumentIds() async {
    final snapshot = await instance
        .index("pisos.com.properties")
        .get(size: 10, onlyIds: true);
    if (snapshot.success) {
      snapshot.docs.forEach((doc) {
        print(doc.id);
        print(doc.source);
      });
    }
  }

  add() async {
    final resp = await instance.index("profile").add({
      "name": Random().nextInt(255).toString(),
    });
    print(resp?.reason);
  }

  update() async {
    final resp = await instance.index("profile").document("1234").update({
      "name": Random().nextInt(255).toString(),
    });
    print(resp?.reason);
  }

  delete() async {
    final resp = await instance.index("profile").document("1234").delete();
    print(resp?.reason);
  }

  getAll() async {
    final snap = await instance.index("profile").get();
    if (snap.success) {
      for (final doc in snap.docs) {
        print(doc.source);
      }
    } else {
      print(snap.reason);
    }
  }

  geoDistanceQuery() async {
    final snap = await instance
        .index("properties")
        .withinRadius(
            center: GeoPoint(latitude: 40.80097, longitude: -3.04601),
            radius: "1km",
            field: "location")
        .get();
    if (snap.success) {
      print("Number of docs: ${snap.docs.length}");
      for (final doc in snap.docs) {
        // print(doc.source);
      }
    } else {
      print(snap.reason);
    }
  }

  geoBoxQuery() async {
    final snap = await instance
        .index("properties")
        .withinBox(
            topLeft: GeoPoint(latitude: 40.636054, longitude: -3.173538),
            bottomRight: GeoPoint(latitude: 40.631152, longitude: -3.159176),
            field: "location")
        .get(size: 200);
    if (snap.success) {
      print("Number of docs: ${snap.docs.length}");
      for (final doc in snap.docs) {
        // print(doc.source);
      }
    } else {
      print(snap.reason);
    }
  }

  initState() {
    getLogs();
    super.initState();
  }

  List<Document> logs = [];
  Future<void> getLogs() async {
    final IndexSnapshot snapshot = await instance
        .index(".hop.logs-rentai-job-pisos.com-16162625855760267--")
        .limit(5)
        .orderBy(field: "time", order: "asc")
        .get();
    if (snapshot.success) {
      setState(() {
        logs = snapshot.docs;
      });
    }
  }

  Future<void> moreLogs() async {
    final IndexSnapshot snapshot = await instance
        .index(".hop.logs-rentai-job-pisos.com-16162625855760267--")
        .limit(5)
        .orderBy(field: "time", order: "asc")
        .start(after: logs.last, nanoDate: true)
        .get();
    if (snapshot.success) {
      setState(() {
        logs = snapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hop Docs"),
      ),
      body: Column(
        children: [
          Container(
            width: 400,
            height: 400,
            child: Scaffold(
              body: Center(
                child: Column(
                  children: logs.map((e) => Text(e.source["log"])).toList(),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: moreLogs,
                child: Text("More"),
              ),
            ),
          ),
          TextButton(onPressed: getIndices, child: Text("Get indices")),
          TextButton(onPressed: getDocumentIds, child: Text("Get doc ids")),
          TextButton(onPressed: update, child: Text("Update")),
          TextButton(onPressed: add, child: Text("Add")),
          TextButton(onPressed: delete, child: Text("Delete")),
          TextButton(onPressed: getAll, child: Text("Get all")),
          TextButton(
              onPressed: geoDistanceQuery, child: Text("Geo distance query")),
          TextButton(onPressed: geoBoxQuery, child: Text("Geo box query")),
        ],
      ),
    );
  }
}
