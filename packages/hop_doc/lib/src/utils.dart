class TimeHelper {
  static const DAYS_IN_YEAR = 365.2182410423452836315;
  static const MONTHS_IN_YEAR = 12.0;
  static const NANOSECONDS_IN_SECOND = 1000000000;
  static const SECONDS_IN_MINUTE = 60;
  static const SECONDS_IN_HOUR = 60 * SECONDS_IN_MINUTE;
  static const SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR;

  static final RegExp _parseFormat =
      RegExp(r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' // Day part.
          r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(?:[.,](\d+))?)?)?' // Time part.
          r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$'); // Timezone part.

  static String nanosecondsSinceEpoch(String date) {
    var re = _parseFormat;
    Match match = re.firstMatch(date);
    if (match != null) {
      int parseIntOrZero(String matched) {
        if (matched == null) return 0;
        return int.parse(matched);
      }

      int parseNanoseconds(String matched) {
        if (matched == null) return 0;
        int length = matched.length;
        assert(length >= 1);
        int result = 0;
        for (int i = 0; i < 9; i++) {
          result *= 10;
          if (i < matched.length) {
            result += matched.codeUnitAt(i) ^ 0x30;
          }
        }
        return result;
      }

      int years = int.parse(match[1]);
      int month = int.parse(match[2]);
      int day = int.parse(match[3]);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      int ns = parseNanoseconds(match[7]);
      bool isUtc = false;
      if (match[8] != null) {
        // timezone part
        isUtc = true;
        String tzSign = match[9];
        if (tzSign != null) {
          // timezone other than 'Z' and 'z'.
          int sign = (tzSign == '-') ? -1 : 1;
          int hourDifference = int.parse(match[10]);
          int minuteDifference = parseIntOrZero(match[11]);
          minuteDifference += 60 * hourDifference;
          minute -= sign * minuteDifference;
        }
      }

      int nanoseconds = 0;
      nanoseconds += ((years - 1970) * DAYS_IN_YEAR * SECONDS_IN_DAY).round();
      nanoseconds +=
          ((month - 1) * DAYS_IN_YEAR / MONTHS_IN_YEAR * SECONDS_IN_DAY)
              .round();
      nanoseconds += (day - 1) * SECONDS_IN_DAY;
      nanoseconds += hour * SECONDS_IN_HOUR;
      nanoseconds += minute * SECONDS_IN_MINUTE;
      nanoseconds += second;
      return nanoseconds.toString() + ns.toString();
    } else {
      throw FormatException("Invalid date format", date);
    }
  }

  static String millisecondsSinceEpoch(String date) {
    final DateTime ts = DateTime.parse(date);
    return ts.millisecondsSinceEpoch.toString();
  }
}
