import 'package:hop_doc/hop_doc.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:websocket/websocket.dart';
import 'index_reference.dart';
import 'package:dio/dio.dart';

class HopDoc {
  init.Project project;
  HopDocClient client;
  static final HopDoc instance = HopDoc._internal();
  factory HopDoc() => instance;
  HopDoc._internal({init.Project project}) {
    if (client == null) {
      project = project ?? init.project;
      // App is initialized from Hop Init
      client = HopDocClient(project: project);
    }
  }

  factory HopDoc.fromProject(init.Project project) =>
      HopDoc._internal(project: project);

  Future<Map<String, dynamic>> get status async {
    try {
      Response response = await client.get("/_cluster/health");
      return response.data;
    } catch (e) {
      return {"status": "Cluster not reachable"};
    }
  }

  IndexReference index(String index) {
    return IndexReference(client, index);
  }

  Future<List<Index>> get({filterHidden = true}) async {
    Response response = await client.get("/_cluster/health?level=indices");
    List<Index> indices = [];
    for (var entry in (response.data["indices"] as Map).entries) {
      if ((!filterHidden || !RegExp(r"\..*").hasMatch(entry.key)) &&
          !RegExp(r"ilm-history-.*").hasMatch(entry.key)) {
        int numDocs = await this.index(entry.key).count;
        indices.add(Index.fromJson(entry.key, entry.value, numDocs));
      }
    }
    return indices;
  }

  GeoPoint point({double latitude, double longitude}) =>
      GeoPoint(latitude: latitude, longitude: longitude);
}

class HopDocClient {
  init.Project project;
  final String host = "docs.hopcolony.io";
  final int port = 443;
  String identity, _baseUrl;
  final Dio dio = Dio();

  HopDocClient({init.Project project})
      : project = project,
        identity = project.config.identity {
    dio.options.headers['content-Type'] = 'application/json';
    this._baseUrl = "https://$host:$port/$identity/http";
  }

  Future<Response> get(String path) async => dio.get(_baseUrl + path);

  Future<Response> post(String path, {var data}) async =>
      dio.post(_baseUrl + path, data: data);

  Future<Response> delete(String path) async => dio.delete(_baseUrl + path);

  Future<WebSocket> connect(String path) async =>
      WebSocket.connect("wss://$host:$port/$identity/ws$path");
}
