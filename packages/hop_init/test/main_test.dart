import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Platform;
import 'package:hop_init/hop_init.dart' as init;

void main() {
  final String? userName = Platform.environment['HOP_USER_NAME'];
  final String? projectName = Platform.environment['HOP_PROJECT_NAME'];
  final String? tokenName = Platform.environment['HOP_TOKEN'];

  test('Test Initialize', () async {
    expect(init.initialize(configFile: ".."),
        throwsA(isInstanceOf<init.ConfigNotFound>()));

    expect(init.initialize(username: userName),
        throwsA(isInstanceOf<init.InvalidConfig>()));

    expect(init.initialize(username: userName, project: projectName),
        throwsA(isInstanceOf<init.InvalidConfig>()));

    init.Project project = await init.initialize(
      username: userName,
      project: projectName,
      token: tokenName,
    );

    expect(project.config.username, userName);
    expect(project.config.project, projectName);
    expect(project.config.token, tokenName);

    final config = init.config;
    expect(config?.project, projectName);
    expect(config?.project, projectName);
    expect(config?.token, tokenName);
  });
}
