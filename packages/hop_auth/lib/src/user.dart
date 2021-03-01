import 'package:hop_auth/src/token.dart';

class HopUser {
  final DateTime registerTs, lastLoginTs;
  final List<String> projects;
  final String uuid, email, name, picture, locale;
  final bool isAnonymous;

  HopUser({
    this.registerTs,
    this.lastLoginTs,
    this.uuid,
    this.email,
    this.name,
    this.projects,
    this.picture,
    this.locale,
    this.isAnonymous,
  });

  factory HopUser.fromJson(Map json) => HopUser(
        registerTs: DateTime.parse(json["registerTs"]),
        lastLoginTs: DateTime.parse(json["lastLoginTs"]),
        uuid: json["uuid"],
        email: json["email"],
        name: json["name"],
        projects: (json["projects"] as List)
            .map((dynamic project) => project.toString())
            .toList(),
        picture: json["picture"],
        locale: json["locale"],
        isAnonymous: json["isAnonymous"],
      );

  Map<String, dynamic> get json => {
        "registerTs": registerTs.toString(),
        "lastLoginTs": lastLoginTs.toString(),
        "uuid": uuid,
        "email": email,
        "name": name,
        "projects": projects,
        "picture": picture,
        "locale": locale,
        "isAnonymous": isAnonymous,
      };
}
