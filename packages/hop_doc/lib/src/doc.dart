import 'dart:convert';
import 'package:hop_doc/hop_doc.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'index_reference.dart';
import 'package:http/http.dart' as http;

class HopDoc {
  late init.Project _project;
  HopDocClient? client;
  static final HopDoc instance = HopDoc._internal();
  factory HopDoc() => instance;
  HopDoc._internal({init.Project? project}) {
    if (project != null) {
      _project = project;
      client = HopDocClient(project: project);
    } else if (client == null) {
      _project = init.project!;
      client = HopDocClient(project: _project);
    }
  }

  init.Project get project => _project;

  factory HopDoc.fromProject(init.Project project) =>
      HopDoc._internal(project: project);

  Future<Map<String, dynamic>> get status async {
    try {
      final response = await client!.get("/_cluster/health");
      return response;
    } catch (e) {
      return {"status": "Cluster not reachable"};
    }
  }

  IndexReference index(String index) {
    return IndexReference(client!, index);
  }

  Future<List<Index>> get({filterHidden = true}) async {
    final response = await client!.get("/_cluster/health?level=indices");
    List<Index> indices = [];
    for (var entry in (response["indices"] as Map).entries) {
      if ((!filterHidden || !RegExp(r"^\..*").hasMatch(entry.key)) &&
          !RegExp(r"ilm-history-.*").hasMatch(entry.key)) {
        int numDocs = await this.index(entry.key).count;
        indices.add(Index.fromJson(entry.key, entry.value, numDocs));
      }
    }
    return indices;
  }

  GeoPoint point({required double latitude, required double longitude}) =>
      GeoPoint(latitude: latitude, longitude: longitude);
}

class HopDocClient {
  init.Project project;
  final String host = "docs.hopcolony.io";
  final int port = 443;
  String identity;
  final http.Client client = http.Client();
  Map<String, String> headers = {};

  HopDocClient({required init.Project project})
      : project = project,
        identity = project.config.identity!;

  Future<Map<String, dynamic>> get(String path) async {
    final response = await client.get(
      Uri.parse("https://$host:$port/$identity/api$path"),
      headers: {'content-Type': 'application/json'},
    );

    if (response.statusCode >= 400) throw Exception(response.body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> data}) async {
    final response = await client.post(
      Uri.parse("https://$host:$port/$identity/api$path"),
      headers: {'content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 400) throw Exception(response.body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await client.delete(
      Uri.parse("https://$host:$port/$identity/api$path"),
    );

    if (response.statusCode >= 400) throw Exception(response.body);
    return jsonDecode(response.body);
  }
}
