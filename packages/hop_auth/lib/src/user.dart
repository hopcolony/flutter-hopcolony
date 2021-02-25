import 'package:hop_auth/src/token.dart';

class HopUser {
  final DateTime registerTs, lastLoginTs;
  final String uuid, email, name, picture, locale;
  final Token idToken;
  final bool isAnonymous;

  HopUser({
    this.registerTs,
    this.lastLoginTs,
    this.uuid,
    this.email,
    this.name,
    this.picture,
    this.locale,
    this.idToken,
    this.isAnonymous,
  });

  factory HopUser.fromJson(Map json) => HopUser(
        registerTs: DateTime.parse(json["registerTs"]),
        lastLoginTs: DateTime.parse(json["lastLoginTs"]),
        uuid: json["uuid"],
        email: json["email"],
        name: json["name"],
        picture: json["picture"],
        locale: json["locale"],
        idToken: Token(json["idToken"]),
        isAnonymous: json["isAnonymous"],
      );

  Map<String, dynamic> get json => {
        "registerTs": registerTs.toString(),
        "lastLoginTs": lastLoginTs.toString(),
        "uuid": uuid,
        "email": email,
        "name": name,
        "picture": picture,
        "locale": locale,
        "idToken": idToken.rawValue,
        "isAnonymous": isAnonymous,
      };
}
