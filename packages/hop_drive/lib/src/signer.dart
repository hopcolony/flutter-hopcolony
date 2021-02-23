import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class Signer {
  final String host, accessKey, secretKey, region, algo;

  Signer(
      {this.host,
      this.accessKey,
      this.secretKey,
      this.region = "",
      this.algo = "AWS4-HMAC-SHA256"});

  SignDetails sign(String requestType, String rsc,
      {Uint8List bodyBytes,
      Map<String, dynamic> queryParameters,
      bool presigned = false,
      String expires = "432000"}) {
    Map<String, dynamic> headers = {};
    queryParameters = queryParameters ?? Map<String, dynamic>();
    bodyBytes = bodyBytes ?? Uint8List(0);
    final now = DateTime.now().toUtc();
    final iso8601ts = toAwsIso8601(now);
    final hPayload = hashBinary(bodyBytes);
    if (!presigned) {
      headers["x-amz-content-sha256"] = hPayload;
      headers["x-amz-date"] = iso8601ts;
    }
    headers["Host"] = host;
    final rScope = requestScope(now, region);
    final credential = "$accessKey/$rScope";
    final sHeaders = signedHeaders(headers);
    // When it is a presigned request, we must include the components
    // that will go with the query.
    // If not, use the request query components.
    Map<String, dynamic> canonicalQuery = presigned
        ? {
            "X-Amz-Algorithm": algo,
            "X-Amz-Credential": credential,
            "X-Amz-Date": iso8601ts,
            "X-Amz-Expires": expires,
            "X-Amz-SignedHeaders": sHeaders,
          }
        : queryParameters;

    List<String> resource = rsc.split('/').map(Uri.encodeComponent).toList();
    // Remove the prefix so that it doesn't get signed
    resource.removeAt(0);

    final canonicalRequest = <String>[
      requestType,
      "/" + resource.join("/"),
      canonicalStringFromQuery(canonicalQuery),
      canonicalStringFromHeaders(headers),
      sHeaders,
      presigned ? "UNSIGNED-PAYLOAD" : hPayload,
    ].join("\n");

    final stringToSign = <String>[
      algo,
      iso8601ts,
      rScope,
      hashedPayload(canonicalRequest),
    ].join("\n");

    final sKey = signingKey(secretKey, now, region, "s3");
    final signature = hex.encode(_signer(sKey, stringToSign));
    final authorization = <String>[
      "$algo Credential=$credential",
      " SignedHeaders=$sHeaders",
      " Signature=$signature"
    ].join(',');

    headers["Authorization"] = authorization;

    headers.remove("Host");

    return SignDetails(
      headers,
      algo: algo,
      date: iso8601ts,
      expires: expires,
      credential: "$accessKey/$rScope",
      signedHeaders: sHeaders,
      signature: signature,
    );
  }

  String getQuerySignature(String requestType, String resource) {
    final signDetails = sign(requestType, resource, presigned: true);
    return "?${signDetails.flatQuery}";
  }

  String canonicalStringFromQuery(Map<String, dynamic> query) {
    var keys = query.keys.toList()..sort();

    final List<String> result = [];
    keys.forEach((key) {
      result.add(
          "${Uri.encodeComponent(key)}=${Uri.encodeComponent(query[key])}");
    });

    return result.join('&');
  }

  String canonicalStringFromHeaders(Map<String, dynamic> headers) {
    var lowerCase = Map<String, String>();

    headers.forEach((k, v) {
      lowerCase[k.toLowerCase()] = k;
    });

    var keys = lowerCase.keys.toList()..sort();

    final List<String> result = [];
    keys.forEach((key) {
      result.add("$key:${headers[lowerCase[key]].trim()}");
    });

    //add final blank line
    result.add("");

    return result.join("\n");
  }

  String signedHeaders(Map<String, dynamic> headers) {
    var lowerCase = <String>[];
    headers.forEach((k, v) {
      lowerCase.add(k.toLowerCase());
    });

    lowerCase.sort();

    return lowerCase.join(";");
  }

  String requestScope(DateTime t, String region) {
    final dateStr =
        "${t.year.toString()}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}";
    return [dateStr, region, "s3", "aws4_request"].join("/");
  }

  String hashedPayload(String payload) {
    return hashBinary(utf8.encode(payload));
  }

  String hashBinary(List<int> payload) {
    return hex.encode(sha256.convert(payload).bytes);
  }

  List<int> signingKey(
      String secretKey, DateTime t, String region, String service) {
    final dateStr =
        "${t.year.toString()}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}";
    return _signer(
        _signer(
          _signer(
            _signer(utf8.encode("AWS4$secretKey"), dateStr),
            region,
          ),
          service,
        ),
        "aws4_request");
  }

  List<int> _signer(List<int> key, String payload) {
    final hmac = Hmac(sha256, key);
    final d = hmac.convert(utf8.encode(payload));
    return d.bytes;
  }

  String toAwsIso8601(DateTime t) {
    String y = t.year.toString();
    String m = t.month.toString().padLeft(2, '0');
    String d = t.day.toString().padLeft(2, '0');
    String h = t.hour.toString().padLeft(2, '0');
    String min = t.minute.toString().padLeft(2, '0');
    String seg = t.second.toString().padLeft(2, '0');

    return "${y}${m}${d}T${h}${min}${seg}Z";
  }
}

class SignDetails {
  final Map<String, dynamic> headers;
  final String algo, date, expires, credential, signedHeaders, signature;
  SignDetails(this.headers,
      {this.algo,
      this.date,
      this.expires,
      this.credential,
      this.signedHeaders,
      this.signature});

  String get flatQuery {
    final query = {
      "X-Amz-Algorithm": algo,
      "X-Amz-Credential": credential,
      "X-Amz-Date": date,
      "X-Amz-Expires": expires,
      "X-Amz-SignedHeaders": signedHeaders,
      "X-Amz-Signature": signature
    };

    return query.entries
        .map((e) => e.key == "X-Amz-SignedHeaders"
            ? "${e.key}=${e.value}"
            : "${e.key}=${Uri.encodeQueryComponent(e.value)}")
        .toList()
        .join("&");
  }
}
