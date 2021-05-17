import 'utils.dart';

class Token {
  final String rawValue;

  Map<String, dynamic>? _header;
  Map<String, dynamic>? _payload;
  String? _signature;
  late final int _i0;
  late final int _i1;

  Token(this.rawValue)
      : _i0 = rawValue.indexOf('.'),
        _i1 = rawValue.lastIndexOf('.');

  Map<String, dynamic> get header {
    _header ??= base64ToJson(rawValue.substring(0, _i0));
    return _header!;
  }

  Map<String, dynamic> get payload {
    _payload ??= base64ToJson(rawValue.substring(_i0 + 1, _i1));
    return _payload!;
  }

  String get signature {
    _signature ??= rawValue.substring(_i1 + 1);
    return _signature!;
  }

  String toString() => rawValue;
}
