import 'token.dart';

class HopUser {
  final DateTime registerTs, lastLoginTs;
  final String uuid, email, name, picture, locale;
  final bool isAnonymous;

  HopUser({
    required this.registerTs,
    required this.lastLoginTs,
    required this.uuid,
    required this.email,
    required this.name,
    required this.picture,
    required this.locale,
    required this.isAnonymous,
  });

  factory HopUser.fromJson(Map json) => HopUser(
        registerTs: DateTime.parse(json["registerTs"]),
        lastLoginTs: DateTime.parse(json["lastLoginTs"]),
        uuid: json["uuid"],
        email: json["email"],
        name: json["name"],
        picture: json["picture"],
        locale: json["locale"],
        isAnonymous: json["isAnonymous"],
      );

  factory HopUser.fromToken(String idToken) {
    final token = Token(idToken);
    return HopUser(
      registerTs: DateTime.parse(token.payload["registerTs"]),
      lastLoginTs: DateTime.parse(token.payload["lastLoginTs"]),
      uuid: token.payload["uuid"],
      email: token.payload["email"],
      name: token.payload["name"],
      picture: token.payload["picture"],
      locale: token.payload["locale"],
      isAnonymous: token.payload["isAnonymous"],
    );
  }

  Map<String, dynamic> get json => {
        "registerTs": registerTs.toString(),
        "lastLoginTs": lastLoginTs.toString(),
        "uuid": uuid,
        "email": email,
        "name": name,
        "picture": picture,
        "locale": locale,
        "isAnonymous": isAnonymous,
      };
}
