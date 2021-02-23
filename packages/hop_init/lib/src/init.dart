import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import "dart:convert";
import 'package:yaml/yaml.dart';
import 'package:flutter/material.dart';

App _app;

class InvalidConfig implements Exception {
  String cause;
  InvalidConfig(this.cause);
}

class ConfigNotFound implements Exception {
  String cause;
  ConfigNotFound(this.cause);
}

class HopConfig {
  final String app, project, token;
  String identity;
  HopConfig({this.app, this.project, this.token}) {
    this.identity = computeIdentity();
  }

  String computeIdentity() {
    if (this.app == null || this.project == null) return null;
    final raw = this.project + "." + this.app;
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    return stringToBase64.encode(raw);
  }

  bool get valid =>
      this.app != null &&
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

  HopConfig.fromJson(var json)
      : app = json["app"],
        project = json["project"],
        token = json["token"];

  Map get json =>
      {"app": this.app, "project": this.project, "token": this.token};
}

class App {
  final String app, project, token, configFile;
  final Completer completer;
  HopConfig config;

  App(this.completer, {this.app, this.project, this.token, this.configFile}) {
    // Use app, project and token values if the 3 provided
    if (this.app != null || this.project != null || this.token != null) {
      if (this.app != null && this.project != null && this.token != null) {
        this.config = HopConfig(app: app, project: project, token: token);
        completer.complete(this.config);
        return;
      } else {
        throw InvalidConfig(
            "If you provide one of [app, project, token], you need to provide the 3 of them");
      }
    }

    HopConfig.fromFile(configFile).then((HopConfig config) {
      this.config = config;
      completer.complete(this.config);
    }).catchError((error) {
      completer.completeError(error);
    });
  }

  String get name => this.config.app;
}

Future<App> initialize(
    {String configFile = ".hop.config",
    String app,
    String project,
    String token}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Completer completer = Completer();
  _app = App(completer,
      configFile: configFile, app: app, project: project, token: token);
  await completer.future;
  return _app;
}

App get app {
  assert(_app != null,
      "You need to initialize the app first with init.initialize()");
  return _app;
}

HopConfig get config {
  return app.config;
}
