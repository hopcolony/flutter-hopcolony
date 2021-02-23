import 'package:flutter/material.dart';
import 'package:hop_doc/hop_doc.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final instance = HopDoc.instance;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Luis Paarup"),
      ),
      body: Column(
        children: [
          FutureBuilder<DocumentSnapshot>(
              future: instance.index("profile").document("1234").get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(children: [
                    TextButton(onPressed: update, child: Text("Update")),
                    TextButton(onPressed: add, child: Text("Add")),
                    TextButton(onPressed: delete, child: Text("Delete")),
                    TextButton(onPressed: getAll, child: Text("Get all")),
                    TextButton(
                        onPressed: geoDistanceQuery,
                        child: Text("Geo distance query")),
                    TextButton(
                        onPressed: geoBoxQuery, child: Text("Geo box query")),
                  ]);
                } else {
                  return CircularProgressIndicator();
                }
              })
        ],
      ),
    );
  }
}
