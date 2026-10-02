// Development CORS proxy for running Reckon Seller as a Flutter web app.
//
// The backend already sends CORS headers, but its Access-Control-Allow-Headers
// list only covers `authorization`, `content-type` and `package_name`. The OTP
// endpoint passes its data in custom headers (MobileNo, CountryCode, lApkName,
// GenerateOtp), so the browser blocks that request at preflight and both the
// forgot-password and device-change flows fail on web.
//
// This proxy sits in front of the API and answers preflights permissively, so
// the browser stops objecting. It also means the page can be served over HTTPS
// while the API stays on plain HTTP, which the browser would otherwise block as
// mixed content.
//
// This is a DEV TOOL. The real fix is to widen Allow-Headers on the server; in
// production put nginx (or similar) in front instead, so the app and the API
// share an origin. Nothing here ships inside the app.
//
// Run:
//   dart run tool/cors_proxy.dart                 # listens on :8010
//   dart run tool/cors_proxy.dart --port 9000
//
// Then point the web build at it:
//   flutter run -d chrome --dart-define=API_PROXY=http://localhost:8010

import 'dart:io';

const _defaultTarget = 'http://mobileappsandbox.reckonsales.com:8080';
const _defaultPort = 8010;

/// Headers that describe a single hop and must not be forwarded.
const _hopByHop = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'host',
  'content-length',
};

Future<void> main(List<String> args) async {
  var port = _defaultPort;
  var target = _defaultTarget;

  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == '--port') port = int.tryParse(args[i + 1]) ?? port;
    if (args[i] == '--target') target = args[i + 1];
  }
  final targetUri = Uri.parse(target);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('CORS proxy listening on http://localhost:$port');
  stdout.writeln('  forwarding to $target');
  stdout.writeln('  flutter run -d chrome --dart-define=API_PROXY=http://localhost:$port');
  stdout.writeln('');

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

  await for (final req in server) {
    _handle(req, targetUri, client).catchError((Object e) {
      stderr.writeln('  ! ${req.method} ${req.uri.path} -> $e');
    });
  }
}

Future<void> _handle(HttpRequest req, Uri target, HttpClient client) async {
  final res = req.response;
  _applyCors(req, res);

  // Preflight: answer here, never forward it.
  if (req.method == 'OPTIONS') {
    res.statusCode = HttpStatus.noContent;
    await res.close();
    stdout.writeln('  OPTIONS ${req.uri.path} -> 204 (preflight)');
    return;
  }

  final upstream = Uri(
    scheme: target.scheme,
    host: target.host,
    port: target.port,
    path: req.uri.path,
    query: req.uri.query.isEmpty ? null : req.uri.query,
  );

  final body = await _readBody(req);

  try {
    final proxied = await client.openUrl(req.method, upstream);
    proxied.followRedirects = false;

    req.headers.forEach((name, values) {
      if (_hopByHop.contains(name.toLowerCase())) return;
      if (name.toLowerCase() == 'origin') return; // upstream reflects it; we set our own
      for (final v in values) {
        proxied.headers.add(name, v);
      }
    });
    if (body.isNotEmpty) proxied.add(body);

    final upstreamRes = await proxied.close();

    res.statusCode = upstreamRes.statusCode;
    upstreamRes.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (_hopByHop.contains(lower)) return;
      // Drop upstream's CORS headers — ours are already set and duplicates are
      // treated as a protocol violation by browsers.
      if (lower.startsWith('access-control-')) return;
      if (lower == 'vary') return;
      for (final v in values) {
        res.headers.add(name, v);
      }
    });

    await upstreamRes.pipe(res);
    stdout.writeln('  ${req.method} ${req.uri.path} -> ${upstreamRes.statusCode}');
  } catch (e) {
    res.statusCode = HttpStatus.badGateway;
    res.headers.contentType = ContentType.json;
    res.write('{"Status":false,"Message":"proxy could not reach the API: $e"}');
    await res.close();
    stdout.writeln('  ${req.method} ${req.uri.path} -> 502 ($e)');
  }
}

Future<List<int>> _readBody(HttpRequest req) async {
  final chunks = <int>[];
  await for (final chunk in req) {
    chunks.addAll(chunk);
  }
  return chunks;
}

/// Permissive CORS for local development: reflect the caller's origin and
/// whatever headers it asked for, so no request is ever rejected at preflight.
void _applyCors(HttpRequest req, HttpResponse res) {
  final origin = req.headers.value('origin') ?? '*';
  final requested = req.headers.value('access-control-request-headers');

  res.headers
    ..set('Access-Control-Allow-Origin', origin)
    ..set('Access-Control-Allow-Credentials', 'true')
    ..set('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS')
    ..set('Access-Control-Allow-Headers', requested ?? '*')
    ..set('Access-Control-Expose-Headers', 'Authorization')
    ..set('Access-Control-Max-Age', '3600');
}
