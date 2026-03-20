class CurlParsedData {
  final String? url;
  final String? method;
  final Map<String, String>? headers;
  final String? body;

  CurlParsedData({this.url, this.method, this.headers, this.body});
}

class CurlParser {
  static CurlParsedData parse(String curlCommand) {
    final cleanCommand =
        curlCommand.replaceAll('\\\n', ' ').replaceAll('\\\r\n', ' ');

    String method = 'GET';
    String url = '';
    Map<String, String> headers = {};
    String body = '';

    final urlMatch =
        RegExp(r'''(?:curl\s+)?(?:['"]?)(https?://[^'"\s]+)(?:['"]?)''')
            .firstMatch(cleanCommand);
    if (urlMatch != null) {
      url = urlMatch.group(1)!;
    }

    final methodMatch =
        RegExp(r'''(?:-X|--request)\s+(['"]?)([A-Z]+)\1''')
            .firstMatch(cleanCommand);
    if (methodMatch != null) {
      method = methodMatch.group(2)!;
    } else if (cleanCommand.contains('-d') ||
        cleanCommand.contains('--data') ||
        cleanCommand.contains('--data-raw')) {
      method = 'POST';
    }

    final headerRegExp =
        RegExp(r'''(?:-H|--header)\s+(['"])([^:]+):\s*(.*?)\1''');
    for (final match in headerRegExp.allMatches(cleanCommand)) {
      headers[match.group(2)!.trim()] = match.group(3)!.trim();
    }

    final headerNoQuoteRegExp =
        RegExp(r'''(?:-H|--header)\s+([^'"\s]+):\s*([^'"\s]+)''');
    for (final match in headerNoQuoteRegExp.allMatches(cleanCommand)) {
      final key = match.group(1)!.trim();
      if (!headers.containsKey(key)) {
        headers[key] = match.group(2)!.trim();
      }
    }

    final dataRegExp = RegExp(
      r'''(?:-d|--data(?:-raw|-binary)?)\s+(['"])(.*?)\1''',
      dotAll: true,
    );
    final dataMatch = dataRegExp.firstMatch(cleanCommand);
    if (dataMatch != null) {
      body = dataMatch.group(2) ?? '';
    } else {
      final dataNoQuoteRegExp =
          RegExp(r'''(?:-d|--data(?:-raw|-binary)?)\s+([^{'"\s][^\s]*)''');
      final dataNoQuoteMatch = dataNoQuoteRegExp.firstMatch(cleanCommand);
      if (dataNoQuoteMatch != null) {
        body = dataNoQuoteMatch.group(1) ?? '';
      }
    }

    return CurlParsedData(
      url: url,
      method: method,
      headers: headers,
      body: body,
    );
  }
}
