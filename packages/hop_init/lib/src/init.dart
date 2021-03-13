import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import "dart:convert";
import 'package:yaml/yaml.dart';
import 'package:flutter/material.dart';

Map<String, Project> _projects = {};

class InvalidConfig implements Exception {
  String cause;
  InvalidConfig(this.cause);
}

class ConfigNotFound implements Exception {
  String cause;
  ConfigNotFound(this.cause);
}

class HopConfig {
  final String username, project, token;
  String identity;
  HopConfig({this.username, this.project, this.token}) {
    this.identity = computeIdentity();
  }

  String computeIdentity() {
    if (this.username == null || this.project == null) return null;
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encodedUsername = 'a' +
        stringToBase64.encode(this.username).toLowerCase().replaceAll("=", "a");
    final raw = encodedUsername + "." + this.project;
    return stringToBase64.encode(raw);
  }

  bool get valid =>
      this.username != null &&
      this.project != null &&
      this.token != null &&
      this.identity != null;

  static Future<HopConfig> fromFile(file) async {
    String content;
    try {
      content = await rootBundle.loadString(file);
    } catch (_) {
      throw ConfigNotFound("Config file \"$file\" not found...");
    }
    YamlMap yaml;
    try {
      yaml = loadYaml(content);
    } catch (_) {
      throw InvalidConfig("Config file \"$file\" has an invalid syntax...");
    }
    return HopConfig.fromJson(yaml);
  }

  factory HopConfig.fromJson(var json) => HopConfig(
      username: json["username"],
      project: json["project"],
      token: json["token"]);

  Map get json =>
      {"username": this.username, "project": this.project, "token": this.token};
}

class Project {
  final String username, project, token, configFile;
  final Completer completer;
  HopConfig config;

  Project(this.completer,
      {this.username, this.project, this.token, this.configFile}) {
    // Use username, project and token values if the 3 provided
    if (this.username != null || this.project != null || this.token != null) {
      if (this.username != null && this.project != null && this.token != null) {
        this.config =
            HopConfig(username: username, project: project, token: token);
        completer.complete(this.config);
        return;
      } else {
        throw InvalidConfig(
            "If you provide one of [username, project, token], you need to provide the 3 of them");
      }
    }

    HopConfig.fromFile(configFile).then((HopConfig config) {
      this.config = config;
      completer.complete(this.config);
    }).catchError((error) {
      completer.completeError(error);
    });
  }

  String get name => this.config.project;
}

Future<Project> initialize(
    {String name = "DEFAULT",
    String configFile = ".hop.config",
    String username,
    String project,
    String token}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Completer completer = Completer();
  final Project proj = Project(completer,
      configFile: configFile,
      username: username,
      project: project,
      token: token);
  await completer.future;
  _projects[name] = proj;
  return proj;
}

Project get project {
  final name = "DEFAULT";
  assert(_projects.containsKey(name),
      "Project DEFAULT does not exist. You need to initialize the project first with init.initialize()");
  return _projects[name];
}

Project getProject(String name) {
  assert(_projects.containsKey(name),
      "Project $name does not exist. You need to initialize the project first with init.initialize(project: $name)");
  return _projects[name];
}

HopConfig get config {
  return project.config;
}
