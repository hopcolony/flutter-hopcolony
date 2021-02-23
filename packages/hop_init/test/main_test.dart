import 'package:flutter_test/flutter_test.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() {
  final String appName = "app";
  final String projectName = "project";
  final String tokenName = "token";
  test('Test Initialize', () async {
    expect(init.initialize(configFile: ".."),
        throwsA(isInstanceOf<init.ConfigNotFound>()));

    expect(init.initialize(app: appName),
        throwsA(isInstanceOf<init.InvalidConfig>()));

    expect(init.initialize(app: appName, project: projectName),
        throwsA(isInstanceOf<init.InvalidConfig>()));

    init.App app = await init.initialize(
      app: appName,
      project: projectName,
      token: tokenName,
    );

    expect(app.config.app, appName);
    expect(app.config.project, projectName);
    expect(app.config.token, tokenName);

    final config = init.config;
    expect(config.app, appName);
    expect(config.project, projectName);
    expect(config.token, tokenName);
  });
}
