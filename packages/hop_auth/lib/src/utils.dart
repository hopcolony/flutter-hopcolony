import 'dart:convert';

Map<String, dynamic> base64ToJson(String input) {
  var r = input.length & 3;
  if (r > 0) input += '%3D' * (4 - r);

  var json = jsonDecode(String.fromCharCodes(base64Decode(input)));
  return json;
}
